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
            help = "The name of the repositories on GitHub"
            arg_type = String
            default = "KrylovCI"   
        
    end

    return parse_args(s, as_symbols=true)
end

"""TODO: make sure to put 'branch_name' as an argument in ArgParse and to add it to all
    function that needs the paramater. Add it as a named parameter""" 

function get_repo(api::GitHub.GitHubWebAPI, org::String, repo_name::String; kwargs...)
    my_params = Dict(:visibility => "all")
    # return GitHub.repo(api, repo; params = my_params, kwargs...)
    return Repo(GitHub.gh_get_json(api, "/repos/$(org)/$(repo_name)"; params = my_params, kwargs...))
end

function update_file(api::GitHub.GitHubWebAPI, org::String, path::String; kwargs...)
    repositories, pagedata = GitHub.repos(api, org; kwargs...)
    file = open(path, "r")
    myparams = Dict(:message => "updating file from remote script: $path", :branch => "develop", :content => base64encode(file))
    close(file)
    [GitHub.update_file(api, repo, path; params = myparams , kwargs...) for repo in repositories]

    println("Update Complete!")
end

function update_file(api::GitHub.GitHubWebAPI, org::String, path::String, repo_names::Vector{String}; kwargs...)
    repositories = [get_repo(api, org, repo_name; kwargs...) for repo_name in repo_names]
    file = open(path, "r")
    myparams = Dict(:message => "updating file from remote script: $path", :branch => "develop", :content => base64encode(file))
    close(file)
    return [GitHub.update_file(api, repo, path; params = myparams, kwargs...) for repo in repositories]
end

# TODO: make that function work... 
function delete_file(api::GitHub.GitHubWebAPI, org::String, path::String, repo_names::Vector{String}; kwargs...)
    # Getting sha of the file if needed:
    myparams = Dict(:message => "deleting file from remote script: $path", :branch => "develop")
    # Looking for the git sha1 of the file to delete:
    repositories = [get_repo(api, org, repo_name; kwargs...) for repo_name in repo_names]

    for repo in repositories
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

function get_file_sha(api::GitHub.GitHubWebAPI , path_to_file::String, repo::Repo, branch_name = "develop"; kwargs...)

    myparams = Dict(:ref => branch_name)
    remote_file = file(api, repo, path_to_file; params = myparams, kwargs...)
    return String(remote_file.sha)
end

function main()
    api = GitHub.DEFAULT_API
    # Need to add GITHUB_AUTH to your .bashrc
    myauth = GitHub.authenticate(env["GITHUB_AUTH"])
    # parse the arguments: 
    parsed_args = parse_commandline()
    org = parsed_args[:org]
    repo_names = parsed_args[:repo]
    # creating/updating file in each repo
    repositories, pagedata = GitHub.repos(api, org; auth = myauth)
    path_to_file = "Jenkinsfile"
    
    # To add a file:

    if repo_names == "*"
        update_file(api, org, path_to_file; auth = myauth)
    else
        repo_names = [String(repo_name) for repo_name in split(repo_names)]
        update_file(api, org, path_to_file, repo_names; auth = myauth)
        println("Update Done!")
    end

    # To delete a file: 

    # repo_names = [String(repo_name) for repo_name in split(repo_names)]
    # delete_file(api, org, path_to_file, repo_names, auth = myauth)

end

main()