using Pkg
bmark_dir = joinpath(@__DIR__, "env/")
Pkg.activate(bmark_dir)
Pkg.instantiate()

using ArgParse
using Git
using GitHub
using Printf
using JSON
using Base64

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--org", "-o"
            help = "Name of GitHub Organization"
            arg_type = String
            default = "ProofOfConceptForJuliSmoothOptimizers"
        "--repo", "-r"
            help = "The name of the repositories on GitHub. To select all repos, simply write : 'all'."
            arg_type = String
            default = "Krylov.jl"
        "--delete", "-d"
            help = "specifies if it's a deletion process"
            action = :store_true
        # TODO: change branch required to true
        "--branch", "-b"
            help = "the name of the new branch on which the modifications will be made."
            arg_type = String   
            required = false
        "--file", "-f"
            help = "path to file to update (e.g dir1/dir2/file_to_update.txt). 
                    Make sure to use the '/' delimiter for the path."
    end

    return parse_args(s, as_symbols=true)
end

"""TODO: make sure to put 'branch_name' as an argument in ArgParse and to add it to all
    function that needs the paramater. Add it as a named parameter""" 

function update_file(api::GitHub.GitHubWebAPI, path::String, repositories::Vector{Repo}; kwargs...)
    file = open(path, "r")
    myparams = Dict(:message => "updating file from remote script: $path", :branch => "master", :content => base64encode(file))
    close(file)
    for repo in repositories
        sha_of_file = get_file_sha(api, path, repo)
        if length(sha_of_file) > 0
           myparams[:sha] = sha_of_file
        end 
        GitHub.update_file(api, repo, path; params = myparams, kwargs...)
        println("file at $(path) updated in $(repo.name)")
        delete!(myparams, :sha)
    end
end

function delete_file(api::GitHub.GitHubWebAPI, path::String, repos::Vector{Repo}; kwargs...)
    # Getting sha of the file if needed:
    myparams = Dict(:message => "deleting file from remote script: $path", :branch => "master")
    # Looking for the git sha1 of the file to delete:

    for repo in repos
        sha_of_file = get_file_sha(api, path, repo)
        if length(sha_of_file) > 0
           myparams[:sha] = sha_of_file
        end 
        GitHub.delete_file(api, repo, path; params = myparams, kwargs...)
        println("file at $(path) deleted in $(repo.name)")
        delete!(myparams, :sha)
    end
    println("Deletion Complete!")
end

function get_file_sha(api::GitHub.GitHubWebAPI , path_to_file::String, repo::Repo, branch_name = "master"; kwargs...)
    remote_file = nothing
    try
        myparams = Dict(:ref => branch_name)
        remote_file = file(api, repo, path_to_file; params = myparams, kwargs...)
    catch exception
        println("file not found in repository")
        
        return ""
    end

    return String(remote_file.sha)
end

function create_branch(api::GitHub.GitHubWebAPI, new_branch_name::String; current_branch_name = "master")
    url = api.endpoint.uri
end

function main()
    api = GitHub.DEFAULT_API
    # Need to add GITHUB_AUTH to your .bashrc
    myauth = GitHub.authenticate("99c2656683ba93a4f3cb2f01494bcd1bcc416545")
    # parse the arguments:

    parsed_args = parse_commandline()
    org = parsed_args[:org]
    repo_names = parsed_args[:repo]
    is_delete = parsed_args[:delete]
    new_branch_name = parsed_args[:branch]

    """" TODO: fix path behaviour
    for now, when given a path like this: './dir1/dir2/file', joinpath does not give the right path
    However, giving 'dir1/dir2/file' works just fine.
    """

    path_to_file = joinpath(split(parsed_args[:file], '/')...) 

    path_to_file = parsed_args[:file]
    # getting the right repositories given as argument: 

    repositories = repo_names == "all" ? GitHub.repos(api, org; auth = myauth)[1] : [repo for repo in GitHub.repos(api, org; auth = myauth)[1] if repo.name in split(repo_names)]
    
    if is_delete
        delete_file(api, path_to_file, repositories, auth = myauth)
    else
        update_file(api, path_to_file, repositories; auth = myauth)
    end
end

main()