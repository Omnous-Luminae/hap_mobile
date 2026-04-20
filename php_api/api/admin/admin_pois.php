<?php
/**
 * admin_pois.php — Gestion administrative des points d'intérêt
 *
 * Méthodes :
 *   GET    → Récupère tous les POI
 *   POST   → Crée un nouveau POI
 *   PUT    → Modifie un POI
 *   DELETE → Supprime un POI
 *
 * Headers : Authorization: Bearer <token_admin>
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
$pdo = getPDO();
const RAW_INPUT_STREAM = 'php://input';

$method = $_SERVER['REQUEST_METHOD'];

// ═══════════════════════════════════════════════════════════════════════════════
// GET — Récupère tous les POI
// ═══════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    try {
        $stmt = $pdo->prepare("
            SELECT id_poi, nom_poi, description, categorie_poi, adresse,
                   latitude, longitude, created_at, updated_at
            FROM points_of_interest
            ORDER BY nom_poi ASC
        ");
        $stmt->execute();
        $pois = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $data = array_map(function ($poi) use ($pdo) {
            $poi['id_poi'] = (int) $poi['id_poi'];
            $poi['latitude'] = (float) $poi['latitude'];
            $poi['longitude'] = (float) $poi['longitude'];
            
            $photoStmt = $pdo->prepare("
                SELECT lien_photo FROM poi_photos
                WHERE id_poi = ?
                ORDER BY ordre ASC
            ");
            $photoStmt->execute([$poi['id_poi']]);
            $photos = $photoStmt->fetchAll(PDO::FETCH_COLUMN);
            $poi['photos'] = $photos ?: [];
            
            return $poi;
        }, $pois);
        
        echo json_encode(['success' => true, 'data' => $data]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur récupération POI']);
    }
    exit;
}

// ═══════════════════════════════════════════════════════════════════════════════
// POST — Crée un nouveau POI
// ═══════════════════════════════════════════════════════════════════════════════
if ($method === 'POST') {
    $input = json_decode(file_get_contents(RAW_INPUT_STREAM), true);
    
    $nom = trim($input['nom_poi'] ?? '');
    $description = trim($input['description'] ?? '');
    $categorie = trim($input['categorie_poi'] ?? '');
    $adresse = trim($input['adresse'] ?? '');
    $latitude = (float) ($input['latitude'] ?? 0);
    $longitude = (float) ($input['longitude'] ?? 0);
    $photos = (array) ($input['photos'] ?? []);
    
    if (empty($nom) || empty($categorie) || $latitude == 0 || $longitude == 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Paramètres manquants']);
        exit;
    }
    
    try {
        $stmt = $pdo->prepare("
            INSERT INTO points_of_interest
            (nom_poi, description, categorie_poi, adresse, latitude, longitude)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([$nom, $description, $categorie, $adresse, $latitude, $longitude]);
        $poiId = (int) $pdo->lastInsertId();
        
        // Ajoute les photos
        if (!empty($photos)) {
            $photoStmt = $pdo->prepare("
                INSERT INTO poi_photos (id_poi, lien_photo, ordre)
                VALUES (?, ?, ?)
            ");
            foreach ($photos as $i => $photo) {
                $photoStmt->execute([$poiId, trim($photo), $i]);
            }
        }
        
        echo json_encode(['success' => true, 'id_poi' => $poiId, 'message' => 'POI créé']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur création POI']);
    }
    exit;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PUT — Modifie un POI
// ═══════════════════════════════════════════════════════════════════════════════
if ($method === 'PUT') {
    $input = json_decode(file_get_contents(RAW_INPUT_STREAM), true);
    $poiId = (int) ($input['id_poi'] ?? 0);
    
    if ($poiId <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID POI manquant']);
        exit;
    }
    
    try {
        $updated = false;
        
        if (isset($input['nom_poi'])) {
            $stmt = $pdo->prepare("UPDATE points_of_interest SET nom_poi = ? WHERE id_poi = ?");
            $stmt->execute([trim($input['nom_poi']), $poiId]);
            $updated = true;
        }
        
        if (isset($input['description'])) {
            $stmt = $pdo->prepare("UPDATE points_of_interest SET description = ? WHERE id_poi = ?");
            $stmt->execute([trim($input['description']), $poiId]);
            $updated = true;
        }
        
        if (isset($input['adresse'])) {
            $stmt = $pdo->prepare("UPDATE points_of_interest SET adresse = ? WHERE id_poi = ?");
            $stmt->execute([trim($input['adresse']), $poiId]);
            $updated = true;
        }
        
        if ($updated) {
            echo json_encode(['success' => true, 'message' => 'POI modifié']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Aucune modification']);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur modification POI']);
    }
    exit;
}

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE — Supprime un POI
// ═══════════════════════════════════════════════════════════════════════════════
if ($method === 'DELETE') {
    $input = json_decode(file_get_contents(RAW_INPUT_STREAM), true);
    $poiId = (int) ($input['id_poi'] ?? 0);
    
    if ($poiId <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ID POI manquant']);
        exit;
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM points_of_interest WHERE id_poi = ?");
        $stmt->execute([$poiId]);
        echo json_encode(['success' => true, 'message' => 'POI supprimé']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur suppression POI']);
    }
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
