# Documentation détaillée de `php_api` et `lib`

Ce document décrit les fichiers source identifiés dans `php_api` et `lib`, avec leur rôle, leurs imports/requires principaux et les fonctions, méthodes, getters, factories et helpers qu’ils exposent ou utilisent.

## `php_api`

### `php_api/config/jwt_config.php`
- `JWT_SECRET` : clé secrète utilisée pour signer les JWT en HS256. Elle doit rester privée et être remplacée en production.
- `JWT_EXPIRY` : durée de validité des tokens, exprimée en secondes. Ici, 30 jours.
- `JWT_ALGORITHM` : algorithme déclaré pour la signature JWT. La valeur est `HS256`.

### `php_api/config/db.php`
- Dépendances : `PDO`, `PDOException`, `Throwable`.
- `getPDO()` : crée et réutilise une connexion PDO unique vers MySQL. En cas d’échec, renvoie une réponse HTTP 500 avec un JSON d’erreur puis arrête l’exécution.
- `hapEnsureAuthSchema(PDO $pdo)` : vérifie le schéma de la table `Locataire` et agrandit `password_locataire` si l’ancienne taille `varchar(20)` est encore présente. Le contrôle n’est effectué qu’une seule fois par requête.

### `php_api/config/cors.php`
- Dépendances : `getenv()`, `header()`, `http_response_code()`, `parse_url()`.
- `hapApplyCors(array $methods = ['GET', 'POST', 'OPTIONS'])` : applique les en-têtes CORS, choisit l’origine autorisée à partir de `ALLOWED_ORIGINS` ou d’une liste locale par défaut, puis termine immédiatement la requête pour `OPTIONS`.
- `hapIsAllowedOrigin(string $origin, array $allowedOrigins)` : détermine si une origine est autorisée, soit par correspondance exacte, soit via la logique locale de développement.
- `hapIsLocalDevOrigin(string $origin)` : valide les origines locales `localhost` et `127.0.0.1` en HTTP ou HTTPS.

### `php_api/classes/JWTHelper.php`
- Dépendances : `json_encode()`, `json_decode()`, `hash_hmac()`, `hash_equals()`, `base64_encode()`, `base64_decode()`, `time()`.
- `JWTHelper::encode(array $payload, string $secret)` : construit un JWT complet au format `header.payload.signature`.
- `JWTHelper::decode(string $token, string $secret)` : vérifie la signature et l’expiration du token, puis retourne le payload ou `false`.
- `JWTHelper::verify(string $token, string $secret)` : raccourci booléen autour de `decode()`.
- `JWTHelper::sign(string $data, string $secret)` : calcule la signature HMAC-SHA256 et l’encode en Base64Url.
- `JWTHelper::base64UrlEncode(string $data)` : convertit une chaîne binaire en Base64Url sans padding.
- `JWTHelper::base64UrlDecode(string $data)` : inverse l’encodage Base64Url.

### `php_api/api/search_communes.php`
- Imports : `cors.php` pour les en-têtes CORS, `db.php` pour les constantes BDD.
- Flux principal : lit `q`, renvoie immédiatement une liste vide si la recherche est vide, sinon interroge `Commune` avec `LIKE` sur `nom_commune` et `cp_commune`.
- Fonction anonyme dans `array_map()` : transforme chaque ligne SQL en structure JSON typée avec `id_commune`, `code_insee`, `nom_commune`, `cp_commune`.

### `php_api/api/mobile/auth_login.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : lit le JSON d’entrée, valide email et mot de passe, appelle `hapEnsureAuthSchema()`, récupère l’utilisateur, accepte à la fois les mots de passe hashés et l’ancien stockage en clair, puis génère un JWT.
- Helpers utilisés : `password_verify()` pour le cas moderne, `hash_equals()` pour la compatibilité legacy, `password_hash()` pour migrer silencieusement vers un hash sécurisé.

### `php_api/api/mobile/auth_register.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : lit et valide les champs obligatoires, vérifie l’unicité de l’email, hash le mot de passe, insère le locataire, puis génère un JWT de session.
- Fonctions importantes : `filter_var()` pour l’email, `strlen()` pour la longueur minimale du mot de passe, `password_hash()` pour la sécurité.

### `php_api/api/mobile/auth_me.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : récupère le token depuis `Authorization`, le vérifie avec `JWTHelper::decode()`, charge le locataire et sa commune, puis renvoie un profil enrichi.
- Particularité : support explicite d’Apache via `apache_request_headers()` si `HTTP_AUTHORIZATION` n’est pas exposé.

### `php_api/api/mobile/auth_logout.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : si un bearer token valide est présent, il est hashé puis ajouté à une table `jwt_blacklist`, avec nettoyage des jetons expirés.
- Helpers utilisés : `hash('sha256', $token)` pour ne jamais stocker le token brut, `date()` pour calculer la date d’expiration.
- Comportement fonctionnel : la réponse est toujours un succès côté client, car la vraie déconnexion reste la suppression locale du token.

### `php_api/api/mobile/auth_register.php`, `auth_login.php`, `auth_me.php`, `auth_logout.php` comme ensemble
- Ces quatre scripts forment le cycle d’authentification mobile.
- `auth_register.php` crée un compte.
- `auth_login.php` crée une session JWT.
- `auth_me.php` recharge le profil depuis le token.
- `auth_logout.php` invalide éventuellement le token côté serveur.

### `php_api/api/mobile/get_biens_mobile.php`
- Imports : `cors.php`, `db.php`.
- Flux principal : lit tous les filtres GET, construit dynamiquement la clause `WHERE`, la clause `HAVING` et l’ordre de tri, compte le total puis renvoie une page paginée de biens.
- Fonctions et constructs utilisés : `max()`, `min()`, `match`, `array_merge()`, `implode()`, `bindValue()`, `array_map()`.
- Fonction anonyme de formatage : convertit chaque ligne SQL en objet JSON compatible avec le modèle Dart `Bien`.
- Rôle métier : c’est l’endpoint de liste principal pour l’accueil mobile.

### `php_api/api/mobile/get_bien_detail.php`
- Imports : `cors.php`, `db.php`.
- Flux principal : valide `id`, charge les informations principales du bien, puis récupère séparément photos, avis validés et tarifs à venir.
- Fonctions SQL et PHP utilisées : `ROUND()`, `AVG()`, `COUNT()`, `DATE_FORMAT()`, `array_map()`.
- Fonction anonyme sur `avis` : convertit `rating` en entier.
- Fonction anonyme sur `tarifs` : normalise `semaine_Tarif`, `annee`, `tarif`, `id_Tarif`.

