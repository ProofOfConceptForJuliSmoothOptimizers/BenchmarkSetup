const PAYLOAD_URL= "http://frontal22.recherche.polymtl.ca:8080/generic-webhook-trigger/invoke?token="

function is_new_webhook(api::GitHub.GitHubWebAPI, org::String, repository::Repo, config_dict::Dict{Symbol, Any}; kwargs...)
    try
        response = GitHub.gh_get_json(api, "/repos/$org/$(repository.name)/hooks"; kwargs...)
        webhooks = [Webhook(res) for res in response]
    
        return !any(hook -> hook.config["url"] == config_dict[:url], webhooks)
    catch exception
        println("no webhook found in repo: $(repository.name)")
        
        return true
    end
end

function create_benchmark_webhook(api::GitHub.GitHubWebAPI, org::String, repository::Repo; kwargs...)
    webhook_config = Dict(:url => "$(PAYLOAD_URL)$(format_repository_name(repository))", :content_type => "json",
                            :insecure_ssl => "0", :active => true)
    
    if is_new_webhook(api, org, repository, webhook_config; kwargs...)
        myparams = Dict(:config => webhook_config, :events => ["issue_comment"])
        response = GitHub.gh_post_json(api, "/repos/$org/$(repository.name)/hooks"; params = myparams, kwargs...)
        new_webhook = Webhook(response)

        return new_webhook
    end

    println("the webhook already exists with this payload url!")
end

function format_repository_name(repo::Repo)

    return split(repo.name, ".")[1]
end

