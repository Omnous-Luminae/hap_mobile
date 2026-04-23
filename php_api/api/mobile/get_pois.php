<?php
/**
 * get_pois.php — Récupération des points d'intérêt + événements (tables existantes)
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
$pdo = getPDO();

$latitude  = isset($_GET['latitude']) ? (float) $_GET['latitude'] : null;
$longitude = isset($_GET['longitude']) ? (float) $_GET['longitude'] : null;
$radius    = isset($_GET['radius']) ? (int) $_GET['radius'] : 2500;
$category  = isset($_GET['category']) ? trim($_GET['category']) : null;

$params = [];
$where = [];

if ($category !== null && $category !== '') {
    $where[] = 'x.categorie_poi LIKE ?';
    $params[] = '%' . $category . '%';
}

if ($latitude !== null && $longitude !== null) {
    $where[] = '(6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS((x.latitude - ?) / 2)), 2) + COS(RADIANS(?)) * COS(RADIANS(x.latitude)) * POWER(SIN(RADIANS((x.longitude - ?) / 2)), 2)))) <= ?';
    $params[] = $latitude;
    $params[] = $latitude;
    $params[] = $longitude;
    $params[] = ($radius / 1000);
}

$sql = "
SELECT *
FROM (
    SELECT
        p.id_pts_interet AS id_poi,
        p.lib_pts_interet AS nom_poi,
        p.description_pts_interet AS description,
        COALESCE(t.lib_type_points_interet, 'Point d''interet') AS categorie_poi,
        p.rue_pts_interet AS adresse,
        CASE p.id_pts_interet
            WHEN 1 THEN 48.858370
            WHEN 2 THEN 48.860611
            WHEN 3 THEN 43.296482
            WHEN 4 THEN 43.284020
            WHEN 5 THEN 45.784000
            WHEN 6 THEN 45.732600
            WHEN 7 THEN 43.604500
            WHEN 8 THEN 43.586500
            WHEN 9 THEN 43.695300
            WHEN 10 THEN 43.697700
            WHEN 11 THEN 43.483200
            WHEN 12 THEN 43.480800
            WHEN 13 THEN 45.899200
            WHEN 14 THEN 45.899200
            WHEN 15 THEN 48.581900
            ELSE c.latitude_commune
        END AS latitude,
        CASE p.id_pts_interet
            WHEN 1 THEN 2.294481
            WHEN 2 THEN 2.337644
            WHEN 3 THEN 5.369780
            WHEN 4 THEN 5.371000
            WHEN 5 THEN 4.852700
            WHEN 6 THEN 4.818400
            WHEN 7 THEN 1.444200
            WHEN 8 THEN 1.493400
            WHEN 9 THEN 7.265400
            WHEN 10 THEN 7.279500
            WHEN 11 THEN -1.558600
            WHEN 12 THEN -1.569600
            WHEN 13 THEN 6.129400
            WHEN 14 THEN 6.123600
            WHEN 15 THEN 7.750700
            ELSE c.longitude_commune
        END AS longitude,
        'poi' AS source_type
    FROM pts_interet p
    LEFT JOIN type_pts_interet t ON t.id_type_points_interet = p.id_type_points_interet
    LEFT JOIN commune c ON c.id_commune = p.id_commune

    UNION ALL

    SELECT
        (1000000 + e.id_evenement) AS id_poi,
        e.nom_evenement AS nom_poi,
        e.description_evenement AS description,
        CONCAT('Evenement - ', COALESCE(te.lib_type_evenement, 'General')) AS categorie_poi,
        NULL AS adresse,
        c.latitude_commune AS latitude,
        c.longitude_commune AS longitude,
        'event' AS source_type
    FROM evenement e
    LEFT JOIN type_evenement te ON te.id_type_evenement = e.id_type_evenement
    LEFT JOIN commune c ON c.id_commune = e.id_commune
) x
WHERE x.latitude IS NOT NULL
  AND x.longitude IS NOT NULL
";

if (!empty($where)) {
    $sql .= ' AND ' . implode(' AND ', $where);
}

$sql .= ' ORDER BY x.nom_poi ASC LIMIT 200';

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $photoStmt = $pdo->prepare('
        SELECT lien_photo_pts
        FROM photos_ptsinteret
        WHERE id_pts_interet = ?
        ORDER BY id_photo_pts ASC
    ');

    $data = array_map(function ($row) use ($photoStmt) {
        $id = (int) $row['id_poi'];
        $photos = [];

        // Les événements ont un offset 1000000, pas de photos dédiées.
        if (($row['source_type'] ?? '') === 'poi') {
            $photoStmt->execute([$id]);
            $photos = $photoStmt->fetchAll(PDO::FETCH_COLUMN) ?: [];
        }

        return [
            'id_poi' => $id,
            'nom_poi' => (string) $row['nom_poi'],
            'description' => $row['description'] !== null ? (string) $row['description'] : null,
            'categorie_poi' => (string) $row['categorie_poi'],
            'adresse' => $row['adresse'] !== null ? (string) $row['adresse'] : null,
            'latitude' => (float) $row['latitude'],
            'longitude' => (float) $row['longitude'],
            'photos' => $photos,
            'source_type' => (string) $row['source_type'],
        ];
    }, $rows);

    echo json_encode(['success' => true, 'data' => $data]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la recuperation des points d\'interet.',
    ]);
}
