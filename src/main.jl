using Pkg
bmark_dir = joinpath(".")
Pkg.activate(bmark_dir)
Pkg.instantiate()

using ArgParse
using Git
using GitHub
using Printf
using JSON
using Base64


# include -------

include(joinpath(@__DIR__,"files.jl"))
include(joinpath(@__DIR__,"branches.jl"))
include(joinpath(@__DIR__,"pull_requests.jl"))
include(joinpath(@__DIR__,"utils.jl"))
include(joinpath(@__DIR__,"webhooks.jl"))

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--org", "-o"
            help = "Name of GitHub Organization."
            arg_type = String
            default = "ProofOfConceptForJuliSmoothOptimizers"
        "--repo", "-r"
            help = "The name of the repositories on GitHub. To select all repos, simply write : 'all'."
            arg_type = String
            default = "Krylov.jl"
        "--delete", "-d"
            help = "boolean that specifies if it's a deletion process."
            action = :store_true
        "--new_branch", "-b"
            help = "the name of the new branch on which the modifications will be made. It must be a new branch name."
            arg_type = String   
            required = true
        "--base_branch", "-B"
            help = "The name of an existing branch. 'master' is the default value."
            default = "master"
        "--file", "-f"
            help = "path to file to update (e.g dir1/dir2/file_to_update.txt and not ./dir1/dir2/file_to_update.txt). 
                    Make sure to use the '/' delimiter for the path."
        "--message", "-m"
            help = "Commit message describing the modification."
            arg_type = String
            required = false
        "--webhook", "-w"
            help = "boolean that triggers the setup of webhooks for the benchmarks."
            action = :store_true
    end

    return parse_args(s, as_symbols=true)
end

function main()
    api = GitHub.DEFAULT_API
    # Need to add GITHUB_AUTH to your .bashrc
    # myauth = GitHub.authenticate("99c2656683ba93a4f3cb2f01494bcd1bcc416545")
    myauth = GitHub.authenticate(ENV["JSO_GITHUB_AUTH"])
    # parse the arguments:

    parsed_args = parse_commandline()
    org = parsed_args[:org]
    repo_names = parsed_args[:repo]
    is_delete = parsed_args[:delete]
    new_branch_name = parsed_args[:new_branch]
    base_branch_name = parsed_args[:base_branch]
    message = parsed_args[:message]
    path = parsed_args[:file]
    is_webhook = parsed_args[:webhook]

    # assigning default value to commit message: 

    message = isnothing(message) ?  "updating/deleting files from remote script: $path" : message

    # getting the right repositories given as argument: 

    repositories = repo_names == "all" ? GitHub.repos(api, org; auth = myauth)[1] : [repo for repo in GitHub.repos(api, org; auth = myauth)[1] if repo.name in split(repo_names)]
    
    file_paths = get_file_paths(path)

    # create branches
    [create_branch(api, org, repository, new_branch_name, base_branch_name; auth = myauth) for repository in repositories]
    # create webhooks for benchmarks
    if is_webhook
        [create_benchmark_webhook(api, org, repository; auth = myauth) for repository in repositories]
    end
    # updating or deleting files given in path
    if is_delete
        [delete_file(api, file_path, repositories, new_branch_name, message, auth = myauth) for file_path in file_paths]
    else
        [update_file(api, file_path, repositories, new_branch_name, message; auth = myauth) for file_path in file_paths]
    end
    
    # creating pull request and branches if needed
    create_pullrequests(api, org, repositories, new_branch_name, base_branch_name, message; auth = myauth)
end

main()