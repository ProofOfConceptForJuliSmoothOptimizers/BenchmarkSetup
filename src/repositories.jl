const bmark_dependencies = ["PkgBenchmark", "BenchmarkTools", "JLD2", "DataFrames",
                            "ArgParse", "Git", "GitHub", "JSON", "Plots", "SolverBenchmark"]

function setup_benchmarks(api::GitHub.GitHubWebAPI, org::String, repositories::Vector{Repo}, new_branch_name::String, base_branch_name::String, message::String; kwargs...)
    file_paths = [normpath("push_benchmarks.sh"), normpath("benchmark", "run_benchmarks.jl"),
    normpath("benchmark", "send_comment_to_pr.jl"), normpath("Jenkinsfile")]
    for repository in repositories
        clone_repo(repository)
        create_branch(api, org, repository, new_branch_name, base_branch_name; kwargs...)
        println(pwd())
        populate_environment(repository, new_branch_name)
        println(pwd())
        rm(joinpath(@__DIR__, "..",repository.name); force = true, recursive = true)
        println(pwd())
        Pkg.activate("..")
    end
    [update_file(api, file_path, repositories, new_branch_name, "adding/updating file: $file_path"; kwargs...) for file_path in file_paths]
    create_pullrequests(api, org, repositories, new_branch_name, base_branch_name, message; kwargs...)
    println("setting up benchmarks for repositories done ✔")
end

function clone_repo(repository::Repo)
    clone_url = get_clone_url(repository)
    try
        git() do git
            run(`$git clone $(repository.clone_url)`)
        end
    catch exception
        println("The repository already exists locally!")
        println(exception)
    end
end

function populate_environment(repository::Repo, new_branch_name::String)
    cd(joinpath(repository.name))
    git() do git
        run(`$git pull origin`)
        run(`$git checkout $new_branch_name`)
    end
    Pkg.activate(joinpath("benchmark"))
    Pkg.add(bmark_dependencies)
    Pkg.update()
    Pkg.instantiate()
    Pkg.resolve()
    try
        git() do git
            run(`$git add benchmark/Project.toml`)
            run(`$git commit -m "setting up project.toml for benchmarks"`)
            run(`$git pull`)
            run(` $git push`)
        end
    catch exception
        println("Working tree clean, nothing to commit!")
    end
    cd(joinpath(".."))
end

function get_clone_url(repository::Repo)
    credentials = ENV["JSO_GITHUB_AUTH"]
    url = split("$(repository.clone_url)", "https://")

    return "https://" * credentials * "@" * url[2]
end
