🎓 Formation DBT - Refactoring & Code Smells
==
# 🛒 Contexte
MegaShop, la branche e-commerce de MegaCompany, a connu une croissance rapide ces derniers mois. Pour répondre aux demandes urgentes du métier, l'équipe Data Engineering a développé de nombreux modèles DBT à marche forcée. Résultat : le pipeline analytique fonctionne... mais la dette technique s'est accumulée.

Aujourd'hui, la qualité du code n'est plus aussi bonne qu'auparavant. Les modèles contiennent des code smells qui rendent la lecture difficile et la maintenance hasardeuse : logique métier dupliquée, requêtes SQL complexes et peu lisibles, noms de colonnes ambigus, macros mal utilisées... Chaque nouvelle évolution prend plus de temps et augmente le risque d'erreur.

L'équipe a décidé de prendre le temps de refactorer le code pour améliorer sa maintenabilité et sa lisibilité. L'objectif : simplifier les transformations, éliminer les duplications, clarifier les intentions, et faciliter les évolutions futures.

C'est là que tu interviens. Ton rôle est clé : identifier les code smells présents dans les modèles DBT et les refactorer pour rendre le code plus propre, plus clair et plus maintenable. On compte sur ton expertise pour nous aider à assainir cette dette technique et faire de MegaShop un modèle d'excellence en matière de qualité de code. Prêt(e) à relever le défi ? 💪


# Installation et découverte du projet DBT

**Installation**
```bash
# Install project dependencies
uv sync

# Install duckdb
curl https://install.duckdb.org | bash
mkdir .db

# Check install
uv run dbt debug
```

**Structure des transformations DBT**

```
formation-dbt-smells/
├── macros/
│   └── capitalize_first_letter.sql             # Macro pour capitaliser la première lettre d'une chaîne
│
├── models/
│   ├── staging/                                # Modèles de staging (préparation des données brutes)
│   │   ├── stg_customers.sql                   # Modèle de staging pour les clients
│   │   ├── stg_customers.yml                   # Documentation et tests pour stg_customers
│   │   ├── stg_orders.sql                      # Modèle de staging pour les commandes
│   │   ├── stg_orders.yml                      # Documentation et tests pour stg_orders
│   │   ├── stg_products.sql                    # Modèle de staging pour les produits
│   │   ├── stg_products.yml                    # Documentation et tests pour stg_products
│
│   ├── marts/                                  # Modèles mart (modèles métiers ou d'analytique)
│   │   ├── mart_customers.sql                  # Modèle mart pour les données clients
│   │   ├── mart_customers.yml                  # Documentation et tests pour mart_customers
│   │   ├── mart_sales_performance_analysis.sql # Modèle mart pour l'analyse des performances des ventes
│   │   ├── mart_sales_performance_analysis.yml # Documentation et tests pour mart_sales_performance_analysis
│
├── seeds/                                      # Données de production
│   ├── customers.csv                           # Données des clients
│   ├── orders.csv                              # Données de commandes
│   ├── products.csv                            # Données de produits
│
├── dbt_project.yml                         # Configuration principale du projet DBT
└── README.md                               # Documentation du projet

```


**🚀 Lancement**
Construis et lance les services :

Exécute DBT :
```bash
# Load seeds
uv run dbt seed --full-refresh

#
uv run dbt run

# Seeds + Test + Run
uv run dbt build
```

Démarre l'UI duckdb:
```bash
uv run duckdb -ui .db/megashop.duckdb
```