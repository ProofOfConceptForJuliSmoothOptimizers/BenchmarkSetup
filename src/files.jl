
function update_file(
    api::GitHub.GitHubWebAPI,
    path::String,
    repositories::Vector{Repo},
    new_branch_name::String,
    message::String;
    kwargs...,
)
    try
        file = open(path, "r")
        myparams = Dict(
            :branch => new_branch_name,
            :message => message,
            :content => base64encode(file),
        )
        close(file)
        for repo in repositories
            sha_of_file = get_file_sha(api, path, repo, new_branch_name)
            if length(sha_of_file) > 0
                myparams[:sha] = sha_of_file
            end
            GitHub.update_file(api, repo, path; params = myparams, kwargs...)
            println("file at $(path) updated in $(repo.name)")
            delete!(myparams, :sha)
        end
    catch exception
        println("Couldn't update file!")
    end
end

function delete_file(
    api::GitHub.GitHubWebAPI,
    path::String,
    repos::Vector{Repo},
    new_branch_name::String,
    message::String;
    kwargs...,
)
    # Getting sha of the file if needed:
    myparams = Dict(:branch => new_branch_name, :message => message)
    # Looking for the git sha1 of the file to delete:

    for repo in repos
        sha_of_file = get_file_sha(api, path, repo, new_branch_name)
        if length(sha_of_file) > 0
            myparams[:sha] = sha_of_file
        end
        # TODO: handle errors when the file to delete does not exist remotely
        GitHub.delete_file(
            api,
            repo,
            path;
            params = myparams,
            handle_error = false,
            kwargs...,
        )
        println("file at $(path) deleted in $(repo.name)")
        delete!(myparams, :sha)
    end
    println("Deletion Complete!")
end

function get_file_sha(
    api::GitHub.GitHubWebAPI,
    path::String,
    repo::Repo,
    branch_name::String;
    kwargs...,
)
    remote_file = nothing
    try
        myparams = Dict(:ref => branch_name)
        remote_file = file(api, repo, path; params = myparams, kwargs...)
    catch exception
        println("file not found in repository")

        return ""
    end

    return String(remote_file.sha)
end
