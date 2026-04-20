<?php
/**
 * cancel_reservation.php — Annulation d'une réservation (API Mobile HAP)
 *
 * Méthode : POST (JSON body)
 * Headers : Authorization: Bearer <token>
 *
 * Body :
 *   { "id_reservation": <int> }
 *
 * Règles :
 *   - Seules les réservations avec statut "a_venir" peuvent être annulées
 *   - La réservation doit appartenir à l'utilisateur connecté
 *
 * Réponse succès :
 *   { "success": true, "message": "Réservation annulée." }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['POST', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../config/jwt_config.php';
require_once __DIR__ . '/../../classes/JWTHelper.php';
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

$payload = \JWTHelper::decode($m[1], JWT_SECRET);
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

// ── Lecture du body JSON ───────────────────────────────────────────────────
$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Corps JSON invalide.']);
    exit;
}

$idReservation = isset($input['id_reservation']) ? (int) $input['id_reservation'] : 0;
if ($idReservation <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètre id_reservation requis.']);
    exit;
}

// ── Vérification que la réservation existe, appartient à l'utilisateur ─────
$stmt = $pdo->prepare("
    SELECT id_reservation, date_debut_reservation
    FROM reservation
    WHERE id_reservation = :id
      AND id_locataire   = :locataire
");
$stmt->execute([':id' => $idReservation, ':locataire' => $idLocataire]);
$reservation = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$reservation) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Réservation introuvable.']);
    exit;
}

// ── Vérification que la réservation est bien "à venir" ────────────────────
$dateDebut = new DateTime($reservation['date_debut_reservation']);
$today     = new DateTime('today');

if ($dateDebut <= $today) {
    http_response_code(409);
    echo json_encode([
        'success' => false,
        'message' => 'Seules les réservations à venir peuvent être annulées.',
    ]);
    exit;
}

// ── Suppression ────────────────────────────────────────────────────────────
try {
    $stmtDel = $pdo->prepare("
        DELETE FROM reservation
        WHERE id_reservation = :id AND id_locataire = :locataire
    ");
    $stmtDel->execute([':id' => $idReservation, ':locataire' => $idLocataire]);

    echo json_encode(['success' => true, 'message' => 'Réservation annulée.']);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'annulation.']);
}
