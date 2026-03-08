package com.example.util;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.util.stream.Collectors;

public class DatabaseMigrationTool {

    private final String jdbcUrl;
    private final String username;
    private final String password;

    public DatabaseMigrationTool(String jdbcUrl, String username, String password) {
        this.jdbcUrl = jdbcUrl;
        this.username = username;
        this.password = password;
    }

    public void executeMigration() {
        System.out.println("Démarrage de la migration de la base de données...");

        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password)) {
            // Charger le script SQL depuis les ressources
            InputStream inputStream = getClass().getClassLoader().getResourceAsStream("db/migration/migration_v2.sql");

            if (inputStream == null) {
                throw new RuntimeException("Script de migration non trouvé dans les ressources");
            }

            String migrationScript = new BufferedReader(new InputStreamReader(inputStream))
                    .lines().collect(Collectors.joining("\n"));

            // Diviser le script en instructions individuelles
            String[] instructions = migrationScript.split(";");

            // Exécuter chaque instruction
            try (Statement statement = connection.createStatement()) {
                for (String instruction : instructions) {
                    if (!instruction.trim().isEmpty()) {
                        System.out.println("Exécution: " + instruction.trim());
                        statement.execute(instruction);
                    }
                }
            }

            System.out.println("Migration terminée avec succès !");

        } catch (Exception e) {
            System.err.println("Erreur lors de la migration: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        // Exemple d'utilisation
        DatabaseMigrationTool migrationTool = new DatabaseMigrationTool(
                "jdbc:mysql://localhost:3306/reservation_salles",
                "root",
                "password"
        );

        migrationTool.executeMigration();
    }
}