function create_branch(api::GitHub.GitHubWebAPI, org::String, repository::Repo, new_branch_name::String, base_branch_name::String; kwargs...)
    if is_new_branch(api, org, repository, new_branch_name; kwargs...)
        base_branch_sha = get_branch_sha(api, org, repository, base_branch_name; kwargs...)
        myparams = Dict(:ref => "refs/heads/$new_branch_name", :sha => base_branch_sha)

        result = GitHub.gh_post_json(api, "/repos/$org/$(repository.name)/git/refs"; params = myparams, kwargs...)
    else
        println("The branch already exists!")
    end
end

function is_new_branch(api::GitHub.GitHubWebAPI, org::String, repository::Repo, branch_name::String; kwargs...)
    refs = map(x-> x["ref"], find_matching_branches(api, org, repository, branch_name; kwargs...))

    return !any(x ->  x == "refs/heads/$branch_name", refs)
end

function find_matching_branches(api::GitHub.GitHubWebAPI, org::String, repository::Repo, branch_name::String; kwargs...)
   
    return GitHub.gh_get_json(api, "/repos/$org/$(repository.name)/git/matching-refs/heads/$branch_name"; kwargs...)
end

function get_branch_sha(api::GitHub.GitHubWebAPI, org::String, repository::Repo, base_branch_name::String; kwargs...) 
    try    
        base_branch_dict = GitHub.gh_get_json(api, "/repos/$org/$(repository.name)/git/ref/heads/$base_branch_name"; kwargs...)

        return base_branch_dict["object"]["sha"]
    catch exception
        println("Error trying to find Base branch. Make sure the base branch exists!")
    end
end