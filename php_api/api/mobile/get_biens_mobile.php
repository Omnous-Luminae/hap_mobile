<?php
/**
 * get_biens_mobile.php — Liste paginée et filtrée des biens (API Mobile HAP)
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/api/mobile/get_biens_mobile.php
 *
 * Méthode : GET
 *
 * Paramètres (tous optionnels) :
 *   ?commune_id=       → filtre sur id_commune
 *   ?type_bien=        → filtre sur id_type_biens
 *   ?nb_couchage_min=  → nb_couchage >= valeur
 *   ?nb_couchage_max=  → nb_couchage <= valeur
 *   ?superficie_min=   → superficie_biens >= valeur
 *   ?superficie_max=   → superficie_biens <= valeur
 *   ?animaux=          → 0 ou 1 (animal_biens)
 *   ?prix_min=         → tarif moyen >= valeur
 *   ?prix_max=         → tarif moyen <= valeur
 *   ?note_min=         → note moyenne Reviews.rating >= valeur
 *   ?search=           → LIKE sur nom_biens
 *   ?sort=             → prix_asc | prix_desc | note_desc (défaut) | recents
 *   ?page=             → page courante (défaut 1)
 *   ?per_page=         → résultats par page (défaut 10, max 50)
 *
 * Réponse JSON :
 *   { "success": true, "data": [...], "total": N, "page": P, "per_page": PP, "total_pages": T }
 */

// ── En-têtes CORS + JSON ───────────────────────────────────────────────────
require_once __DIR__ . '/../../config/cors.php'; // NOSONAR - API procédurale sans autoloader
hapApplyCors(['GET', 'OPTIONS']);

// ── Chargement de la configuration BDD ────────────────────────────────────
require_once __DIR__ . '/../../config/db.php'; // NOSONAR - API procédurale sans autoloader
$pdo = getPDO();

// ── Lecture et nettoyage des paramètres GET ────────────────────────────────
$communeId    = isset($_GET['commune_id'])      ? (int) $_GET['commune_id']      : null;
$typeBien     = isset($_GET['type_bien'])        ? (int) $_GET['type_bien']        : null;
$couchageMin  = isset($_GET['nb_couchage_min']) ? (int) $_GET['nb_couchage_min'] : null;
$couchageMax  = isset($_GET['nb_couchage_max']) ? (int) $_GET['nb_couchage_max'] : null;
$superfMin    = isset($_GET['superficie_min'])   ? (float) $_GET['superficie_min']  : null;
$superfMax    = isset($_GET['superficie_max'])   ? (float) $_GET['superficie_max']  : null;
$animaux      = isset($_GET['animaux'])          ? (int) $_GET['animaux']           : null;
$prixMin      = isset($_GET['prix_min'])         ? (float) $_GET['prix_min']         : null;
$prixMax      = isset($_GET['prix_max'])         ? (float) $_GET['prix_max']         : null;
$noteMin      = isset($_GET['note_min'])         ? (float) $_GET['note_min']         : null;
$search       = isset($_GET['search'])           ? trim($_GET['search'])             : null;
$sort         = $_GET['sort']    ?? 'note_desc';
$page         = max(1, (int) ($_GET['page']     ?? 1));
$perPage      = min(50, max(1, (int) ($_GET['per_page'] ?? 10)));
$offset       = ($page - 1) * $perPage;


// ── Construction de la requête dynamique ───────────────────────────────────
$where  = ['b.validated = 1', '(b.is_hidden = 0 OR b.is_hidden IS NULL)'];
$params = [];

if ($communeId !== null) {
    $where[]            = 'b.id_commune = :commune_id';
    $params[':commune_id'] = $communeId;
}

if ($typeBien !== null) {
    $where[]            = 'b.id_type_biens = :type_bien';
    $params[':type_bien'] = $typeBien;
}

if ($couchageMin !== null) {
    $where[]               = 'b.nb_couchage >= :couchage_min';
    $params[':couchage_min'] = $couchageMin;
}

if ($couchageMax !== null) {
    $where[]               = 'b.nb_couchage <= :couchage_max';
    $params[':couchage_max'] = $couchageMax;
}

if ($superfMin !== null) {
    $where[]              = 'b.superficie_biens >= :superf_min';
    $params[':superf_min'] = $superfMin;
}

if ($superfMax !== null) {
    $where[]              = 'b.superficie_biens <= :superf_max';
    $params[':superf_max'] = $superfMax;
}

if ($animaux !== null) {
    $where[]          = 'b.animal_biens = :animaux';
    $params[':animaux'] = $animaux;
}

if ($search !== null && $search !== '') {
    $where[]          = 'b.nom_biens LIKE :search';
    $params[':search'] = '%' . $search . '%';
}

$whereClause = 'WHERE ' . implode(' AND ', $where);