### `php_api/api/mobile/get_disponibilites.php`
- Imports : `cors.php`, `db.php`.
- Flux principal : vérifie `id_biens`, charge les réservations futures confirmées, charge les semaines bloquées manuellement, puis convertit ces semaines ISO en plages de dates.
- Helpers utilisés : `DateTime::setISODate()`, `DateTime::modify()`, `date()`.
- Résultat : un tableau `reserved_ranges` consommable par le calendrier Flutter.

### `php_api/api/mobile/get_mes_reservations.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : authentifie l’utilisateur, puis renvoie ses réservations avec dates formatées, nombre de nuits, coût total, statut calculé et résumé du bien.
- Fonction anonyme `array_map()` : transforme chaque réservation SQL en structure adaptée au modèle Flutter `Reservation`.

### `php_api/api/mobile/create_reservation.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : authentifie le locataire, valide le JSON, vérifie les dates, bloque les doublons de réservation, calcule le tarif applicable puis prépare l’insertion.
- Helpers utilisés : `preg_match()` pour le format des dates, `DateTime` et `DateInterval` via `diff()`, `round()` pour le coût total.
- Logique métier : la date de début doit être dans le futur, la durée minimale est d’une nuit, et les réservations se facturent au prorata d’une semaine.

### `php_api/api/mobile/cancel_reservation.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : authentifie l’utilisateur, vérifie que la réservation lui appartient, vérifie qu’elle est à venir, puis la supprime.
- Helpers utilisés : `DateTime`, comparaison de dates et requête préparée de suppression.
- Règle métier : seules les réservations futures peuvent être annulées.

### `php_api/api/mobile/favoris.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : authentifie le locataire puis route selon la méthode HTTP.
- GET : liste les favoris avec note moyenne, nombre d’avis, tarif estimé et photo.
- POST : ajoute un bien en favori après vérification d’existence et d’état validé.
- DELETE : retire un bien des favoris.
- Helpers utilisés : `INSERT IGNORE` côté SQL pour éviter l’erreur de doublon, `array_map()` pour formater la réponse, `hash_equals()` indirectement via JWT.

### `php_api/api/mobile/update_profile.php`
- Imports : `cors.php`, `db.php`, `jwt_config.php`, `JWTHelper.php`.
- Flux principal : authentifie l’utilisateur, lit un JSON partiel, normalise les champs vides en `null`, valide la date de naissance et prépare une mise à jour ciblée.
- Caractéristique importante : seuls les champs présents et non vides sont appliqués, ce qui évite d’effacer accidentellement le profil.

### `php_api/api/mobile/search_biens.php`
- Imports : `cors.php`, `db.php`.
- Flux principal : autocomplete des biens par `q`, avec filtre sur biens validés et visibles, jointure commune et extraction de la première photo.
- Fonction anonyme `array_map()` : renvoie un JSON minimal pour l’interface de recherche.

### `php_api/api/mobile/get_pois.php`
- Imports : `cors.php`, `db.php`.
- Flux principal : charge les points d’intérêt et les événements, applique un filtre géographique optionnel et un filtre catégorie optionnel, puis enrichit chaque POI avec ses photos.
- Helpers utilisés : `header()` pour désactiver le cache, `DateTime` côté PHP n’est pas utilisé ici, `array_map()` pour assembler la réponse.
- Fait métier important : les événements sont mappés avec un identifiant décalé de `1000000`, ce qui les distingue des POI.

### `php_api/api/mobile/get_biens_mobile.php`, `get_bien_detail.php`, `search_biens.php`
- Ces endpoints forment le noyau lecture côté mobile.
- `get_biens_mobile.php` sert la liste paginée filtrée.
- `get_bien_detail.php` sert la vue détaillée.
- `search_biens.php` alimente l’autocomplétion.

### `php_api/api/mobile/get_disponibilites.php`, `create_reservation.php`, `cancel_reservation.php`, `get_mes_reservations.php`
- Ces endpoints gèrent tout le cycle de réservation.
- `get_disponibilites.php` expose les créneaux indisponibles.
- `create_reservation.php` réserve.
- `cancel_reservation.php` annule une réservation à venir.
- `get_mes_reservations.php` liste les réservations du locataire.

### `php_api/api/mobile/auth_*`
- Ces scripts constituent le sous-système d’authentification JWT.
- Ils partagent tous les mêmes dépendances CORS / BDD / JWT.
- Ils utilisent `apache_request_headers()` comme compatibilité serveur.

## `lib`

---

## Guide Complet Dart pour Débutants

Si vous découvrez le langage Dart, cette section explique les concepts clés que vous rencontrerez dans ce projet. Dart est un langage orienté objet, fortement typé, utilisé principalement pour développer des applications Flutter.

### 1. Concepts Fondamentaux Dart

#### Types et Null Safety (Sécurité Nulle)
Dart 2.12+ introduit la **null safety**, un système qui vous force à gérer les valeurs `null` explicitement :

```dart
String nom = "Alice";      // Jamais null
String? email = null;      // Peut être null (le ? indique null-safe)

// Pour accéder à une valeur nullable, il faut vérifier d'abord :
if (email != null) {
  print(email.length);     // Safe - email est garantie non-null ici
}

// Opérateurs de coalescence nulle
String adresse = user.adresse ?? "Non spécifiée";  // Valeur par défaut
int age = int.tryParse(ageTxt) ?? 0;               // Conversion sûre
```

**Exemple dans votre code** : Dans `user.dart`, le `User` a des champs `String?` car ils peuvent être `null` :
```dart
class User {
  final int idLocataire;
  final String email;
  final String prenom;
  final String? telephone;    // Nullable
  final String? adresse;      // Nullable
}
```

#### Variables et Typage
```dart
// Inférence de type (le compilateur détecte le type)
var nombre = 42;             // Dart infère int
var texte = "Hello";         // Dart infère String

// Déclaration explicite (recommandé pour la clarté)
int compteur = 10;
String message = "Bonjour";
double prix = 19.99;

// Collections typées
List<String> emails = ["alice@mail.com", "bob@mail.com"];
Map<String, int> ages = {"Alice": 30, "Bob": 25};
Set<int> ids = {1, 2, 3};
```

#### Getters et Setters
Dart permet de créer des propriétés calculées sans parenthèses :

