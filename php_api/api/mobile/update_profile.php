<?php
/**
 * update_profile.php — Mise à jour du profil locataire connecté (API Mobile HAP)
 *
 * Méthode : POST (JSON body)
 * Header  : Authorization: Bearer <token>
 *
 * Body (champs optionnels) :
 *   {
 *     "prenom": "...",
 *     "nom": "...",
 *     "telephone": "...",
 *     "date_naissance": "YYYY-MM-DD",
 *     "rue": "...",
 *     "complement": "...",
 *     "id_commune": <int|null>
 *   }
 *
 * Réponse succès :
 *   { "success": true, "user": { ...profil actualisé... } }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['POST', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../config/jwt_config.php';
require_once __DIR__ . '/../../classes/JWTHelper.php';
$pdo = getPDO();

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

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Corps JSON invalide.']);
    exit;
}

$prenom = isset($input['prenom']) ? trim((string) $input['prenom']) : null;
$nom = isset($input['nom']) ? trim((string) $input['nom']) : null;
$telephone = array_key_exists('telephone', $input) ? trim((string) $input['telephone']) : null;
$dateNaissance = array_key_exists('date_naissance', $input) ? trim((string) $input['date_naissance']) : null;
$rue = array_key_exists('rue', $input) ? trim((string) $input['rue']) : null;
$complement = array_key_exists('complement', $input) ? trim((string) $input['complement']) : null;
$idCommune = array_key_exists('id_commune', $input) ? (int) $input['id_commune'] : null;

if ($prenom !== null && $prenom === '') {
    $prenom = null;
}
if ($nom !== null && $nom === '') {
    $nom = null;
}
if ($telephone !== null && $telephone === '') {
    $telephone = null;
}
if ($dateNaissance !== null && $dateNaissance === '') {
    $dateNaissance = null;
}
if ($rue !== null && $rue === '') {
    $rue = null;
}
if ($complement !== null && $complement === '') {
    $complement = null;
}
if ($idCommune !== null && $idCommune <= 0) {
    $idCommune = null;
}

if ($dateNaissance !== null && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateNaissance)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Format de date invalide (YYYY-MM-DD attendu).']);
    exit;
}

$fields = [];
$params = [':id' => $idLocataire];

if ($prenom !== null) {
    $fields[] = 'prenom_locataire = :prenom';
    $params[':prenom'] = $prenom;
}
if ($nom !== null) {
    $fields[] = 'nom_locataire = :nom';
    $params[':nom'] = $nom;
}
if ($telephone !== null) {
    $fields[] = 'telephone_locataire = :telephone';
    $params[':telephone'] = $telephone;
}
if ($dateNaissance !== null) {
    $fields[] = 'date_naissance = :date_naissance';
    $params[':date_naissance'] = $dateNaissance;
}
if ($rue !== null) {
    $fields[] = 'rue_locataire = :rue';
    $params[':rue'] = $rue;
}
if ($complement !== null) {
    $fields[] = 'complement_locataire = :complement';
    $params[':complement'] = $complement;
}
if (array_key_exists('id_commune', $input)) {
    $fields[] = 'id_commune = :id_commune';
    $params[':id_commune'] = $idCommune ?: null;
}

if (empty($fields)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Aucune modification à appliquer.']);
    exit;
}

try {
    $sql = 'UPDATE Locataire SET ' . implode(', ', $fields) . ' WHERE id_locataire = :id';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $stmtUser = $pdo->prepare(
        'SELECT l.id_locataire,
                l.nom_locataire,
                l.prenom_locataire,
                l.email_locataire,
                l.telephone_locataire,
                l.date_naissance,
                l.rue_locataire,
                l.complement_locataire,
                l.id_commune,
                c.nom_commune,
                c.cp_commune
         FROM Locataire l
         LEFT JOIN Commune c ON c.id_commune = l.id_commune
         WHERE l.id_locataire = :id
         LIMIT 1'
    );
    $stmtUser->execute([':id' => $idLocataire]);
    $locataire = $stmtUser->fetch(PDO::FETCH_ASSOC);

    if (!$locataire) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Compte introuvable.']);
        exit;
    }

    echo json_encode([
        'success' => true,
        'user' => [
            'id' => (int) $locataire['id_locataire'],
            'nom' => $locataire['nom_locataire'],
            'prenom' => $locataire['prenom_locataire'],
            'email' => $locataire['email_locataire'],
            'telephone' => $locataire['telephone_locataire'],
            'date_naissance' => $locataire['date_naissance'],
            'rue' => $locataire['rue_locataire'],
            'complement' => $locataire['complement_locataire'],
            'id_commune' => $locataire['id_commune'] !== null ? (int) $locataire['id_commune'] : null,
            'nom_commune' => $locataire['nom_commune'],
            'cp_commune' => $locataire['cp_commune'],
        ],
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour du profil.']);
}
