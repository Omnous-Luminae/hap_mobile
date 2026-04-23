<?php
/**
 * get_bien_detail.php — Détail complet d'un bien (API Mobile HAP)
 *
 * Méthode : GET
 * Paramètre : ?id=<id_biens>
 *
 * Réponse :
 *   {
 *     "success": true,
 *     "bien": { ...info, "photos": [...], "avis": [...], "tarifs": [...] }
 *   }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
$pdo = getPDO();

$idBiens = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($idBiens <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètre id manquant ou invalide.']);
    exit;
}


// ── Infos principales du bien ──────────────────────────────────────────────
$stmtBien = $pdo->prepare("
    SELECT
        b.id_biens,
        b.nom_biens,
        b.rue_biens,
        b.superficie_biens,
        b.description_biens,
        b.animal_biens,
        b.nb_couchage,
        tb.designation_type_bien,
        c.nom_commune,
        c.cp_commune,
        CASE b.id_biens
            WHEN 1 THEN 48.855900
            WHEN 2 THEN 43.281900
            WHEN 3 THEN 45.764200
            WHEN 4 THEN 44.841000
            WHEN 5 THEN 43.694000
            WHEN 6 THEN 45.905000
            WHEN 7 THEN 43.269800
            WHEN 8 THEN 43.129800
            WHEN 9 THEN 43.602900
            WHEN 10 THEN 43.487500
            WHEN 11 THEN 48.578600
            WHEN 12 THEN 47.215800
            WHEN 13 THEN 43.611200
            WHEN 14 THEN 43.120200
            WHEN 15 THEN 45.874500
            ELSE c.latitude_commune
        END AS lat_commune,
        CASE b.id_biens
            WHEN 1 THEN 2.298200
            WHEN 2 THEN 5.360200
            WHEN 3 THEN 4.832000
            WHEN 4 THEN -0.575900
            WHEN 5 THEN 7.259500
            WHEN 6 THEN 6.137000
            WHEN 7 THEN 5.394000
            WHEN 8 THEN 5.958800
            WHEN 9 THEN 1.439800
            WHEN 10 THEN -1.552200
            WHEN 11 THEN 7.754700
            WHEN 12 THEN -1.548000
            WHEN 13 THEN 3.876700
            WHEN 14 THEN 5.932000
            WHEN 15 THEN 6.132400
            ELSE c.longitude_commune
        END AS long_commune,
        ROUND(AVG(r.rating), 1)     AS note_moyenne,
        COUNT(DISTINCT r.id_review) AS nb_avis
    FROM biens b
    LEFT JOIN type_bien tb ON tb.id_type_biens  = b.id_type_biens
    LEFT JOIN commune   c  ON c.id_commune       = b.id_commune
    LEFT JOIN reviews   r  ON r.id_biens         = b.id_biens AND r.validated = 1
    WHERE b.id_biens = :id AND b.validated = 1
    GROUP BY
        b.id_biens, b.nom_biens, b.rue_biens, b.superficie_biens,
        b.description_biens, b.animal_biens, b.nb_couchage,
        tb.designation_type_bien, c.nom_commune, c.cp_commune,
        c.latitude_commune, c.longitude_commune
");
$stmtBien->execute([':id' => $idBiens]);
$bien = $stmtBien->fetch(PDO::FETCH_ASSOC);

if (!$bien) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Bien introuvable.']);
    exit;
}

// ── Photos ─────────────────────────────────────────────────────────────────
$stmtPhotos = $pdo->prepare("
    SELECT id_photo, nom_photos, lien_photo
    FROM photos
    WHERE id_biens = :id
    ORDER BY id_photo ASC
");
$stmtPhotos->execute([':id' => $idBiens]);
$photos = $stmtPhotos->fetchAll(PDO::FETCH_ASSOC);

// ── Avis validés ───────────────────────────────────────────────────────────
$stmtAvis = $pdo->prepare("
    SELECT
        r.id_review,
        r.rating,
        r.content,
        r.created_at,
        CONCAT(l.prenom_locataire, ' ', LEFT(l.nom_locataire, 1), '.') AS auteur
    FROM reviews r
    LEFT JOIN locataire l ON l.id_locataire = r.id_locataire
    WHERE r.id_biens = :id AND r.validated = 1
    ORDER BY r.created_at DESC
    LIMIT 10
");
$stmtAvis->execute([':id' => $idBiens]);
$avis = $stmtAvis->fetchAll(PDO::FETCH_ASSOC);

// ── Tarifs (prochaines semaines) ───────────────────────────────────────────
$stmtTarifs = $pdo->prepare("
    SELECT
        t.id_Tarif,
        t.semaine_Tarif,
        t.année_Tarif   AS annee,
        t.tarif,
        s.lib_saison
    FROM tarif t
    JOIN saison s ON s.id_saison = t.id_saison
    WHERE t.id_biens = :id
      AND (t.année_Tarif > YEAR(NOW())
           OR (t.année_Tarif = YEAR(NOW()) AND t.semaine_Tarif >= WEEK(NOW(), 1)))
    ORDER BY t.année_Tarif ASC, t.semaine_Tarif ASC
");
$stmtTarifs->execute([':id' => $idBiens]);
$tarifs = $stmtTarifs->fetchAll(PDO::FETCH_ASSOC);

// ── Formatage ──────────────────────────────────────────────────────────────
$bien['note_moyenne']     = $bien['note_moyenne'] !== null ? (float) $bien['note_moyenne'] : null;
$bien['nb_avis']          = (int) $bien['nb_avis'];
$bien['superficie_biens'] = (float) $bien['superficie_biens'];
$bien['animal_biens']     = (int) $bien['animal_biens'];
$bien['nb_couchage']      = (int) $bien['nb_couchage'];
$bien['lat_commune']      = $bien['lat_commune'] !== null ? (float) $bien['lat_commune'] : null;
$bien['long_commune']     = $bien['long_commune'] !== null ? (float) $bien['long_commune'] : null;
$bien['photos']           = $photos;
$bien['avis']             = array_map(function ($a) {
    $a['rating'] = (int) $a['rating'];
    return $a;
}, $avis);
$bien['tarifs']           = array_map(function ($t) {
    $t['semaine_Tarif'] = (float) $t['semaine_Tarif'];
    $t['annee']         = (int)   $t['annee'];
    $t['tarif']         = (float) $t['tarif'];
    $t['id_Tarif']      = (int)   $t['id_Tarif'];
    return $t;
}, $tarifs);

echo json_encode(['success' => true, 'bien' => $bien]);
