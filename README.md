# Application de Réservation de Salles

Application Java complète de gestion de réservations de salles, développée avec **JPA/Hibernate**, incluant un cache de second niveau, des scénarios de test, un script de migration SQL et un rapport de performance.

---


##  Structure du projet

```
reservation-salles/
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── model/
│   │   │   │   ├── Utilisateur.java
│   │   │   │   ├── Salle.java
│   │   │   │   ├── Reservation.java
│   │   │   │   ├── Equipement.java
│   │   │   │   └── StatutReservation.java
│   │   │   ├── repository/
│   │   │   │   ├── SalleRepository.java / SalleRepositoryImpl.java
│   │   │   │   └── ReservationRepository.java / ReservationRepositoryImpl.java
│   │   │   ├── service/
│   │   │   │   ├── SalleService.java / SalleServiceImpl.java
│   │   │   │   └── ReservationService.java / ReservationServiceImpl.java
│   │   │   ├── test/
│   │   │   │   └── TestScenarios.java
│   │   │   ├── util/
│   │   │   │   ├── DataInitializer.java
│   │   │   │   ├── DatabaseMigrationTool.java
│   │   │   │   ├── PerformanceReport.java
│   │   │   │   └── PaginationResult.java
│   │   │   └── App.java
│   │   └── resources/
│   │       ├── META-INF/
│   │       │   └── persistence.xml
│   │       ├── ehcache.xml
│   │       └── migration_v2.sql
│   └── test/
└── pom.xml
```

---


### Entités principales

| Entité | Table SQL | Description |
|--------|-----------|-------------|
| `Utilisateur` | `utilisateurs` | Employés pouvant réserver des salles |
| `Salle` | `salles` | Salles disponibles à la réservation |
| `Reservation` | `reservations` | Lien entre un utilisateur et une salle sur un créneau |
| `Equipement` | `equipements` | Équipements associés aux salles |

### Relations

- `Utilisateur` -> `Reservation` : **OneToMany**
- `Salle` -> `Reservation` : **OneToMany**
- `Salle` <-> `Equipement` : **ManyToMany** (table de jointure `salle_equipement`)

### Statuts de réservation (`StatutReservation`)

```
CONFIRMEE | EN_ATTENTE | ANNULEE
```

### Optimistic Locking

Toutes les entités disposent d'un champ `@Version` pour gérer les accès concurrents sans verrouillage pessimiste.

---




##  Menu principal

```
=== MENU PRINCIPAL ===
1. Initialiser les données de test
2. Exécuter les scénarios de test
3. Exécuter le script de migration
4. Générer un rapport de performance
5. Quitter
```

---

##  Scénarios de test

La classe `TestScenarios` exécute 5 tests automatisés :

| # | Test | Description |
|---|------|-------------|
| 1 | Recherche de disponibilité | Trouve les salles libres sur un créneau donné |
| 2 | Recherche multi-critères | Filtre par capacité, bâtiment, étage, équipements |
| 3 | Pagination | Navigation paginée sur la liste des salles |
| 4 | Optimistic Locking | Simulation de 2 threads modifiant la même réservation |
| 5 | Performance du cache | Comparaison des temps d'accès avec et sans cache L2 |

### Lancer tous les tests

```java
TestScenarios testScenarios = new TestScenarios(emf, salleService, reservationService);
testScenarios.runAllTests();
```

---

##  Migration de base de données

Le script `migration_v2.sql` met à jour une base existante vers la **version 2.0** :

1. Sauvegarde des tables existantes
2. Ajout des nouvelles colonnes (`departement`, `numero`, `statut`, `version`, etc.)
3. Création d'index de performance
4. Ajout de contraintes d'intégrité
5. Création d'une vue `vue_reservations_completes`
6. Procédure stockée `nettoyer_anciennes_reservations`

### Exécution programmatique

```java
DatabaseMigrationTool migrationTool = new DatabaseMigrationTool(
    "jdbc:mysql://localhost:3306/reservation_salles",
    "root",
    "password"
);
migrationTool.executeMigration();
```

---

##  Rapport de performance

La classe `PerformanceReport` mesure et analyse les performances de l'application, puis génère un fichier texte horodaté.

### Métriques collectées

- Temps d'exécution (ms)
- Nombre de requêtes SQL générées
- Entités chargées
- Hits / Miss du cache de second niveau
- Ratio de hit du cache (%)

### Exemple de rapport

```
Test: Accès répété avec cache
Temps d'exécution: 320ms
Hits du cache: 99
Miss du cache: 1
Ratio de hit du cache: 99.00%
```

### Génération

```java
PerformanceReport report = new PerformanceReport(emf);
report.runPerformanceTests();
// → génère performance_report_20230515_143022.txt
```

---

##  Jeu de données de test

`DataInitializer` génère automatiquement :

- **10** équipements (projecteurs, écrans, systèmes audio, etc.)
- **20** utilisateurs répartis dans 10 départements
- **15** salles dans 3 bâtiments (A, B, C)
- **100** réservations aléatoires sur 90 jours (80% confirmées, 10% en attente, 10% annulées)

```java
DataInitializer initializer = new DataInitializer(emf);
initializer.initializeData();
```

---

##  Gestion de la concurrence

L'optimistic locking est testé avec deux threads concurrents modifiant la même réservation. En cas de conflit, une `OptimisticLockException` est levée et la transaction est annulée.

```
Thread 1: version = 0 → commit réussi 
Thread 2: version = 0 → OptimisticLockException  → rollback
```

