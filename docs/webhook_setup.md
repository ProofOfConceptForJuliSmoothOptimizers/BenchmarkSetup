
## Webhook setup for a Julia module

A webhook needs to be setup to communicate with the remote server that will run the benchmarks.

Here are the following steps:

1. In the `Jenkinsfile`, set the value of the `token` variable to *module_name* without the ".jl" (e.g `token: LDLFactorizations`).

2.  Go to **Settings** and in **Webhooks** of the repository. 
	![](https://res.cloudinary.com/practicaldev/image/fetch/s--FG6s3z8s--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://thepracticaldev.s3.amazonaws.com/i/9g49g2mg4pbjrasyo7fz.png)
	* Click on **Add webhook**.
3.  You should be in a page like this: 

	![](https://res.cloudinary.com/practicaldev/image/fetch/s--uBEnAyMb--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://thepracticaldev.s3.amazonaws.com/i/kwfykcgytaqvzxaz8gks.png)
* In  **payload URL** , add the following address: http://frontal22.recherche.polymtl.ca:8080/generic-webhook-trigger/invoke?token=module_name.  
	* replace `module_name` with the value of the `token` variable found in the `Jenkinsfile`. **The token in the `Jenkinsfile` must be the same as the one in the url.**

* In the **Content Type** , choose the **application/json** option.

4. Choose **Let me select individual events** and select the following: 
	*  Issue comments

5. Click on **Update webhook/Add webhook** and you are done!


