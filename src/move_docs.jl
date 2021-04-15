using Pkg
Pkg.activate(".")
using GitHub
using GitCommand

include(joinpath(@__DIR__,"files.jl"))
include(joinpath(@__DIR__,"branches.jl"))
include(joinpath(@__DIR__,"pull_requests.jl"))
include(joinpath(@__DIR__,"utils.jl"))
include(joinpath(@__DIR__,"webhooks.jl"))
include(joinpath(@__DIR__, "repositories.jl"))

api = GitHub.DEFAULT_API
# Need to add GITHUB_AUTH to your .bashrc
myauth = GitHub.authenticate(ENV["JSO_GITHUB_AUTH"])

repositories = GitHub.repos(api, org; auth = myauth)[1]

function update_docs(api, org, repositories; kwargs...)
    for repo in repositories
        clone_repo(repo)
        cd(repo.name) do
            if()
        end
    end

end