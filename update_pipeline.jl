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
using SHA

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

function get_repo(api::GitHub.GitHubWebAPI, org::String, repo_name::String; kwargs...)
    my_params = Dict(:visibility => "all")
    # return GitHub.repo(api, repo; params = my_params, kwargs...)
    return Repo(GitHub.gh_get_json(api, "/repos/$(org)/$(repo_name)"; params = my_params, kwargs...))
end

function update_pipeline(api::GitHub.GitHubWebAPI, org::String, path::String; kwargs...)
    repositories, pagedata = GitHub.repos(api, org; kwargs...)

    return [GitHub.update_file(api, repo, path; kwargs...) for repo in repositories]
end

function update_pipeline(api::GitHub.GitHubWebAPI, org::String, path::String, repo_names::Vector{String}; kwargs...)
    repositories = [get_repo(api, org, repo_name; kwargs...) for repo_name in repo_names]

    return [GitHub.update_file(api, repo, path; kwargs...) for repo in repositories]
end


function main()
    api = GitHub.DEFAULT_API
    # TODO: to remove this line after testing, this is the Auth of JSOBot
    GITHUB_AUTH = "99c2656683ba93a4f3cb2f01494bcd1bcc416545"
    # Need to add GITHUB_AUTH to your .bashrc
    myauth = GitHub.authenticate(GITHUB_AUTH)
    # parse the arguments: 
    parsed_args = parse_commandline()
    org = parsed_args[:org]
    repo_names = parsed_args[:repo]
    # creatinf ile in each repo
    repositories, pagedata = GitHub.repos(api, org; auth = myauth)
    file_name = "test.txt"
    file = open(file_name, "r")
    myparams = Dict(:message => "updating file from remote script: $file_name", :branch => "develop", :content => base64encode(file))
    updated_content = nothing
    if repo_names == "*"
        updated_content = update_pipeline(api, org, file_name; auth = myauth, params = myparams)
    else
        repo_names = [String(repo_name) for repo_name in split(repo_names)]
        updated_content = update_pipeline(api, org, file_name, repo_names; auth = myauth, params = myparams)
    end
    print(updated_content)
    # sha = Git.ls
    # sha = join([string(x, base = 16, pad = 2) for x in sha1(file)])
    # myparams = Dict(:message => "deleting file from remote script: $file_name", :branch => "develop", :sha => sha)
    # GitHub.delete_file(api, org, file_name; auth = myauth, params = myparams)
    close(file)
end
main()


# cmd = Git.cmd(Cmd(`git ls-files -s test.txt`))
# sha = Git.run(cmd)
# open("test.txt", "r") do file
#     sha = sha1(file)
#     println(sha)
#     println(join([string(x, base = 16, pad = 2) for x in sha]))
# end