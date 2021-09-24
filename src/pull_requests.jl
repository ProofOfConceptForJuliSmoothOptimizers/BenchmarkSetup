function create_pullrequests(
    api::GitHub.GitHubWebAPI,
    org::String,
    repositories::Vector{Repo},
    new_branch_name::String,
    base_branch_name::String,
    title::String;
    kwargs...,
)

    [
        create_pullrequest(
            api,
            org,
            repository,
            new_branch_name,
            base_branch_name,
            title;
            kwargs...,
        ) for repository in repositories
    ]
end

function create_pullrequest(
    api::GitHub.GitHubWebAPI,
    org::String,
    repository::Repo,
    new_branch_name::String,
    base_branch_name::String,
    title::String;
    kwargs...,
)
    try
        myparams =
            Dict(:head => new_branch_name, :base => base_branch_name, :title => title)

        # check if pr exists
        is_new_pr, pr_number = is_new_pullrequest(
            api,
            org,
            repository,
            new_branch_name,
            base_branch_name;
            kwargs...,
        )
        if is_new_pr
            GitHub.create_pull_request(api, repository; params = myparams, kwargs...)
        else
            GitHub.update_pull_request(
                api,
                repository,
                pr_number;
                params = myparams,
                kwargs...,
            )
        end
    catch exception
        println("Couldn't create PR: $exception")
    end
end

function is_new_pullrequest(
    api::GitHub.GitHubWebAPI,
    org::String,
    repository::Repo,
    new_branch_name::String,
    base_branch_name::String;
    kwargs...,
)
    myparams = Dict(:base => base_branch_name, :state => "open", :org => org)
    # getting array of pull requests
    prs = pull_requests(api, repository; params = myparams, kwargs...)[1]
    pr_idx = findfirst(pr -> pr.head.ref == new_branch_name, prs)
    if isnothing(pr_idx)
        return true, -1
    end

    return false, prs[pr_idx].number
end
