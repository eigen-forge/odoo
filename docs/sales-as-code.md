# Configuration du module Ventes « as code » — Odoo Community 19

Ce premier exemple utilise un **module Odoo Community installable** (eigen_sales_config). Il dépend du module officiel **Ventes** (sale_management) et configure trois paramètres existants de la société principale :

| Paramètre dans Odoo | Valeur d'exemple | Champ technique |
| --- | --- | --- |
| Durée par défaut des devis | 21 jours | quotation_validity_days |
| Signature en ligne des devis | Activée | portal_confirmation_sign |
| Paiement en ligne exigé à la confirmation du devis | Désactivé | portal_confirmation_pay |

La configuration se trouve dans **addons/eigen_sales_config/data/sales_defaults.xml**. C'est ce fichier qu'on modifie pour faire évoluer les paramètres. Les valeurs sont réappliquées lors de l'installation (-i) ou de la mise à jour (-u) du module.

## Prérequis

1. PostgreSQL et Odoo démarrent correctement avec Docker Compose.
2. Une base Odoo a déjà été créée depuis l'interface de démarrage (par exemple **odoo_demo**).
3. Le dépôt est à jour avec **git pull --ff-only**.

## Windows PowerShell : installation et mise à jour

Depuis C:\dev\odoo, installer le profil Ventes sur **une seule base** :

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply-sales-config.ps1 -Database odoo_demo -Action install
~~~

Après avoir modifié et versionné les paramètres XML, les réappliquer :

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply-sales-config.ps1 -Database odoo_demo -Action upgrade
~~~

Le script arrête temporairement le service web Odoo, lance l'installation/la mise à jour pour la base choisie, puis redémarre le service. **Les autres bases Odoo ne sont pas modifiées**, mais leurs utilisateurs subiront aussi une brève interruption si le serveur applicatif est partagé. Ne pas utiliser tel quel en production multi-tenant sans orchestrateur de maintenance.

## Linux/macOS : commandes Docker Compose

~~~bash
# Installation initiale dans odoo_demo :
docker compose stop odoo
docker compose run --rm -T odoo -d odoo_demo -i eigen_sales_config --stop-after-init --no-http
docker compose up -d odoo

# Mise à jour (après modification du XML et git pull) :
docker compose stop odoo
docker compose run --rm -T odoo -d odoo_demo -u eigen_sales_config --stop-after-init --no-http
docker compose up -d odoo
~~~

Si l'installation échoue, vérifier docker compose logs --tail=100 db et docker compose logs --tail=100 odoo. Ne pas détruire les volumes.

## Vérifier la configuration appliquée

Dans Odoo, ouvrir Ventes et les paramètres des devis. Pour vérifier techniquement la base odoo_demo :

~~~powershell
docker compose exec -T db psql -U odoo -d odoo_demo -c "SELECT quotation_validity_days, portal_confirmation_sign, portal_confirmation_pay FROM res_company WHERE id = (SELECT res_id FROM ir_model_data WHERE module = 'base' AND name = 'main_company');"
~~~

Résultat attendu : **21**, **t**, **f**.

## Isolation et personnalisation par client

- Chaque **base Odoo** a ses propres applications installées, sociétés, utilisateurs et paramètres.
- Installer eigen_sales_config dans la base A ne l'installe pas dans la base B.
- Le module d'exemple cible explicitement **base.main_company dans la base sélectionnée** ; il ne configure pas les autres sociétés présentes dans la même base.
- Pour des valeurs différentes entre entreprises A et B, créer des profils complémentaires (modules distincts installés dans les bases concernées) ou ajouter ultérieurement un provisionneur SaaS déclaratif par tenant. **Ne pas installer deux profils modifiant les mêmes paramètres dans une base.**
- Une mise à jour -u réapplique les valeurs définies dans Git et peut écraser une modification manuelle dans l'interface, conformément au principe « as code ».

Ce module ne modifie pas le moteur de vente d'Odoo et n'active aucune fonctionnalité Enterprise. Il ne crée pas encore de souscriptions SaaS ni de bases clients.

## Contrôles statiques

~~~bash
python -m unittest discover -s tests -v
~~~

Les tests statiques ne remplacent pas un essai réel d'installation dans Odoo 19 avec PostgreSQL.
