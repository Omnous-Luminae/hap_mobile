<?php
/**
 * init_poi_tables.php — Initialisation des tables POI
 *
 * Crée les tables pour stocker les points d'intérêt avec photos et descriptions
 */

require_once __DIR__ . '/config/db.php';
$pdo = getPDO();

try {
    $sql1 = "CREATE TABLE IF NOT EXISTS points_of_interest (
        id_poi INT AUTO_INCREMENT PRIMARY KEY,
        nom_poi VARCHAR(255) NOT NULL,
        description TEXT,
        categorie_poi VARCHAR(50) NOT NULL,
        adresse VARCHAR(255),
        latitude DECIMAL(10, 8) NOT NULL,
        longitude DECIMAL(11, 8) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_categorie (categorie_poi),
        INDEX idx_lat_lon (latitude, longitude)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    $pdo->exec($sql1);
    echo "✓ Table points_of_interest créée.\n";
    
    $sql2 = "CREATE TABLE IF NOT EXISTS poi_photos (
        id_poi_photo INT AUTO_INCREMENT PRIMARY KEY,
        id_poi INT NOT NULL,
        lien_photo VARCHAR(255) NOT NULL,
        ordre INT DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_poi) REFERENCES points_of_interest(id_poi) ON DELETE CASCADE,
        INDEX idx_id_poi (id_poi)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    $pdo->exec($sql2);
    echo "✓ Table poi_photos créée.\n";
    
    // Insert sample POI data
    $samplePois = [
        ['restaurant', 'Pizzeria Mario', 'Excellente pizza authentique italienne', 'Rue de Paris 12', 48.8566, 2.3522],
        ['pharmacy', 'Pharmacie Centrale', 'Pharmacie 24h/24', 'Avenue des Champs', 48.8565, 2.3524],
        ['park', 'Jardin Public', 'Grand parc avec aires de jeux', 'Square du Port', 48.8560, 2.3520],
        ['museum', 'Musée Local', 'Découvrez l\'histoire de la région', 'Rue de la Culture 5', 48.8570, 2.3525],
    ];
    
    foreach ($samplePois as $poi) {
        $stmt = $pdo->prepare("
            INSERT IGNORE INTO points_of_interest
            (categorie_poi, nom_poi, description, adresse, latitude, longitude)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute($poi);
    }
    echo "✓ Données d'exemple insérées.\n";
    
} catch (Exception $e) {
    fprintf(STDERR, "✗ Erreur: %s\n", $e->getMessage());
    exit(1);
}

echo "\n✓ Initialisation complétée avec succès.\n";
