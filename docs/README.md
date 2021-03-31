# JSOBot: How to benchmark with ease

JSOBot is the new member of the organization that will be able to benchmark any module of the organization.


## What does it do?

JSOBot's most basic function is to benchmark a repository by comparing a branch to the master. This way, the developers can easily check if the new changes made are having an impact on the the performances of the given module.

**The bot will always compare the latest commit of the current branch with the lastest version of the master branch.**

<p align="center">
	<img src="images/image1.png"/>

## How do I set it up?

To set up JSOBot on your julia module, simply clone this [repository](https://github.com/ProofOfConceptForJuliSmoothOptimizers/BenchmarkSetup).

In `BenchmarkSetup`, run: 

`julia src/setup_benchmarks.jl --org ${your_organization} --repo ${your_repo} --new_branch ${branch_name} --title {pr_title} --webhook`

If you want to setup the webhooks manually, simply omit the `--webhook` argument and follow [this guide](webhook_setup.md).

`setup_benchmarks.jl` adds all the necessary dependencies to the `Project.toml`.

## How do I run my benchmarks?

First, make sure you have a pull request containing all your commits. 

Make sure you have all the necessary files on your branch and on the master branch and that the webhook is correctly configured. [See here](webhook_setup.md).  

**Verify that the `token` variable in the Jenkinsfile has the same value as the token in the payload url of the webhook.**

After connecting to the Jenkins server, make sure that you see your repository. If you can't find it, click on the `Scan repository now`.

<p>
    <img src="images/image2.png">
</p>

After clicking on your repository, you should be able to see your branch. If you don't, simply click on `Scan Repository Now`.

<p>
    <img src="images/image3.png">
</p>

After clicking on your branch, make sure to run the build manually by clicking `Build Now`.

<p>
    <img src="images/image4.png">
</p>

Now, you can run the benchmarks by commenting on your PR:

"@JSOBot runbenchmarks"

Give it some time and it should respond with another comment. Eventually, it will post a link to a gist containing the results! 

## Prerequisites

To benchmark a module, some requirements need to be met. Some files are required for it to work properly.

All the necessary files can be found [here](https://github.com/ProofOfConceptForJuliSmoothOptimizers/BenchmarkSetup)!
 
Here are the files required **at the base of your repository AND at the branch you want to benchmark**:

1. A `Jenkinsfile` needs to be in the master branch.
2. A `Jenkinsfile` needs to be in the branch you want to benchmark (different than master).
3. A bash script called `push_benchmarks.sh`.

It is necessary for a module to have a `benchmark` folder. That folder needs to contain some specific files: 

1. `benchmarks.jl` to define the how to benchmark the module.
2. `run_benchmarks.jl` to run the benchmarks.
3. `send_comment_to_pr.jl`. This script is what sends the results of the benchmarks to the pull request.

For all these scripts to work, you need to add some modules to `benchmark/Project.toml`.

If you wish to these modules manually, execute the following in the julia REPL:

```
using Pkg
Pkg.add(["PkgBenchmark", "BenchmarkTools", "JLD2", "DataFrames", "ArgParse", "Git", "GitHub", "JSON", "Plots", "SolverBenchmark"])
```

JSOBot also requires a webhook to be set up for the repository that needs to benchmarked. You can set up the webhook manually [here](webhook_setup.md).




