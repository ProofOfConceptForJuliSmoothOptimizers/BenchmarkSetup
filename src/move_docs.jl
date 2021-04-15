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

repositories = GitHub.repos(api, org; auth = myauth)[1]

function update_docs(api, org, repositories; kwargs...)
    for repo in repositories
        has_change = false
        clone_repo(repo)
        cd(repo.name) do
            git() do git
                try
                    run(`$git checkout workflows --`)
                catch
                    run(`$git checkout -b workflows --`)
                end

            end
            if("docs" in readdir())
                cd("docs") do 
                    if("index.md" in readdir())
                        run(`mv index.md src/`)
                        has_change = true
                        println("index.md moved to src folder")
                    end
                    if("tutorial.md" in readdir())
                        run(`mv tutorial.md src/`)
                        has_change = true
                        println("tutorial.md moved to src folder")
                    end
                    if("reference.md" in readdir())
                        run(`mv reference.md src/`)
                        has_change = true
                        println("reference.md moved to src folder")
                    end
                end
            else
                println("docs folder not found in $(repo.name)")
            end
            git() do git
                if(has_change)
                    run(`$git add docs`)
                    run(`$git commit -m "fix docs folder structure"`)
                    try
                        run(`$git push origin workflows`)
                    catch
                        run(`$git push -u origin workflows`)
                    end
                    create_pullrequest(api, org, repo, "workflows", "master", "Update CI, TagBot and documentation workflows"; kwargs...)
                end
            end
        end
        rm(joinpath(@__DIR__, "..", repo.name); force = true, recursive = true)
    end
end
filter!(repo -> (match(r"^AMD.jl$", repo.name) != nothing), repositories)
update_docs(api, org, repositories; auth=myauth)