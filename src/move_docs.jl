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
org = "JuliaSmoothOptimizers"
# org = "ProofOfConceptForJuliSmoothOptimizers"
myauth = GitHub.authenticate(ENV["JSO_GITHUB_AUTH"])

file_body = 
"""
# Reference
​
## Contents
​
```@contents
Pages = ["reference.md"]
```
​
## Index
​
```@index
Pages = ["reference.md"]
```
​
```@autodocs
"""
end_of_file = "```"

repositories = GitHub.repos(api, org; auth = myauth)[1]

function update_docs(api, org, repositories; kwargs...)
    for repo in repositories
        has_docs = false
        repo_ref = "Modules = [$(split(repo.name, '.')[1])]\n"
        clone_repo(repo)
        cd(repo.name) do
            try
                run(`$(git()) checkout workflows --`)
            catch
                run(`$(git()) checkout -b workflows --`)
            end

            if("docs" in readdir())
                has_docs = true 
                cd(joinpath("docs", "src")) do
                    if("reference.md" in readdir())
                        open("reference.md", "w") do file
                            write(file, file_body)
                            write(file, repo_ref)
                            write(file, end_of_file)
                        end
                    end
                end
            else
                println("docs folder not found in $(repo.name)")
            end
            if(has_docs)
                run(`$(git()) add docs`)
                try
                    run(`$(git()) commit -m "fix reference.md"`)
                    run(`$(git()) push origin workflows`)
                catch
                    run(`$(git()) push -u origin workflows`)
                end
                create_pullrequest(api, org, repo, "workflows", "main", "Update CI, TagBot and documentation workflows"; kwargs...)
            end
        end
        rm(joinpath(@__DIR__, "..", repo.name); force = true, recursive = true)
    end
end
# filter!(repo -> (match(r"^AMD.jl$", repo.name) != nothing), repositories)
update_docs(api, org, repositories; auth=myauth)