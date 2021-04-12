
function fork_repositories(api::GitHub.GitHubWebAPI, org::String, repositories::Vector{Repo}, dest_org::String; kwargs...)
    for repo in repositories
        fork_repository(api, org, repo, dest_org; kwargs...)
    end
end

# Note: Organization to fork from is hardcoded for simplicity
function fork_repository(api::GitHub.GitHubWebAPI, org::String, repository::Repo, dest_org::String; kwargs...)
    try
        myparams = Dict(:owner => org, :organization => dest_org)
        result = GitHub.gh_post_json(api, "/repos/$org/$(repository.name)/forks"; params=myparams, kwargs...)
        println("Repository $(repository.name) forked!")
    catch exception
        println("Exception occured while forking repo: ", exception)
    end
end

