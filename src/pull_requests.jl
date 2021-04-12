function create_pullrequests(api::GitHub.GitHubWebAPI, org::String, repositories::Vector{Repo}, new_branch_name::String, base_branch_name::String, title::String, is_fork::Bool; kwargs...)
    
    [create_pullrequest(api, org, repository, new_branch_name, base_branch_name, title, is_fork; kwargs...) for repository in repositories]
end

function create_pullrequest(api::GitHub.GitHubWebAPI, org::String, repository::Repo, new_branch_name::String, base_branch_name::String, title::String, is_fork::Bool; kwargs...)
    myparams = Dict(:head => new_branch_name, :base => base_branch_name, :title => title)
    if(is_fork)
        println("$(repository.name)-$org:$base_branch_name")
        myparams[:owner] = org
        myparams[:repo] = repository.name
    end
    # check if pr exists
    is_new_pr, pr_number = is_new_pullrequest(api, org, repository, new_branch_name, base_branch_name; kwargs...)
    if is_new_pr
        GitHub.create_pull_request(api, repository; params = myparams, kwargs...)
    else
        GitHub.update_pull_request(api, repository, pr_number; params = myparams, kwargs...)
    end
end

function is_new_pullrequest(api::GitHub.GitHubWebAPI, org::String, repository::Repo, new_branch_name::String, base_branch_name::String; kwargs...)
    myparams = Dict(:base => base_branch_name, :state => "open", :org => org)
    # getting array of pull requests
    prs = pull_requests(api, repository; params = myparams, kwargs...)[1]
    pr_idx = findfirst(pr -> pr.head.ref == new_branch_name, prs)
    if isnothing(pr_idx)
        return true, -1 
    end

    return false, prs[pr_idx].number
end