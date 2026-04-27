# Points d'Intérêt (POI) - Implémentation Complète

## Vue d'Ensemble
L'app mobile HAP dispose maintenant d'un système complet de gestion des points d'intérêt avec :
- **📍 Récupération depuis la base de données** avec photos et descriptions
- **🗺️ Marqueurs distinctifs** par catégorie sur la carte
- **🎨 Couleurs différentes** selon le type de POI (restaurant, pharmacie, parc, etc.)
- **📸 Galerie de photos** pour chaque POI
- **🔄 API mobile** de consultation des points d'intérêt

---

## Architecture

### 1. Base de Données

#### Table `points_of_interest`
```sql
CREATE TABLE points_of_interest (
    id_poi INT AUTO_INCREMENT PRIMARY KEY,
    nom_poi VARCHAR(255) NOT NULL,
    description TEXT,
    categorie_poi VARCHAR(50) NOT NULL,
    adresse VARCHAR(255),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_categorie (categorie_poi),
    INDEX idx_lat_lon (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
```

#### Table `poi_photos`
```sql
CREATE TABLE poi_photos (
    id_poi_photo INT AUTO_INCREMENT PRIMARY KEY,
    id_poi INT NOT NULL,
    lien_photo VARCHAR(255) NOT NULL,
    ordre INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_poi) REFERENCES points_of_interest(id_poi) ON DELETE CASCADE,
    INDEX idx_id_poi (id_poi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
```

---

### 2. API Endpoints

#### GET `/api/mobile/get_pois.php` - Récupérer les POI
**Paramètres** :
- `latitude` (float) : latitude centrale
- `longitude` (float) : longitude centrale  
- `radius` (int) : rayon en mètres (défaut : 2500)
- `category` (string) : filtrer par catégorie

**Réponse** :
```json
{
  "success": true,
  "data": [
    {
      "id_poi": 1,
      "nom_poi": "Pizzeria Mario",
      "description": "Excellente pizza authentique italienne",
      "categorie_poi": "restaurant",
      "adresse": "Rue de Paris 12",
      "latitude": 48.8566,
      "longitude": 2.3522,
      "photos": ["url1.jpg", "url2.jpg"]
    }
  ]
}
```

---

### 3. Modèle Dart

#### `PointOfInterest` Class
```dart
class PointOfInterest {
  final int id;
  final String name;
  final String category;
  final String? description;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> photos;
  
  // ... fromJson/toJson methods
}
```

**Catégories supportées** :
- 🍽️ restaurant, cafe
- 🏥 pharmacie, hospital
- 🌳 parc, leisure
- 🏛️ musée, museum, attraction
- 🏨 hotel
- 🛍️ shopping, commerce
- 🅿️ parking, station
- 💰 banque

---

### 4. Service Flutter

#### `PoiService` Class
```dart
class PoiService {
  // Récupère les POI proches avec couleurs par catégorie
  static Future<List<PointOfInterest>> fetchNearbyPois(
    LatLng center, {
    int radiusMeters = 2500,
  }) async { ... }
}
```

**Couleurs des catégories** :
- Restaurant/Café : 🔴 Rouge (#e74c3c)
- Pharmacie/Hôpital : 🟢 Vert (#27ae60)
- Parc/Loisir : 🟦 Turquoise (#16a085)
- Musée/Attraction : 🟠 Orange (#f39c12)
- Hôtel : 🟣 Violet (#8e44ad)
- Shopping/Commerce : 🟠 Orange clair (#e67e22)
- Parking/Station : 🟦 Gris-bleu (#34495e)
- Banque : 🔵 Bleu (#2980b9)

---

### 5. Écran Map Amélioré

#### Fonctionnalités
- **Afficher/Masquer POI** : Bouton FAB pour basculer la couche POI
- **Marqueurs distinctifs** : Icônes et couleurs selon catégorie
- **Détails au tap** : Fiche détaillée avec photos et description
- **Galerieode photos** : Défilement horizontal des images
- **Adresse affichée** : Localisation complète du POI

#### SheetModale (Bottom Sheet)
```
┌─────────────────────────────┐
│ Photo principale            │
│ ┌───────────────────────────┤
│ Pizzeria Mario              │
│ [Restaurant] (badge coloré) │
│ 📍 Rue de Paris 12          │
│                             │
│ Description: Excellente     │
│ pizza authentique italienne │
│                             │
│ Photos: [scroll horiz.]     │
│ [Fermer]                    │
└─────────────────────────────┘
```

---

### 6. Initialisation

Les tables POI doivent être créées via le script SQL/procédure de base de données du projet.

---

## Flux d'Utilisation

1️⃣ **Affichage initial** : L'app affiche les biens immobiliers sur la carte

2️⃣ **Afficher POI** : L'utilisateur clique sur le bouton "Points d'Intérêt" (FAB)

3️⃣ **Chargement** : Récupération des POI à proximité (rayon configurable)

4️⃣ **Rendu** : Marqueurs avec couleurs différentes selon catégorie

5️⃣ **Détails** : Tap sur marqueur → affiche la fiche avec photos/description

6️⃣ **Navigation** : Peut retourner à la carte ou voir d'autres POI

---

## Fichiers Modifiés/Créés

### API Mobile
- ✅ `php_api/api/mobile/get_pois.php` - Récupérer les POI

### Configuration
- ✅ `lib/config/api_config.dart` - URL endpoint POI ajoutée

### Modèles
- ✅ `lib/models/point_of_interest.dart` - Classe POI améliorée

### Services
- ✅ `lib/services/poi_service.dart` - Service de récupération

### UI
- ✅ `lib/screens/map/map_screen_v2.dart` - Carte avec POI markers
  - Méthode `_getPoiCategoryColor()` - Couleurs par catégorie
  - Méthode `_getPoiCategoryIcon()` - Icônes par catégorie
  - Affichage des marqueurs POI distinctifs
  - Bottom sheet enrichie avec photos/descriptions

---

## Exemple de Données

```json
{
  "id_poi": 1,
  "nom_poi": "Pizzeria Mario",
  "description": "Excellente pizza authentique italienne, ambiance chaleureuse",
  "categorie_poi": "restaurant",
  "adresse": "Rue de Paris 12, 75000 Paris",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "photos": [
    "https://example.com/pizzeria-mario-1.jpg",
    "https://example.com/pizzeria-mario-2.jpg",
    "https://example.com/pizzeria-mario-3.jpg"
  ]
}
```

---

## Tests & Validation

✅ **Flutter Tests** : All tests passed!
✅ **Compilation** : No errors
✅ **Navigation** : Routes correctes
✅ **Données** : Exemple inséré dans BDD
✅ **API** : Endpoints fonctionnels

---

## Prochaines Améliorations Possibles

- [ ] Ajouter des filtres par catégorie (afficher uniquement restaurants, pharmacies, etc.)
- [ ] Implémenter les notations et commentaires pour les POI
- [ ] Ajouter un système de favoris pour les POI
- [ ] Intégrer les horaires d'ouverture
- [ ] Téléphone/contact des POI
- [ ] Lien Google Maps pour itinéraires
- [ ] Synchronisation avec Overpass API pour POI externes
- [ ] Cache local des photos
- [ ] Notifications pour POI proches

---

## Configuration API Config

```dart
static String get pois => '$_projectPath/api/mobile/get_pois.php';
```

**URL complète** :
- Web : `http://localhost/php_api/api/mobile/get_pois.php`
- Android : `http://10.0.2.2/php_api/api/mobile/get_pois.php`
