using Pkg
bmark_dir = @__DIR__
println(@__DIR__)
Pkg.activate(bmark_dir)
Pkg.instantiate()
repo_name = string(split(ARGS[1], ".")[1])
bmarkname = lowercase(repo_name)
using Git

# if we are running these benchmarks from the git repository
# we want to develop the package instead of using the release
if isdir(joinpath(bmark_dir, "..", ".git"))
  Pkg.develop(PackageSpec(url=joinpath(bmark_dir, "..")))
  bmarkname = Git.head()  # sha of HEAD
end

using DataFrames
using GitHub
using JLD2
using JSON
using PkgBenchmark
using Plots

using SolverBenchmark

# NB: benchmarkpkg will run benchmarks/benchmarks.jl by default
commit = benchmarkpkg(repo_name)  # current state of repository

commit_stats = bmark_results_to_dataframes(commit)

export_markdown("$(bmarkname).md", commit)

function profile_solvers_from_pkgbmark(stats::Dict{Symbol,DataFrame})
  # guard against zero gctimes
  costs = [df -> df[!, :time], df -> df[!, :memory], df -> df[!, :gctime] .+ 1, df -> df[!, :allocations]]
  profile_solvers(stats, costs, ["time", "memory", "gctime+1", "allocations"])
end

# extract stats for each benchmark to plot profiles
# files_dict will be part of json_dict below
files_dict = Dict{String, Any}()
file_num = 1
for k ∈ keys(commit_stats)
  global file_num
  k_stats = Dict{Symbol,DataFrame}(:commit => commit_stats[k])
  save_stats(k_stats, "$(bmarkname)profiles_commit$(k).jld2", force=true)

  k_profile = profile_solvers_from_pkgbmark(k_stats)
  savefig("profiles_commit$(k).svg")
  # read contents of svg file to add to gist
  k_svgfile = open("profiles_commit$(k).svg", "r") do fd
    readlines(fd)
  end
  # file_num makes sure svg files appear before md files (added below)
  files_dict["$(file_num)_$(k).svg"] = Dict{String,Any}("content" => join(k_svgfile))
  file_num += 1
end

for mdfile ∈ [:commit]
  global file_num
  files_dict["$(file_num)_$(mdfile).md"] = Dict{String,Any}("content" => "$(sprint(export_markdown, eval(mdfile)))")
  file_num += 1
end

jldopen("$(bmarkname)profiles_commit.jld2", "w") do file
  println("keys of profile commit: ", keys(file))
end

# json description of gist
json_dict = Dict{String,Any}("description" => "$(repo_name) repository benchmark",
                             "public" => true,
                             "files" => files_dict)

open("gist.json", "w") do f
    JSON.print(f, json_dict)
end
