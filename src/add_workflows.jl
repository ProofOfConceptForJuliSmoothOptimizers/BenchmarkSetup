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

for repo in repositories
    clone_repo(repo)
    file_paths = get_file_paths(".github/workflows")
    cd(repo.name) do
        git() do git
            try
                run(`$git checkout workflows --`)
            catch
                run(`$git checkout -b workflows --`)
            end
        end
        run(`mkdir -p .github/workflows`)
        [cp("../$file_path", file_path; force=true) for file_path in file_paths]
        run(`cp ../.JuliaFormatter.toml ./`)

        git() do git
            run(`$git add .github/workflows`)
            run(`$git add ./.JuliaFormatter.toml`)
            try
                run(`$git commit -m "Adding files for workflow and for formatting"`)
                run(`$git push origin workflows`)
            catch
                run(`$git push -u origin workflows`)
            end
            create_pullrequest(api, org, repo, "workflows", "main", "Update CI, TagBot and documentation workflows"; auth=myauth)
            # create_pullrequest(api, org, repo, "workflows", "main", "This is a test PR for workflows"; auth=myauth)
        end
    end
    rm(joinpath(@__DIR__, "..", repo.name); force = true, recursive = true)
end

