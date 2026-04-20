<?php
/**
 * favoris.php — Gestion des favoris (API Mobile HAP)
 *
 * Méthodes :
 *   GET    → Liste les favoris de l'utilisateur connecté
 *   POST   → Ajoute un bien aux favoris  { "id_biens": <int> }
 *   DELETE → Retire un bien des favoris  { "id_biens": <int> }
 *
 * Headers : Authorization: Bearer <token>
 *
 * Réponse GET :
 *   { "success": true, "data": [ { id_biens, nom_biens, nom_commune,
 *     cp_commune, photo, note_moyenne, nb_avis, tarif_semaine } ] }
 *
 * Réponse POST / DELETE :
 *   { "success": true, "message": "..." }
 *
 * Prérequis SQL :
 *   CREATE TABLE IF NOT EXISTS favoris (
 *     id_favori    INT AUTO_INCREMENT PRIMARY KEY,
 *     id_locataire INT NOT NULL,
 *     id_biens     INT NOT NULL,
 *     created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
 *     UNIQUE KEY uq_favori (id_locataire, id_biens),
 *     FOREIGN KEY (id_locataire) REFERENCES locataire(id_locataire),
 *     FOREIGN KEY (id_biens)     REFERENCES biens(id_biens)
 *   );
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'POST', 'DELETE', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../config/jwt_config.php';
require_once __DIR__ . '/../../classes/JWTHelper.php';
use JWTHelper as JWT;
$pdo = getPDO();

// ── Auth JWT ───────────────────────────────────────────────────────────────
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (empty($authHeader) && function_exists('apache_request_headers')) {
    $h = apache_request_headers();
    $authHeader = $h['Authorization'] ?? '';
}

if (empty($authHeader) || !preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token manquant ou mal formé.']);
    exit;
}

$payload = JWT::decode($m[1], JWT_SECRET);
if ($payload === false) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token invalide ou expiré.']);
    exit;
}

$idLocataire = (int) ($payload['id_locataire'] ?? 0);
if ($idLocataire <= 0) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token corrompu.']);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// ══════════════════════════════════════════════════════════════════════════════
// GET — Liste des favoris
// ══════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $stmt = $pdo->prepare("
        SELECT
            b.id_biens,
            b.nom_biens,
            c.nom_commune,
            c.cp_commune,
            ROUND(AVG(r.rating), 1)        AS note_moyenne,
            COUNT(DISTINCT r.id_review)    AS nb_avis,
            COALESCE(
                (SELECT AVG(t.tarif) FROM tarif t WHERE t.id_biens = b.id_biens LIMIT 1),
                0
            ) AS tarif_semaine,
            (SELECT p.lien_photo FROM photos p WHERE p.id_biens = b.id_biens LIMIT 1) AS photo
        FROM favoris f
        JOIN biens     b ON b.id_biens   = f.id_biens
        LEFT JOIN commune  c ON c.id_commune = b.id_commune
        LEFT JOIN reviews  r ON r.id_biens   = b.id_biens AND r.validated = 1
        WHERE f.id_locataire = :id
          AND b.validated = 1
        GROUP BY b.id_biens, b.nom_biens, c.nom_commune, c.cp_commune
        ORDER BY f.id_favori DESC
    ");
    $stmt->execute([':id' => $idLocataire]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $data = array_map(function ($row) {
        return [
            'id_biens'      => (int)   $row['id_biens'],
            'nom_biens'     =>         $row['nom_biens'],
            'nom_commune'   =>         $row['nom_commune'],
            'cp_commune'    =>         $row['cp_commune'],
            'note_moyenne'  => $row['note_moyenne'] !== null ? (float) $row['note_moyenne'] : null,
            'nb_avis'       => (int)   $row['nb_avis'],
            'tarif_semaine' => (float) $row['tarif_semaine'],
            'photo'         =>         $row['photo'],
        ];
    }, $rows);

    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

// ══════════════════════════════════════════════════════════════════════════════
// POST — Ajout aux favoris
// ══════════════════════════════════════════════════════════════════════════════
if ($method === 'POST') {
    $input   = json_decode(file_get_contents('php://input'), true);
    $idBiens = isset($input['id_biens']) ? (int) $input['id_biens'] : 0;

    if ($idBiens <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Paramètre id_biens requis.']);
        exit;
    }

    // Vérifie que le bien existe
    $chk = $pdo->prepare("SELECT id_biens FROM biens WHERE id_biens = :id AND validated = 1");
    $chk->execute([':id' => $idBiens]);
    if (!$chk->fetch()) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Bien introuvable.']);
        exit;
    }

    try {
        // INSERT IGNORE évite l'erreur si le favori existe déjà (contrainte UNIQUE)
        $ins = $pdo->prepare("
            INSERT IGNORE INTO favoris (id_locataire, id_biens)
            VALUES (:locataire, :biens)
        ");
        $ins->execute([':locataire' => $idLocataire, ':biens' => $idBiens]);
        echo json_encode(['success' => true, 'message' => 'Ajouté aux favoris.']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'ajout.']);
    }
    exit;
}

// ══════════════════════════════════════════════════════════════════════════════
// DELETE — Suppression des favoris
// ══════════════════════════════════════════════════════════════════════════════
if ($method === 'DELETE') {
    $input   = json_decode(file_get_contents('php://input'), true);
    $idBiens = isset($input['id_biens']) ? (int) $input['id_biens'] : 0;

    if ($idBiens <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Paramètre id_biens requis.']);
        exit;
    }

    try {
        $del = $pdo->prepare("
            DELETE FROM favoris
            WHERE id_locataire = :locataire AND id_biens = :biens
        ");
        $del->execute([':locataire' => $idLocataire, ':biens' => $idBiens]);
        echo json_encode(['success' => true, 'message' => 'Retiré des favoris.']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression.']);
    }
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
