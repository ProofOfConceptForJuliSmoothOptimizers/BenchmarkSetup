
## Création du Webhook pour LDLFactorizations.jl

Afin de connecter l'API de GitHub au serveur distant Jenkins, il faut ajouter un webhook au dépôt souhaité (i.e LDLFactorizations).

Voici les étapes à suivre:

1. Dans le `Jenkinsfile`, Il faut prendre note de la valeur de la variable `token` et s'assurer que celle-ci contient le nom du dépôt sans le ".jl" (i.e `token: LDLFactorizations`).

2.  Aller dans **Settings** puis dans **Webhooks** du dépôt. 
	![](https://res.cloudinary.com/practicaldev/image/fetch/s--FG6s3z8s--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://thepracticaldev.s3.amazonaws.com/i/9g49g2mg4pbjrasyo7fz.png)
	* Cliquer sur **Add webhook**.
3.  Voici la page pour créer le Webhook en question: 

![](https://res.cloudinary.com/practicaldev/image/fetch/s--uBEnAyMb--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_880/https://thepracticaldev.s3.amazonaws.com/i/kwfykcgytaqvzxaz8gks.png)
* Il faut mettre dans le **payload URL** l'adresse du serveur distant : http://frontal22.recherche.polymtl.ca:8080/generic-webhook-trigger/invoke?token=LDLFactorizations 
	* Il est à noter que le token dans l'URL est le même que celui spécifié dans le Jenkinsfile. C'est graĉe à ce token que Jenkins sait quel dépôt lance une job. **Il est donc capital que le token dans le Jenkinsfile aît la même valeur que dans le payload du webhook!**

* Pour le **Content Type** , il faut choisir l'option **application/json**

* Laisser la section **Secret** vide pour le moment. Éventuellement, il faudra en rajouter un pour sécuriser au plus possible la communication entre GitHub et Jenkins.
4. Sélectionner plus bas **Let me select individual events** et choisir: 
	1.  Issue comments
	2. Pull requests

5. Cliquer sur **Update webhook** et c'est terminé!

 Lorsqu'un nouveau dépôt est ajouté avec un nouveau token, jenkins a parfois du mal à se synchroniser. Il est donc judicieux de partir un build manuellement après avoir setup le webhook. Pour les prochaines fois, écrire un commentaire dans la pull request suffira. 
 

