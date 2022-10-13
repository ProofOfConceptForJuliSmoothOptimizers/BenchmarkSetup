#!/bin/bash

# Specify the module to test (e.g "HSL")
julia -E 'using Pkg; module_name = split(ENV["repo"], ".")[1]; Pkg.activate("test_env"); Pkg.develop(PackageSpec(url=joinpath("."))); Pkg.test(module_name)' &> "$org"_"$repo"_"$pullrequest".txt

# Create the gist and create comment on PR:
julia BenchmarkSetup/test/send_gist_url.jl


git clean -fd
git reset --hard
rm -rf BenchmarkSetup*