// ── Clause HAVING pour les filtres sur agrégats ────────────────────────────
$having       = [];
$havingParams = [];

if ($prixMin !== null) {
    $having[]            = 'tarif_semaine >= :prix_min';
    $havingParams[':prix_min'] = $prixMin;
}

if ($prixMax !== null) {
    $having[]            = 'tarif_semaine <= :prix_max';
    $havingParams[':prix_max'] = $prixMax;
}

if ($noteMin !== null) {
    $having[]            = 'note_moyenne >= :note_min';
    $havingParams[':note_min'] = $noteMin;
}

$havingClause = !empty($having) ? 'HAVING ' . implode(' AND ', $having) : '';

// ── Tri ────────────────────────────────────────────────────────────────────
// Note: aggregate aliases (note_moyenne) cannot be wrapped in functions in ORDER BY in MySQL.
// Use the alias directly; NULLs sort last in DESC naturally.
$orderBy = match ($sort) {
    'prix_asc'  => 'ORDER BY tarif_semaine ASC',
    'prix_desc' => 'ORDER BY tarif_semaine DESC',
    'recents'   => 'ORDER BY b.id_biens DESC',
    default     => 'ORDER BY note_moyenne DESC',
};

// ── Sous-requête commune (SELECT principal) ────────────────────────────────
$selectSql = "
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
        (SELECT p.lien_photo
           FROM Photos p
          WHERE p.id_biens = b.id_biens
          LIMIT 1) AS photo,
        ROUND(AVG(r.rating), 1)  AS note_moyenne,
        COUNT(DISTINCT r.id_review) AS nb_avis,
        COALESCE(
            (SELECT AVG(t.tarif)
               FROM Tarif t
              WHERE t.id_biens = b.id_biens
              LIMIT 1),
            0
        ) AS tarif_semaine
    FROM   Biens b
    LEFT JOIN Type_Bien tb ON tb.id_type_biens = b.id_type_biens
    LEFT JOIN Commune   c  ON c.id_commune     = b.id_commune
    LEFT JOIN Reviews   r  ON r.id_biens       = b.id_biens AND r.validated = 1
    $whereClause
    GROUP BY
        b.id_biens, b.nom_biens, b.rue_biens, b.superficie_biens,
        b.description_biens, b.animal_biens, b.nb_couchage,
        tb.designation_type_bien, c.nom_commune, c.cp_commune,
        c.latitude_commune, c.longitude_commune
    $havingClause
";

// ── Comptage total ─────────────────────────────────────────────────────────
try {
    $countSql  = "SELECT COUNT(*) FROM ($selectSql) AS sub";
    $stmtCount = $pdo->prepare($countSql);
    $stmtCount->execute(array_merge($params, $havingParams));
    $total = (int) $stmtCount->fetchColumn();
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors du comptage des biens.']);
    exit;
}

// ── Requête paginée ────────────────────────────────────────────────────────
try {
    $dataSql  = "$selectSql $orderBy LIMIT :limit OFFSET :offset";
    $stmtData = $pdo->prepare($dataSql);

    foreach (array_merge($params, $havingParams) as $key => $value) {
        $stmtData->bindValue($key, $value);
    }
    $stmtData->bindValue(':limit',  $perPage, PDO::PARAM_INT);
    $stmtData->bindValue(':offset', $offset,  PDO::PARAM_INT);
    $stmtData->execute();
    $rows = $stmtData->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la récupération des biens.']);
    exit;
}

// ── Formatage de la réponse ────────────────────────────────────────────────
$data = array_map(function (array $row): array {
    return [
        'id_biens'             => (int) $row['id_biens'],
        'nom_biens'            => $row['nom_biens'],
        'rue_biens'            => $row['rue_biens'],
        'superficie_biens'     => (float) $row['superficie_biens'],
        'description_biens'    => $row['description_biens'],
        'animal_biens'         => (int) $row['animal_biens'],
        'nb_couchage'          => (int) $row['nb_couchage'],
        'designation_type_bien'=> $row['designation_type_bien'],
        'nom_commune'          => $row['nom_commune'],
        'cp_commune'           => $row['cp_commune'],
        'lat_commune'          => $row['lat_commune'] !== null ? (float) $row['lat_commune'] : null,
        'long_commune'         => $row['long_commune'] !== null ? (float) $row['long_commune'] : null,
        'photo'                => $row['photo'],
        'note_moyenne'         => $row['note_moyenne'] !== null ? (float) $row['note_moyenne'] : null,
        'nb_avis'              => (int) $row['nb_avis'],
        'tarif_semaine'        => (float) $row['tarif_semaine'],
    ];
}, $rows);

echo json_encode([
    'success'     => true,
    'data'        => $data,
    'total'       => $total,
    'page'        => $page,
    'per_page'    => $perPage,
    'total_pages' => $perPage > 0 ? (int) ceil($total / $perPage) : 0,
]);
