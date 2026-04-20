<?php
require_once __DIR__ . '/config/db.php';
$pdo = new PDO('mysql:host='.DB_HOST.';dbname='.DB_NAME.';charset=utf8', DB_USER, DB_PASS, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

foreach (['reservation', 'semaine_indisponible', 'tarif', 'saison', 'biens', 'photos'] as $t) {
    $allowed = ['reservation', 'semaine_indisponible', 'tarif', 'saison', 'biens', 'photos'];
    if (!in_array($t, $allowed, true)) {
        continue;
    }

    $cols = $pdo->query(sprintf('DESCRIBE `%s`', $t))->fetchAll(PDO::FETCH_ASSOC);
    echo "\n=== $t ===\n";
    foreach ($cols as $c) {
        echo "  {$c['Field']} {$c['Type']} {$c['Null']} {$c['Key']} default={$c['Default']}\n";
    }
}

// Sample data
echo "\n=== Reservations (3) ===\n";
echo json_encode($pdo->query("SELECT * FROM reservation LIMIT 3")->fetchAll(PDO::FETCH_ASSOC), JSON_PRETTY_PRINT) . "\n";

echo "\n=== semaine_indisponible (5) ===\n";
echo json_encode($pdo->query("SELECT * FROM semaine_indisponible LIMIT 5")->fetchAll(PDO::FETCH_ASSOC), JSON_PRETTY_PRINT) . "\n";

echo "\n=== Photos (3) ===\n";
echo json_encode($pdo->query("SELECT * FROM photos LIMIT 3")->fetchAll(PDO::FETCH_ASSOC), JSON_PRETTY_PRINT) . "\n";

echo "\n=== Tarif (3) ===\n";
echo json_encode($pdo->query("SELECT * FROM tarif LIMIT 3")->fetchAll(PDO::FETCH_ASSOC), JSON_PRETTY_PRINT) . "\n";

echo "\n=== Saison (all) ===\n";
echo json_encode($pdo->query("SELECT * FROM saison")->fetchAll(PDO::FETCH_ASSOC), JSON_PRETTY_PRINT) . "\n";
