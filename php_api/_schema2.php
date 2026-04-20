<?php
require_once __DIR__ . '/config/db.php';
$pdo = new PDO('mysql:host='.DB_HOST.';dbname='.DB_NAME.';charset=utf8', DB_USER, DB_PASS);
$rows = $pdo->query("SELECT id_biens, COUNT(*) as nb FROM photos GROUP BY id_biens ORDER BY nb DESC LIMIT 10")->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($rows);

// Also check reviews
$reviews = $pdo->query("SELECT * FROM reviews LIMIT 3")->fetchAll(PDO::FETCH_ASSOC);
echo "\n" . json_encode($reviews);

// Check reservations for bien 1
$res = $pdo->query("SELECT * FROM reservation WHERE id_biens = 1")->fetchAll(PDO::FETCH_ASSOC);
echo "\nReservations for bien 1: " . json_encode($res);

// Tarifs for bien 1
$tarifs = $pdo->query("SELECT t.*, s.lib_saison FROM tarif t JOIN saison s ON s.id_saison = t.id_saison WHERE t.id_biens = 1 ORDER BY t.semaine_Tarif LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
echo "\nTarifs bien 1: " . json_encode($tarifs);