```dart
class Bien {
  final String nom;
  final double prix;
  final double? remise;

  // Getter : propriété calculée, pas d'appel ()
  double get prixFinal => prix * (1 - (remise ?? 0));

  // Dans le code
  print(bien.prixFinal);      // Pas de parenthèses, mais c'est une méthode
}

// Setter : modification de propriété
class Utilisateur {
  String _email = "";

  String get email => _email;
  
  set email(String value) {
    if (value.contains("@")) {
      _email = value;
    }
  }
}
```

**Exemple dans votre code** : Dans `bien.dart`, `communeLabel` est un getter :
```dart
String get communeLabel => "$nom_commune ($cp_commune)";
```

#### Fonctions Anonymes et Arrow Functions
```dart
// Fonction anonyme classique
List<int> nombres = [1, 2, 3];
nombres.map((n) {
  return n * 2;
}).toList();

// Arrow function (=>)  - plus court pour une seule expression
nombres.map((n) => n * 2).toList();

// Utilisation dans callbacks
button.onPressed = () {
  print("Bouton cliqué");
};
```

**Exemple dans votre code** : Dans `api_service.dart`, les callbacks utilisent les arrow functions :
```dart
.then((response) => _handleResponse(response))
.catchError((error) => throw error);
```

### 2. Async/Await et Futures

Dart utilise des **Futures** pour les opérations asynchrones (comme les appels API). C'est similaire aux **Promises** en JavaScript.

```dart
// Future<T> = une valeur qui sera disponible plus tard
Future<String> fetchData() async {
  // await = attendre la réponse
  final response = await http.get(url);
  return response.body;
}

// Utilisation
void main() async {
  String data = await fetchData();  // Attend la réponse
  print(data);
}

// Enchaîner sans async/await (style ancien)
fetchData().then((data) {
  print(data);
}).catchError((error) {
  print("Erreur : $error");
});
```

**Exemple dans votre code** : Dans `auth_service.dart` :
```dart
Future<void> login(String email, String password) async {
  final response = await ApiService.post(ApiConfig.login, {
    'email': email,
    'mot_de_passe': password,
  });
  // ...
}
```

### 3. Classes et Constructeurs

#### Constructeur Simple
```dart
class User {
  final String nom;
  final int age;

  // Constructeur simple
  User(this.nom, this.age);
}

// Utilisation
var user = User("Alice", 30);
```

#### Constructeur Nommé (Named Constructor)
```dart
class Bien {
  final String nom;
  final double prix;

  // Constructeur classique
  Bien(this.nom, this.prix);

  // Constructeur nommé pour cas spéciaux
  Bien.empty() : 
    nom = "",
    prix = 0.0;

  // Constructeur factory (créer une instance autrement)
  factory Bien.fromJson(Map<String, dynamic> json) {
    return Bien(
      json['nom'] as String,
      json['prix'] as double,
    );
  }
}

// Utilisation
var bien1 = Bien("Maison", 500000);
var bien2 = Bien.empty();
var bien3 = Bien.fromJson(apiResponse);
```

**Exemple dans votre code** : Dans `user.dart` :
```dart
class User {
  final int idLocataire;
  // ... autres champs

  User({required this.idLocataire, required this.email, ...});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idLocataire: json['id_Locataire'] as int,
      email: json['email_Locataire'] as String,
      // ...
    );
  }
}
```

#### CopyWith (Copier avec Modifications)
Modèle courant en Dart pour créer une copie d'un objet avec certains champs modifiés :

```dart
class Filtres {
  final String recherche;
  final int? maxPrix;
  final String? commune;

  Filtres({
    required this.recherche,
    this.maxPrix,
    this.commune,
  });

  // Créer une copie avec certains champs changés
  Filtres copyWith({
    String? recherche,
    int? maxPrix,
    String? commune,
  }) {
    return Filtres(
      recherche: recherche ?? this.recherche,
      maxPrix: maxPrix ?? this.maxPrix,
      commune: commune ?? this.commune,
    );
  }
}

// Utilisation
var filtres2 = filtres1.copyWith(maxPrix: 600000);
```

**Exemple dans votre code** : Dans `filter_options.dart` :
```dart
FilterOptions copyWith({
  String? recherche,
  RangeValues? fourchettePrix,
  // ...
}) {
  return FilterOptions(
    recherche: recherche ?? this.recherche,
    fourchettePrix: fourchettePrix ?? this.fourchettePrix,
    // ...
  );
}
```

### 4. Extensions et Modificateurs

#### const (Immuable)
```dart
// const = valeur déterminée à la compilation
const int maxUsers = 100;
const String appName = "HAP";

// constexpr en classe
class Config {
  static const String baseUrl = "http://api.example.com";
}
```

#### final (Immuable après initialisation)
```dart
// final = défini une seule fois à l'exécution
final String uuid = generateUUID();
final DateTime createdAt = DateTime.now();

// Dans une classe
class User {
  final int id;        // Doit être défini dans le constructeur
  final String email;

  User(this.id, this.email);
}
```

#### late (Inicialisation différée)
```dart
// late = la valeur sera définie plus tard, pas au constructeur
class ProfileScreen extends StatefulWidget {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();  // Défini ici
  }
}
```

### 5. Extension Methods

Dart permet d'ajouter des méthodes aux classes existantes :

```dart
// Extension sur String
extension StringExtension on String {
  String toCapitalized() => 
    length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

// Utilisation
String nom = "alice";
print(nom.toCapitalized());  // "Alice"

// Extension sur DateTime
extension DateTimeExt on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && 
           month == now.month && 
           day == now.day;
  }
}
```

**Exemple dans votre code** : Dans `filter_options.dart`, il y a une extension :
```dart
extension SortOptionExt on SortOption {
  String get apiValue { ... }
  String get label { ... }
}
```

### 6. Énumérations (Enums)

```dart
enum Statut {
  aVenir,
  enCours,
  termine,
}

// Accès
if (reservation.statut == Statut.aVenir) {
  print("Réservation à venir");
}

// Switch sur enum
String label = switch(statut) {
  Statut.aVenir => "À venir",
  Statut.enCours => "En cours",
  Statut.termine => "Terminé",
};
```

**Exemple dans votre code** : Dans `reservation.dart` :
```dart
enum StatutReservation {
  aVenir,
  enCours,
  termine,
}

class Reservation {
  final StatutReservation statut;
  
  String get statutLabel => switch(statut) {
    StatutReservation.aVenir => "À venir",
    StatutReservation.enCours => "En cours",
    StatutReservation.termine => "Terminé",
  };
}
```

### 7. String Interpolation

Dart permet d'insérer des variables directement dans les chaînes :

