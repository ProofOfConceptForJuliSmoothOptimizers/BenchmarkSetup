using Pkg
bmark_dir = joinpath(".")
Pkg.activate(bmark_dir)
Pkg.instantiate()

using ArgParse
using Git
using GitHub
using JSON
using Base64
using GitCommand

# include -------

include(joinpath(@__DIR__,"files.jl"))
include(joinpath(@__DIR__,"branches.jl"))
include(joinpath(@__DIR__,"pull_requests.jl"))
include(joinpath(@__DIR__,"utils.jl"))
include(joinpath(@__DIR__,"webhooks.jl"))
include(joinpath(@__DIR__, "repositories.jl"))
include(joinpath(@__DIR__, "fork.jl"))

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
            required = false
        "--fork", "-F"
            help = "boolean that specifies if the repositories are to be forked."
            action = :store_true
        "--title", "-t"
            help = "pull request title"
            arg_type = String
            default = "Setting up benchmarks"
    end

    return parse_args(s, as_symbols=true)
end

function main()
    api = GitHub.DEFAULT_API
    # Need to add GITHUB_AUTH to your .bashrc
    myauth = GitHub.authenticate(ENV["JSO_GITHUB_AUTH"])
    # parse the arguments:

    parsed_args = parse_commandline()
    org = parsed_args[:org]
    is_delete = parsed_args[:delete]
    repo_names = parsed_args[:repo]
    new_branch_name = parsed_args[:new_branch]
    base_branch_name = parsed_args[:base_branch]
    title = parsed_args[:title]
    path = parsed_args[:file]
    is_fork = parsed_args[:fork]

    # getting the right repositories given as argument: 
    repositories = repo_names == "all" ? GitHub.repos(api, org; auth = myauth)[1] : [repo for repo in GitHub.repos(api, org; auth = myauth)[1] if repo.name in split(repo_names)]
    # get file paths:
    file_paths = get_file_paths(path)
    
    if(is_fork)
        dest_org = "ProofOfConceptForJuliSmoothOptimizers"
        fork_repositories(api, org, repositories, dest_org; auth=myauth)
        # Setting org to organization where the forked repo is:
        repositories = repo_names == "all" ? GitHub.repos(api, dest_org; auth = myauth)[1] : [repo for repo in GitHub.repos(api, dest_org; auth = myauth)[1] if repo.name in split(repo_names)]
    end
    
    # update or delete:
    [create_branch(api, dest_org, repository, new_branch_name, base_branch_name; auth = myauth) for repository in repositories]
    if is_delete
        [delete_file(api, file_path, repositories, new_branch_name, "deleting file: $file_path"; auth = myauth) for file_path in file_paths]
    else
        [update_file(api, file_path, repositories, new_branch_name, "adding/updating file: $file_path"; auth = myauth) for file_path in file_paths]
    end

    create_pullrequests(api, org, repositories, new_branch_name, base_branch_name, title, is_fork; auth = myauth)
end

main()