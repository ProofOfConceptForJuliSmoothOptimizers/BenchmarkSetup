#!/bin/bash

julia --project=BenchmarkSetup BenchmarkSetup/benchmark/send_comment_to_pr.jl -o $org -r $repo -p $pullrequest -c '**Starting unit tests!**'

# Specify the module to test (e.g "HSL")
julia -E 'using Pkg; module_name = split(ENV["repo"], ".")[1]; Pkg.activate("test_env"); Pkg.develop(PackageSpec(url=joinpath("."))); Pkg.test(module_name)' &> "$org"_"$repo"_"$pullrequest".txt

# Create the gist and create comment on PR:
julia BenchmarkSetup/test/send_gist_url.jl
exit_status=$?

if [ $exit_status -ne 0 ] ; then
    ERROR_LOGS="/home/jenkins/tests/$org/$repo/${pullrequest}_${BUILD_NUMBER}_error.log"
    julia --project=BenchmarkSetup BenchmarkSetup/benchmark/send_comment_to_pr.jl -o $org -r $repo -p $pullrequest -c "**An error occured while running the unit tests: **" -g $ERROR_LOGS
fi

git clean -fd
git reset --hard
rm -rf BenchmarkSetup*