```dart
String nom = "Alice";
int age = 30;

// Utiliser $variable pour insérer simplement
print("Bonjour $nom, vous avez $age ans");

// Utiliser ${expression} pour des expressions complexes
print("L'année prochaine vous aurez ${age + 1} ans");

// Expressions dans les URLs
String email = "test@example.com";
String url = "https://api.com/users/$email";
```

**Exemple dans votre code** : Dans `api_service.dart` :
```dart
final url = '${ApiConfig.baseUrl}${endpoint}';
```

### 8. Mixin et Héritage Multiple

Dart ne supporte pas l'héritage multiple classique, mais les **mixins** en permettent l'équivalent :

```dart
// Mixin = classe qui ajoute des fonctionnalités
mixin LoggerMixin {
  void log(String message) {
    print("[LOG] $message");
  }
}

mixin TimestampMixin {
  DateTime timestamp = DateTime.now();
}

// Utiliser des mixins
class ApiService with LoggerMixin, TimestampMixin {
  void fetchData() {
    log("Récupération des données");
  }
}
```

### 9. Génériques (Generics)

Les génériques permettent des collections et méthodes type-safe :

```dart
// Générique sur une classe
class Cache<T> {
  final Map<String, T> _data = {};

  void set(String key, T value) {
    _data[key] = value;
  }

  T? get(String key) => _data[key];
}

// Utilisation
Cache<String> stringCache = Cache();
stringCache.set("name", "Alice");

Cache<int> intCache = Cache();
intCache.set("age", 30);

// Générique sur une méthode
List<T> filterList<T>(List<T> items, bool Function(T) predicate) {
  return items.where(predicate).toList();
}

List<int> nums = [1, 2, 3, 4, 5];
List<int> evens = filterList(nums, (n) => n % 2 == 0);
```

### 10. Pattern Matching (Switch Expression)

Dart 3+ supporte le pattern matching moderne :

```dart
String getUserMessage(User? user) => switch(user) {
  null => "Pas d'utilisateur",
  User(age: > 18) => "Adulte",
  User(age: <= 18, nom: 'Alice') => "Alice mineure",
  _ => "Autre",
};
```

---

### 11. Provider Pattern (Gestion d'État)

**Provider** est un système de gestion d'état populaire en Flutter. Les concepts clés :

```dart
// ChangeNotifier = observable pattern
class AuthProvider extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  // Notifier les listeners de changements
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();  // Redraw les widgets qui l'observent
  }
}

// Dans un Widget
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Consumer = s'abonne aux changements
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.currentUser == null) return LoginScreen();
        return Text("Bienvenue ${auth.currentUser!.nom}");
      },
    );
  }
}
```

**Exemple dans votre code** : `auth_provider.dart` utilise ce pattern :
```dart
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  void login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await AuthService.login(email, password);
      _currentUser = user;
      notifyListeners();  // Notifier les widgets
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
```

### 12. Widget Lifecycle (Cycle de Vie)

En Flutter, les **StatefulWidgets** ont un cycle de vie :

```dart
class MonWidget extends StatefulWidget {
  @override
  State<MonWidget> createState() => _MonWidgetState();
}

class _MonWidgetState extends State<MonWidget> {
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Appelé une seule fois à la création
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(MonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Appelé quand le widget parent change
  }

  @override
  void dispose() {
    super.dispose();
    // Appelé à la destruction - NETTOYER les ressources
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Appelé à chaque setState()
    return TextField(controller: _controller);
  }
}
```

**Exemple dans votre code** : `search_bar_widget.dart` suit ce cycle :
```dart
@override
void initState() {
  super.initState();
  _controller = TextEditingController();
  _controller.addListener(_onTextChanged);
}

@override
void dispose() {
  _debounceTimer?.cancel();
  _controller.dispose();
  super.dispose();
}
```

### 13. Lire et Écrire du JSON

Le JSON est converti en objets Dart via `fromJson()` et `toJson()` :

```dart
// Modèle
class Utilisateur {
  final int id;
  final String nom;
  final String? email;

  Utilisateur({required this.id, required this.nom, this.email});

  // Depuis API JSON
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String?,
    );
  }

  // Vers JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
    };
  }
}

// Utilisation
var json = {'id': 1, 'nom': 'Alice', 'email': 'alice@mail.com'};
var user = Utilisateur.fromJson(json);

// Conversion en JSON string
import 'dart:convert';
String jsonString = jsonEncode(user.toJson());
```

**Exemple dans votre code** : Tous les modèles dans `lib/models/` utilisent ce pattern.

---

### 14. Debounce et Throttling

Lors de recherches en temps réel, il faut éviter les appels API constants :

