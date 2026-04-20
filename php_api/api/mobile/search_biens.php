<?php

/**
 * search_biens.php — Autocomplétion des biens pour la recherche mobile
 *
 * Méthode : GET
 * Paramètre : q (texte de recherche)
 *
 * Réponse :
 *   { "success": true, "data": [ { id_biens, nom_biens, nom_commune, cp_commune, photo } ] }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
$pdo = getPDO();

$query = trim($_GET['q'] ?? '');
if ($query === '') {
    echo json_encode(['success' => true, 'data' => []]);
    exit;
}

try {
    $stmt = $pdo->prepare(
        "SELECT
            b.id_biens,
            b.nom_biens,
            c.nom_commune,
            c.cp_commune,
            (SELECT p.lien_photo FROM photos p WHERE p.id_biens = b.id_biens ORDER BY p.id_photo ASC LIMIT 1) AS photo
         FROM biens b
         LEFT JOIN commune c ON c.id_commune = b.id_commune
         WHERE b.validated = 1
           AND (b.is_hidden = 0 OR b.is_hidden IS NULL)
           AND (
                b.nom_biens LIKE :q
                OR c.nom_commune LIKE :q
                OR c.cp_commune LIKE :q
           )
         GROUP BY b.id_biens
         ORDER BY b.nom_biens ASC
         LIMIT 8"
    );
    $stmt->execute([':q' => '%' . $query . '%']);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $data = array_map(static function (array $row): array {
        return [
            'id_biens' => (int) $row['id_biens'],
            'nom_biens' => $row['nom_biens'],
            'nom_commune' => $row['nom_commune'],
            'cp_commune' => $row['cp_commune'],
            'photo' => $row['photo'],
        ];
    }, $rows);

    echo json_encode(['success' => true, 'data' => $data]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la recherche des biens.']);
}
