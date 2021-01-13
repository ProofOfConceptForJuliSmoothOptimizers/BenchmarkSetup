using Pkg
bmark_dir = joinpath(@__DIR__, "env")
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
            help = "Name of GitHub Organization."
            arg_type = String
            default = "ProofOfConceptForJuliSmoothOptimizers"
        "--repo", "-r"
            help = "The name of the repositories on GitHub. To select all repos, simply write : 'all'."
            arg_type = String
            default = "Krylov.jl"
        "--delete", "-d"
            help = "specifies if it's a deletion process."
            action = :store_true
        "--new_branch", "-b"
            help = "the name of the new branch on which the modifications will be made. It must be a new branch name."
            arg_type = String   
            required = true
        "--base_branch", "-B"
            help = "The name of an existing branch. 'master' is the default value."
            default = "master"
        "--file", "-f"
            help = "path to file to update (e.g dir1/dir2/file_to_update.txt). 
                    Make sure to use the '/' delimiter for the path."
        "--message", "-m"
            help = "Commit message describing the modification."
            arg_type = String
            required = false

    end

    return parse_args(s, as_symbols=true)
end

"""TODO: make sure to put 'branch_name' as an argument in ArgParse and to add it to all
    function that needs the paramater. Add it as a named parameter""" 

function update_file(api::GitHub.GitHubWebAPI, path::String, repositories::Vector{Repo}, new_branch_name::String, message::String; kwargs...)
    file = open(path, "r")
    myparams = Dict(:branch => new_branch_name, :message => message,  :content => base64encode(file))
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

function delete_file(api::GitHub.GitHubWebAPI, path::String, repos::Vector{Repo}, new_branch_name::String, message::String; kwargs...)
    # Getting sha of the file if needed:
    myparams = Dict(:branch => new_branch_name, :message => message)
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

function create_pullrequest(api::GitHub.GitHubWebAPI, repository::Repo, new_branch_name::String, base_branch::String, message::String; kwargs...)

    myparams = Dict(:head => new_branch_name, :base => base_branch, :title => message)

    GitHub.create_pull_request(api, repository; params = myparams, kwargs...)
end

function create_pullrequests(api::GitHub.GitHubWebAPI, repositories::Vector{Repo}, new_branch_name::String, base_branch::String, message::String; kwargs...)
    
    [create_pullrequest(api, repository, new_branch_name, base_branch, message; kwargs...) for repository in repositories]
end

# TODO: make this method smart enough to detect if the new branch exists already
function create_branch(api::GitHub.GitHubWebAPI, org::String, repository::Repo, new_branch_name::String, base_branch::String; kwargs...)
    base_branch_sha = get_branch_sha(api::GitHub.GitHubWebAPI, org::String, repository::Repo, base_branch::String; kwargs...)
    myparams = Dict(:ref => "refs/heads/$new_branch_name", :sha => base_branch_sha)

    result = GitHub.gh_post_json(api, "/repos/$org/$(repository.name)/git/refs"; params = myparams, kwargs...)
end

function create_branches(api::GitHub.GitHubWebAPI, org::String, repositories::Vector{Repo}, new_branch_name::String, base_branch::String; kwargs...)

    [create_branch(api, org, repository, new_branch_name, base_branch; kwargs...) for repository in repositories]
end

function get_branch_sha(api::GitHub.GitHubWebAPI, org::String, repository::Repo, base_branch::String; kwargs...) 
    base_branch_dict = GitHub.gh_get_json(api, "/repos/$org/$(repository.name)/git/ref/heads/$base_branch"; kwargs...)
    
    return base_branch_dict["object"]["sha"]
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
    new_branch = parsed_args[:new_branch]
    base_branch = parsed_args[:base_branch]
    message = parsed_args[:message]

    # Debug:

    new_branch_name = "test-br"
    file = "dir1/test.txt"
    is_delete = false

    """" TODO: fix path behaviour
    for now, when given a path like this: './dir1/dir2/file', joinpath does not give the right path
    However, giving 'dir1/dir2/file' works just fine.
    """
    
    # assigning default value to commit message: 

    message = isnothing(message) ?  "updating/deleting file from remote script: $path" : message

    path_to_file = parsed_args[:file]
    # getting the right repositories given as argument: 

    repositories = repo_names == "all" ? GitHub.repos(api, org; auth = myauth)[1] : [repo for repo in GitHub.repos(api, org; auth = myauth)[1] if repo.name in split(repo_names)]
    
    # creating new branches for each repo.
    create_branches(api, org, repositories, new_branch_name, base_branch; auth = myauth)

    if is_delete
        delete_file(api, path_to_file, repositories, new_branch, message, auth = myauth)
    else
        update_file(api, path_to_file, repositories, new_branch, message; auth = myauth)
    end
    
    # creating pull request 
    create_pullrequests(api, repositories, new_branch, base_branch, message; auth = myauth)
end

main()