```dart
// Debounce = attendre que l'utilisateur arrête de taper avant l'appel
class SearchWidget extends StatefulWidget {
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();  // Annuler le timer précédent
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      fetchResults(query);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

**Exemple dans votre code** : `search_bar_widget.dart` utilise ce pattern :
```dart
void _onTextChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    widget.onSearch(query);
  });
}
```

---

### 15. Erreurs Courantes à Éviter

| Erreur | Mauvais | Correct |
|--------|--------|---------|
| Oublier `await` | `var data = fetchData()` | `var data = await fetchData()` |
| Null safety | `user.nom.length` (crash si null) | `user.nom?.length ?? 0` |
| Dispose oublié | Ne pas appeler `super.dispose()` | Toujours appeler `super.dispose()` |
| setState en dispose | `setState()` dans `dispose()` | Éviter `setState()` après `dispose()` |
| Lutter contre const | `final List<int> = []` | `final List<int> = const []` si immuable |

---

### Résumé pour Démarrer

1. **Types** : Déclarez les types explicitement (`String`, `int`, `List<T>`)
2. **Null Safety** : Utilisez `?` pour nullable, vérifiez avec `??`
3. **Async** : Utilisez `async/await` pour les opérations longues
4. **Widgets** : Créez des `StatelessWidget` ou `StatefulWidget` pour l'UI
5. **Provider** : Gérez l'état avec `ChangeNotifier` et `Consumer`
6. **JSON** : Convertissez avec `fromJson()` et `toJson()`
7. **Dispose** : Nettoyez toujours dans `dispose()`
8. **Erreurs** : Attrapez les exceptions avec `try/catch`

Vous verrez tous ces patterns appliqués dans les fichiers de ce projet. Reportez-vous à cette section quand vous en rencontrez un !

---

### `lib/config/api_config.dart`
- Imports : `kIsWeb`, `defaultTargetPlatform`, `TargetPlatform` depuis `package:flutter/foundation.dart`.
- `ApiConfig.baseUrl` : choisit dynamiquement la base URL selon la cible d’exécution ou la valeur `API_BASE_URL`.
- `ApiConfig._projectPath` : concatène la base URL avec le dossier `php_api`.
- Endpoints getters : `login`, `register`, `me`, `logout`, `biens`, `bienDetail`, `communes`, `favoris`, `disponibilites`, `createReservation`, `mesReservations`, `cancelReservation`, `updateProfile`, `searchBiens`, `pois`.
- `adresseGouv` : URL publique pour l’autocomplete d’adresse française.
- `photoUrl(String? lienPhoto)` : normalise une URL de photo en gérant les cas `null`, URL locales `localhost`, URL externes et chemins relatifs.

### `lib/services/api_service.dart`
- Imports : `dart:convert`, `dart:async`, `package:http/http.dart` as `http`, `SharedPreferences`.
- `ApiService.get()` : effectue un GET avec timeout, paramètres de requête et en-têtes automatiques.
- `ApiService.post()` : effectue un POST JSON avec timeout.
- `ApiService.delete()` : effectue un DELETE JSON via `http.Request`.
- `ApiService._buildHeaders()` : construit les en-têtes communs, avec Bearer token si disponible.
- `ApiService._handleResponse()` : interprète la réponse HTTP, décode le JSON et déclenche une `UnauthorizedException` sur 401.
- `ApiService._clearLocalSession()` : supprime le token et l’utilisateur localement.
- `UnauthorizedException` : exception dédiée aux réponses 401.

### `lib/services/auth_service.dart`
- Imports : `dart:convert`, `SharedPreferences`, `ApiConfig`, `User`, `ApiService`.
- `AuthService.login()` : appelle `auth_login.php`, sauvegarde la session si succès.
- `AuthService.register()` : appelle `auth_register.php`, sauvegarde la session si succès.
- `AuthService.logout()` : appelle `auth_logout.php`, puis efface localement la session.
- `AuthService.isLoggedIn()` : vérifie si un token existe en local.
- `AuthService.getCurrentUser()` : lit l’utilisateur depuis `SharedPreferences`.
- `AuthService.fetchMe()` : recharge le profil complet depuis l’API et met à jour le cache.
- `AuthService.updateProfile()` : pousse les modifications de profil vers l’API puis recache l’utilisateur.
- `AuthService.getToken()` : récupère le JWT local.
- `AuthService.saveSession()` : enregistre token et utilisateur.
- `AuthService._saveUser()` : écrit uniquement l’utilisateur dans le cache.
- `AuthService.clearSession()` : supprime les données de session.

### `lib/services/profile_service.dart`
- Imports : `User`, `AuthService`.
- `ProfileService.updateProfile()` : simple façade vers `AuthService.updateProfile()`. Elle n’ajoute pas de logique métier supplémentaire.

### `lib/services/reservation_service.dart`
- Imports : `ApiConfig`, `BienDetail`, `Reservation`, `ApiService`.
- `ReservationService.getBienDetail()` : charge le détail complet d’un bien.
- `ReservationService.getDisponibilites()` : charge les plages réservées pour un bien.
- `ReservationService.createReservation()` : formate les dates puis crée une réservation.
- `ReservationService.cancelReservation()` : annule une réservation si l’API renvoie succès.
- `ReservationService.getMesReservations()` : charge et transforme les réservations de l’utilisateur connecté.

### `lib/services/bien_service.dart`
- Imports : `ApiConfig`, `Bien`, `FilterOptions`, `ApiService`.
- `BienService.getBiens()` : transmet les filtres à l’API, mappe les résultats en `Bien` et renvoie la pagination complète.
- `BienService.toggleFavori()` : envoie une demande de bascule de favori. Le paramètre `token` est conservé pour compatibilité d’appel mais n’est pas utilisé directement car `ApiService` gère le JWT.
- `BienService.getFavoris()` : récupère la liste des IDs favoris.
- `BienService.searchSuggestions()` : renvoie les suggestions d’autocomplétion pour la recherche.

### `lib/services/poi_service.dart`
- Imports : `dart:convert`, `http`, `LatLng`, `ApiConfig`, `PointOfInterest`.
- `PoiService.fetchNearbyPois()` : tente d’abord la base locale, puis un fallback global, puis OpenStreetMap Overpass.
- `PoiService._fetchFromDatabase()` : appelle l’API PHP locale et transforme le JSON en `PointOfInterest`.
- `PoiService._fetchFromOverpass()` : interroge Overpass API et convertit les nœuds en points d’intérêt.
- `PoiService._categoryFromTags()` : déduit une catégorie lisible à partir des tags OSM.
- `PoiService._friendlyAmenity()`, `_friendlyTourism()`, `_friendlyLeisure()` : convertissent les valeurs OSM techniques en libellés UI.

### `lib/services/favoris_service.dart`
- Imports : `ApiConfig`, `ApiService`.
- `FavorisService.getFavoris()` : charge les favoris et les renvoie sous forme de listes de maps.
- `FavorisService.retirerFavori()` : supprime un favori via DELETE et lève une exception si l’API échoue.

### `lib/services/notification_service.dart`
- Imports : `dart:convert`, `SharedPreferences`, `AppNotificationItem`, `Reservation`, `ReservationService`.
- `NotificationService.loadNotifications()` : fusionne les notifications stockées localement et celles générées à partir des réservations.
- `NotificationService.getUnreadCount()` : compte les notifications non lues.
- `NotificationService.markAsRead()` : marque une notification donnée comme lue.
- `NotificationService.markAllAsRead()` : marque tout comme lu.
- `NotificationService.clear()` : vide le cache de notifications.
- `NotificationService._generateFromReservations()` : fabrique des rappels métier à partir des réservations à venir ou en cours.
- `NotificationService._loadStoredNotifications()` : lit et désérialise le cache local.
- `NotificationService._saveNotifications()` : persiste les notifications en JSON.
- `NotificationService._formatDate()` : formate une date en français court.

### `lib/services/app_preferences_service.dart`
- Imports : `SharedPreferences`.
- `getNotificationsEnabled()` / `setNotificationsEnabled()` : lisent ou écrivent l’activation globale des notifications.
- `getCompactLayout()` / `setCompactLayout()` : gèrent le mode d’affichage compact.
- `getLanguage()` / `setLanguage()` : gèrent la langue d’interface persistée.

### `lib/models/bien.dart`
- `Bien` : modèle principal d’un bien immobilier.
- Constructeur : instancie les champs nécessaires pour la liste et la carte détail.
- `Bien.fromJson()` : convertit la réponse API en objet `Bien`.
- `toJson()` : sérialise le modèle pour stockage ou envoi.
- `animauxAcceptes` : indique si les animaux sont autorisés.
- `communeLabel` : retourne un libellé lisible de commune, avec code postal si présent.

### `lib/models/bien_detail.dart`
- Imports : `bien.dart`.
- `BienPhoto` : photo d’un bien.
- `BienPhoto.fromJson()` : lit l’objet photo depuis l’API.
- `Avis` : avis utilisateur sur un bien.
- `Avis.fromJson()` : convertit une ligne d’avis.
- `TarifSemaine` : tarif hebdomadaire pour une semaine donnée.
- `TarifSemaine.fromJson()` : transforme la ligne SQL de tarif.
- `BienDetail` : extension de `Bien` avec photos, avis et tarifs.
- `BienDetail.fromJson()` : reconstruit l’objet détaillé complet.
- `tarifPourDate(DateTime date)` : cherche le tarif applicable à une date donnée.
- `_isoWeek(DateTime date)` et `_isoYear(DateTime date)` : helpers de calcul de semaine/année ISO simplifiés.

### `lib/models/reservation.dart`
- `ReservationBien` : résumé imbriqué du bien associé à une réservation.
- `ReservationBien.fromJson()` : conversion JSON du bien résumé.
- `StatutReservation` : enum des statuts métier (`aVenir`, `enCours`, `termine`).
- `Reservation` : modèle de réservation utilisateur.
- `Reservation.fromJson()` : mappe la réponse API et convertit le statut texte en enum.
- `statutLabel` : libellé d’affichage lisible en français.

### `lib/models/user.dart`
- `User` : modèle du locataire connecté.
- `User.fromJson()` : parse une réponse API profil/connexion.
- `toJson()` : sérialise l’utilisateur.
- `fullName` : concatène prénom et nom.
- `_parseInt(dynamic value)` : helper robuste pour convertir un entier venant du JSON.
- `toString()` : représentation de debug.

### `lib/models/point_of_interest.dart`
- `PointOfInterest` : modèle de POI ou d’événement.
- `PointOfInterest.fromJson()` : accepte plusieurs variantes de clés JSON (`id_poi`, `id`, `name`, `categorie_poi`, etc.).
- `toJson()` : sérialise le POI.

### `lib/models/filter_options.dart`
- `SortOption` : enum des tris de liste.
- `SortOptionExt.apiValue` : valeur transmise à l’API.
- `SortOptionExt.label` : libellé UI du tri.
- `FilterOptions` : snapshot immuable des critères de recherche.
- `FilterOptions.empty()` : instance sans filtre.
- `activeCount` : nombre de filtres actifs.
- `isEmpty` : vrai si aucun filtre ni recherche n’est actif.
- `toQueryParams()` : convertit les filtres en paramètres GET.
- `copyWith()` : crée une copie en modifiant ou en effaçant sélectivement des champs.

### `lib/models/app_notification.dart`
- `AppNotificationItem` : modèle de notification locale.
- `copyWith()` : recopie une notification avec un nouvel état de lecture.
- `fromJson()` : lit une notification persistée.
- `toJson()` : sérialise la notification.

### `lib/providers/auth_provider.dart`
- Imports : `foundation.dart`, `User`, `AuthService`.
- `AuthProvider` : `ChangeNotifier` central pour l’authentification.
- `checkAuth()` : initialise l’état à partir de la session locale.
- `updateProfile()` : propage la mise à jour du profil vers l’API et l’état local.
- `login()` : se connecte et met à jour token, utilisateur et état global.
- `register()` : crée un compte et synchronise l’état.
- `logout()` : appelle le logout serveur, puis purge l’état local.
- `_setLoading()` : bascule l’état de chargement et notifie les listeners.
- Getters : `isAuthenticated`, `currentUser`, `token`, `isLoading`, `error`.

### `lib/widgets/bien_card.dart`
- Imports : `CachedNetworkImage`, `Material`, `flutter_rating_bar`, `ApiConfig`, `Bien`.
- `BienCard` : carte d’un bien avec photo, note, prix et favori.
- `_BienCardState.initState()` : initialise l’état favori et l’animation du cœur.
- `_BienCardState.dispose()` : libère l’`AnimationController`.
- `_toggleFavori()` : inverse l’état favori local et déclenche l’animation.
- `_buildImage()` et autres helpers internes du rendu : gèrent l’image, les overlays et le fallback visuel.

### `lib/widgets/search_bar_widget.dart`
- Imports : `dart:async`, `Material`.
- `SearchBarWidget` : champ de recherche avec debounce et bouton filtres.
- `_SearchBarWidgetState.initState()` : initialise le contrôleur texte et le listener de mise à jour.
- `_SearchBarWidgetState.didUpdateWidget()` : synchronise la valeur initiale si elle change depuis le parent.
- `_SearchBarWidgetState.dispose()` : annule le debounce et détruit le contrôleur.
- `_onTextChanged()` : déclenche la recherche après 500 ms.
- `_clearSearch()` : vide le champ et notifie immédiatement le parent.
- `build()` : rend le champ, le bouton clear et le bouton filtres avec badge.

### `lib/widgets/filter_bottom_sheet.dart`
- Imports : `Material`, `flutter_rating_bar`, `FilterOptions`.
- `showFilterBottomSheet()` : ouvre le panneau modal de filtres.
- `FilterBottomSheet` : widget d’édition des filtres.
- `_FilterBottomSheetState.initState()` : copie les filtres initiaux dans l’état local.
- `_activeCount` : compte les filtres réellement actifs dans le panneau.
- `_reset()` : remet tous les filtres à leur valeur par défaut.
- `_apply()` : transforme l’état local en `FilterOptions` final et le renvoie au parent.
- Les helpers `build` privés du widget structurent les sections de l’UI, les chips, sliders, switches et options de tri.

### `lib/widgets/calendrier_disponibilites.dart`
- Imports : `Material`, `intl`, `table_calendar`, `BienDetail`.
- `showCalendrierDisponibilites()` : ouvre le calendrier de réservation et renvoie la plage validée ou `null`.
- `CalendrierDisponibilitesSheet` : widget de calendrier en bottom sheet.
- `_CalendrierDisponibilitesSheetState.initState()` : prépare l’ensemble des jours bloqués.
- `_buildBlockedDays()` : convertit les plages réservées en ensemble de jours individuels.
- `_isDayBlocked()`, `_isDayBeforeToday()`, `_isSelectableDay()` : déterminent si un jour est sélectionnable.
- `_nbNuits` : calcule la durée de la plage.
- `_estimatedCost` : estime le coût à partir du tarif du bien.
- `_onDaySelected()` et `_onRangeSelected()` : mettent à jour la sélection.
- `_confirm()` : ferme la sheet si la plage est valide.

### `lib/widgets/bottom_nav_bar.dart`
- Imports : `Material`.
- `HapBottomNavBar` : barre de navigation inférieure à 5 onglets.
- `build()` : rend la barre avec icônes actives/inactives et styles HAP.

### `lib/screens/home_screen.dart`
- Imports : `bottom_nav_bar.dart`, `FavorisScreen`, `home/home_screen.dart` alias `home`, `MapScreen`, `ProfileScreen`, `ReservationsScreen`.
- `HomeScreen` : shell principal de navigation.
- `_HomeScreenState.build()` : affiche les onglets dans un `IndexedStack` et la barre du bas.
- Ce fichier ne contient pas de logique métier complexe, mais organise la navigation persistante.

### `lib/screens/home/home_screen.dart`
- Imports : `Material`, `HapBottomNavBar`, écrans `favoris`, `map`, `profile`, `reservations`, `home`.
- `HomeScreen` : shell principal qui contient les 5 onglets de l’application.
- `_HomeScreenState.build()` : alterne entre les écrans via `_currentIndex` et conserve leur état grâce à `IndexedStack`.

### `lib/screens/auth/splash_screen.dart`
- Imports : `Material`, `go_router`, `AuthService`.
- `SplashScreen` : écran de démarrage.
- `_SplashScreenState.initState()` : lance l’animation et vérifie la session.
- `_checkSession()` : attend 1,5 seconde, vérifie la présence d’un token puis redirige vers `/home` ou `/login`.
- `dispose()` : libère l’animation.
- `build()` : affiche le logo, le nom de l’app et l’indicateur de chargement.

### `lib/screens/auth/login_screen.dart`
- Imports : `Material`, `go_router`, `provider`, `AuthProvider`.
- `LoginScreen` : formulaire de connexion.
- `_submit()` : valide le formulaire, appelle `auth.login()` et navigue ou affiche un SnackBar d’erreur.
- `dispose()` : libère les contrôleurs de texte.
- `build()` : compose les champs email/mot de passe, le toggle de visibilité et les liens de navigation.

### `lib/screens/auth/register_screen.dart`
- Imports : `dart:async`, `dart:convert`, `Material`, `go_router`, `http`, `intl`, `provider`, `ApiConfig`, `AuthProvider`, `ApiService`.
- `RegisterScreen` : formulaire d’inscription complet.
- `_onCommuneChanged()` : lance une recherche de communes avec debounce.
- `_onCommuneSelected()` : remplit la commune sélectionnée et réinitialise la rue.
- `_onRueChanged()` : interroge l’API adresse française avec le `citycode` sélectionné.
- `_pickDate()` : ouvre un sélecteur de date de naissance.
- `_submit()` : valide tous les champs, vérifie la cohérence des mots de passe puis appelle `auth.register()`.
- `dispose()` : détruit les contrôleurs et annule les timers.

### `lib/screens/home/home_screen.dart`, `favoris/favoris_screen.dart`, `reservations/reservations_screen.dart`, `profile/profile_screen.dart`, `map/map_screen.dart`, `notifications/notifications_screen.dart`
- Ces écrans forment l’interface principale accessible depuis le shell `HomeScreen`.
- Ils consomment surtout `AuthProvider`, `ApiConfig`, les services métier et divers widgets d’affichage.

### `lib/screens/home/home_screen.dart` et `lib/screens/home_screen.dart`
- Le premier est le shell de navigation avec les onglets.
- Le second est l’écran de feed principal des biens avec recherche, filtres, suggestions et pagination.

### `lib/screens/home/home_screen.dart` ? Correction pratique
- Le chemin `lib/screens/home/home_screen.dart` correspond au contenu principal “Accueil”.
- Le chemin `lib/screens/home_screen.dart` correspond au conteneur de navigation.
- Les deux portent des responsabilités différentes malgré un nom proche.

### `lib/screens/home/home_screen.dart` contenu principal
- Imports : `Material`, `provider`, `shimmer`, `go_router`, `Bien`, `ApiConfig`, `FilterOptions`, `AuthProvider`, `BienService`, `NotificationService`, `BienCard`, `FilterBottomSheet`, `SearchBarWidget`.
- `HomeScreen` : page d’accueil avec liste paginée de biens.
- `_loadBiens()` : charge ou recharge la liste selon les filtres et la pagination.
- `_onScroll()` : déclenche le chargement de la page suivante près du bas de liste.
- `_onSearch()` : met à jour les filtres, recharge les suggestions et la liste.
- `_loadSuggestions()` : appelle l’autocomplétion de biens.
- `_selectSuggestion()` : applique une suggestion sélectionnée.
- `_openFilters()` : ouvre la bottom sheet de filtres.
- `_loadUnreadNotifications()` : récupère le nombre de notifications non lues.
- `build()` : compose l’app bar, la barre de recherche, les suggestions, la liste et le FAB.

### `lib/screens/favoris/favoris_screen.dart`
- Imports : `CachedNetworkImage`, `Material`, `flutter_rating_bar`, `go_router`, `provider`, `ApiConfig`, `AppPreferencesService`, `AuthProvider`, `FavorisService`.
- `FavorisScreen` : liste des biens favoris de l’utilisateur.
- `_loadPreferences()` : lit le mode compact.
- `_load()` : charge les favoris depuis le service.
- `_retirer(int idBiens)` : retire un bien des favoris avec feedback immédiat.
- `build()` : construit l’UI principale.
- `_buildBody()` : gère les états chargement, erreur, vide et liste.
- Les widgets internes `_SectionShell`, `_SummaryCard`, `_FavoriCard` et autres helpers assurent la mise en page détaillée.

### `lib/screens/reservations/reservations_screen.dart`
- Imports : `CachedNetworkImage`, `Material`, `go_router`, `intl`, `ApiConfig`, `Reservation`, `AppPreferencesService`, `ReservationService`.
- `ReservationsScreen` : liste des réservations de l’utilisateur.
- `_loadPreferences()` : lit le mode compact.
- `_refresh()` : recharge la future des réservations.
- `_annuler(Reservation r)` : demande confirmation puis annule la réservation si elle est annulable.
- `_fmt(String iso)` : formate une date ISO en français.
- `build()` : gère le FutureBuilder, l’état vide et la liste.
- `_buildEmpty()` : affiche un état vide avec action vers la recherche des biens.

### `lib/screens/bien_detail/bien_detail_screen.dart`
- Imports : `CachedNetworkImage`, `CarouselSlider`, `Material`, `flutter_map`, `flutter_rating_bar`, `intl`, `LatLng`, `ApiConfig`, `Bien`, `BienDetail`, `ReservationService`, `showCalendrierDisponibilites`, `showReservationFormSheet`.
- `BienDetailScreen` : écran détaillé d’un bien.
- `_loadDetail()` : charge le détail complet du bien.
- `_loadDisponibilites()` : charge les périodes réservées.
- `_openReservation()` : enchaîne le calendrier puis la confirmation de réservation.
- `build()` : choisit entre loader, erreur ou contenu.
- `_buildLoader()` : affiche l’indicateur de chargement.
- `_buildContent()` : organise le `CustomScrollView` et la barre sticky.
- `_buildError()` : affiche un état d’erreur avec bouton réessayer.
- `_buildSliverAppBar()` : affiche le carrousel de photos en haut.
- `_buildPhotoCarousel(List<BienPhoto> photos)` : gère le slider d’images.
- `_buildPhotoFallback()` : fournit une image de secours quand il n’y a pas de photo.
- D’autres helpers rendent le corps de page, la carte, les avis et le bloc de réservation.

### `lib/screens/bien_detail/reservation_form_sheet.dart`
- Imports : `Material`, `intl`, `BienDetail`, `ReservationService`.
- `showReservationFormSheet()` : ouvre la confirmation de réservation et renvoie un booléen.
- `ReservationFormSheet` : bottom sheet de confirmation.
- `_ReservationFormSheetState._nbNuits` : calcule la durée.
- `_estimatedCost` : estime le coût total.
- `_fmtDate()` : formate une date en français.
- `_confirmer()` : appelle l’API de réservation puis ferme la sheet en cas de succès.
- `build()` : affiche le récapitulatif, le tarif, les erreurs et le bouton de confirmation.

### `lib/screens/map/map_screen.dart`
- Imports : `dart:convert`, `CachedNetworkImage`, `Material`, `flutter_map`, `flutter_map_cancellable_tile_provider`, `flutter_rating_bar`, `geolocator`, `go_router`, `http`, `LatLng`, `shimmer`, `ApiConfig`, `Bien`, `PointOfInterest`, `PoiService`.
- `MapScreen` : carte interactive des biens et des points d’intérêt.
- `_loadBiens()` : charge les biens géolocalisés.
- `_initLocation()` : tente d’utiliser la géolocalisation si la permission est déjà accordée.
- `_fetchLocation()` : demande la permission si besoin et récupère la position GPS.
- `_onLocationError()` : centralise la gestion d’erreur de géolocalisation.
- `_onMarkerTap(Bien bien)` : sélectionne un bien et ouvre sa fiche.
- `_showBienSheet(Bien bien)` : affiche une bottom sheet de détail rapide.
- `_togglePois()` : charge ou masque les POI.
- `_showPoiSheet(PointOfInterest poi)` : affiche la fiche d’un POI.
- Les autres helpers gèrent le rendu de la carte, des marqueurs et des panneaux inférieurs.

### `lib/screens/profile/profile_screen.dart`
- Imports : `dart:convert`, `CachedNetworkImage`, `Material`, `go_router`, `http`, `intl`, `provider`, `ApiConfig`, `User`, `AuthProvider`, `AppPreferencesService`, `showEditProfileSheet`.
- `ProfileScreen` : écran profil avec onglets.
- `_ProfileHeader` : bloc d’en-tête avec avatar, identité et actions.
- `_TabBarDelegate` : helper de `SliverPersistentHeader` pour garder la TabBar épinglée.
- `_InfosTab`, `_ReservationsTab`, `_ParametresTab` : onglets de profil, réservations et paramètres.
- Les helpers de cet écran organisent l’UI du profil et la navigation vers l’édition.

### `lib/screens/profile/edit_profile_sheet.dart`
- Imports : `Material`, `intl`, `provider`, `User`, `AuthProvider`.
- `showEditProfileSheet()` : ouvre la bottom sheet d’édition du profil.
- `EditProfileSheet` : formulaire d’édition.
- `_pickDate()` : ouvre le date picker pour la date de naissance.
- `_save()` : valide les champs minimaux puis appelle la mise à jour du profil.
- `build()` : rend les champs éditables, les erreurs et les boutons annuler/enregistrer.

### `lib/screens/notifications/notifications_screen.dart`
- Imports : `Material`, `go_router`, `AppNotificationItem`, `AppPreferencesService`, `NotificationService`.
- `NotificationsScreen` : liste des notifications locales générées à partir des réservations et du cache.
- `_loadEnabled()` : lit l’état global des notifications.
- `_reload()` : recharge la source de notifications.
- `_markAll()` : marque tout comme lu.
- `_toggleEnabled()` : met à jour le paramètre utilisateur.
- `_iconFor(String category)` : choisit une icône selon la catégorie de notification.
- `_NotificationCard` : carte individuelle d’une notification.
- `_EmptyState` : écran vide quand aucune notification n’est disponible.

### `lib/screens/auth/login_screen.dart`, `register_screen.dart`, `splash_screen.dart`
- Ces trois écrans gèrent respectivement la connexion, l’inscription et le démarrage.
- Ils s’appuient sur `AuthProvider`, `go_router` et les services d’authentification.

## Notes transverses
- Les fichiers PHP reposent sur des scripts procéduraux et des helpers partagés via `require_once`.
- Les fichiers Dart reposent sur des modèles JSON cohérents avec les réponses PHP.
- Les points d’intégration les plus importants sont `ApiConfig`, `ApiService`, `AuthService`, `BienService`, `ReservationService`, `FavorisService`, `PoiService` et `NotificationService`.
- Le couplage principal entre les deux mondes est le contrat JSON des endpoints PHP et les factories `fromJson()` des modèles Dart.

## Remarques de cohérence
- Les IDs de `Type_Bien` utilisés dans l’UI doivent rester dans l’ordre défini par le SQL du projet.
- Le flux de favoris côté Flutter utilise des appels génériques `GET`/`DELETE` via `ApiService`.
- Les réservations, le profil et l’authentification partagent tous le même schéma JWT.
- Le fichier `lib/screens/home_screen.dart` est le shell de navigation, tandis que `lib/screens/home/home_screen.dart` est l’écran d’accueil avec la liste paginée.
