# 📱 Fiche Technique — HAP Mobile (Flutter)

**Projet :** House After Party — Application Mobile  
**Source :** Conversion de l'application web PHP/MySQL ([Projet_SLAM](https://github.com/Omnous-Luminae/Projet_SLAM))  
**Technologie cible :** Flutter (Dart)  
**Type d'accès :** Local (gratuit, via XAMPP/serveur local)  
**Date :** 2026-03-05  

---

## 📋 Sommaire

1. [Présentation du projet](#1-présentation-du-projet)
2. [Prérequis](#2-prérequis)
3. [Installation & Configuration de Flutter](#3-installation--configuration-de-flutter)
4. [Configuration du backend local (XAMPP)](#4-configuration-du-backend-local-xampp)
5. [Architecture de l'application mobile](#5-architecture-de-lapplication-mobile)
6. [Conversion Web → Mobile : stratégie et correspondances](#6-conversion-web--mobile--stratégie-et-correspondances)
7. [Modules & Écrans Flutter](#7-modules--écrans-flutter)
8. [Communication avec le backend](#8-communication-avec-le-backend)
9. [Gestion des rôles](#9-gestion-des-rôles)
10. [Dictionnaire de données & Relations (schéma SQL)](#10-dictionnaire-de-données--relations-schéma-sql)
11. [Sécurité](#11-sécurité)
12. [Démarrage du projet Flutter](#12-démarrage-du-projet-flutter)

---

## 1. Présentation du projet

**House After Party (HAP)** est une plateforme de location de logements à proximité des lieux festifs. L'application web originale, développée en **PHP 8+ / MySQL 8+ / XAMPP**, est convertie en application mobile Flutter native Android/iOS.

### Objectifs de la conversion

| Objectif | Détail |
|----------|--------|
| Portabilité | Disposer d'une app mobile native Android/iOS |
| Réutilisation du backend | Conserver le serveur PHP/MySQL local existant |
| Accès gratuit | Fonctionnement en local via XAMPP (pas de cloud, pas de frais) |
| UX mobile | Navigation adaptée aux écrans tactiles |
| Modularité | Architecture Flutter en features/modules indépendants |

---

## 2. Prérequis

### Matériel & Système

| Composant | Minimum requis |
|-----------|---------------|
| OS | Windows 10/11 64 bits, macOS 12+, ou Linux Ubuntu 20.04+ |
| RAM | 8 Go (16 Go recommandés) |
| Espace disque | 10 Go libres minimum (Flutter SDK + Android Studio) |
| Processeur | x86_64, Intel ou AMD |

### Logiciels à installer

| Logiciel | Version | Utilisation | Lien |
|----------|---------|-------------|------|
| Flutter SDK | 3.19+ (stable) | Framework mobile | https://flutter.dev/docs/get-started/install |
| Dart SDK | Inclus dans Flutter | Langage de programmation | — |
| Android Studio | Hedgehog 2023.1+ | IDE + émulateur Android | https://developer.android.com/studio |
| VS Code (optionnel) | Dernière version | Éditeur alternatif | https://code.visualstudio.com |
| Git | 2.40+ | Gestion de version | https://git-scm.com |
| XAMPP | 8.2+ | Serveur local PHP/MySQL | https://www.apachefriends.org/fr |
| JDK | 17 (LTS) | Requis pour Android Studio | https://adoptium.net |

---

## 3. Installation & Configuration de Flutter

### 3.1 Téléchargement du SDK Flutter

1. Se rendre sur [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
2. Sélectionner son système d'exploitation (Windows / macOS / Linux)
3. Télécharger l'archive Flutter SDK stable (ex : `flutter_windows_3.x.x-stable.zip`)
4. Extraire dans un dossier **sans espaces ni caractères spéciaux** :
   - ✅ Correct : `C:\dev\flutter`
   - ❌ Éviter : `C:\Program Files\flutter`

### 3.2 Ajout de Flutter au PATH

**Windows :**
```
Panneau de configuration → Système → Variables d'environnement
→ Variable "Path" → Ajouter : C:\dev\flutter\bin
```

**macOS / Linux :**
```bash
export PATH="PATH:`pwd`/flutter/bin"
# Ajouter dans ~/.bashrc ou ~/.zshrc pour rendre permanent
```

### 3.3 Vérification de l'installation

Ouvrir un terminal et exécuter :
```bash
flutter doctor
```

Corriger les éventuels problèmes signalés (✗ rouge) avant de continuer.  
Résultat attendu (tous les éléments en ✓ vert) :
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio (version 2023.x)
[✓] Connected device (1 available)
[✓] Network resources
```

### 3.4 Installation d'Android Studio

1. Télécharger et installer Android Studio
2. Au premier démarrage, suivre l'assistant de configuration (Android SDK sera téléchargé automatiquement)
3. Installer les plugins Flutter et Dart :
   - `File → Settings → Plugins → Marketplace`
   - Rechercher **Flutter** → Installer (Dart s'installera automatiquement)

### 3.5 Configuration d'un émulateur Android

1. Dans Android Studio : `Tools → Device Manager → Create Device`
2. Choisir un appareil : **Pixel 6** (recommandé)
3. Choisir une image système : **API 33 (Android 13)** ou supérieur
4. Valider et démarrer l'émulateur

> 💡 Il est également possible de tester sur un appareil physique Android en activant le **Mode développeur** et le **Débogage USB**.

### 3.6 Création du projet Flutter

```bash
flutter create hap_mobile
cd hap_mobile
flutter run
```

Pour spécifier les plateformes cibles :
```bash
flutter create --platforms=android hap_mobile
```

---

## 4. Configuration du backend local (XAMPP)

L'application mobile communique avec le backend **PHP/MySQL** existant du projet HAP via des requêtes HTTP locales. Aucun hébergement externe n'est nécessaire : **tout fonctionne gratuitement en local**.

### 4.1 Démarrage du serveur

1. Ouvrir le **Panneau de contrôle XAMPP**
2. Démarrer **Apache** et **MySQL**
3. Vérifier que le projet HAP est bien dans : `C:\xampp\htdocs\HAP\`

### 4.2 Accès depuis l'émulateur Android

L'émulateur Android ne peut pas accéder à `localhost` directement. Il faut utiliser l'adresse IP de la machine hôte :

| Contexte | Adresse à utiliser |
|----------|-------------------|
| Émulateur Android | `http://10.0.2.2` |
| Appareil physique (même réseau Wi-Fi) | IP locale de la machine, ex: `http://192.168.1.X` |

Exemple dans le code Flutter :
```dart
const String baseUrl = 'http://10.0.2.2/HAP/Projet_HAP(House_After_Party)/api';
```

### 4.3 Configuration CORS dans PHP

Pour autoriser les requêtes depuis l'app Flutter, ajouter en tête de chaque fichier API PHP :

```php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
```

> Il est recommandé de centraliser ces en-têtes dans un fichier `config/cors.php` inclus dans tous les endpoints API.

---

## 5. Architecture de l'application mobile

### 5.1 Structure des dossiers Flutter

```
hap_mobile/
├── lib/
│   ├── main.dart                  # Point d'entrée
│   ├── core/
│   │   ├── constants/             # Constantes (URLs, couleurs, textes)
│   │   ├── services/              # Services HTTP (ApiService)
│   │   ├── models/                # Modèles de données (Dart)
│   │   └── utils/                 # Fonctions utilitaires
│   ├── features/
│   │   ├── auth/                  # Authentification (login, inscription)
│   │   ├── accueil/               # Page d'accueil
│   │   ├── annonces/              # Liste et détail des logements
│   │   ├── reservation/           # Réservation et calendrier
│   │   ├── favoris/               # Favoris utilisateur
│   │   ├── avis/                  # Avis et blog
│   │   ├── profil/                # Profil utilisateur
│   │   ├── support/               # Tickets de support
│   │   ├── carte/                 # Carte interactive
│   │   └── admin/                 # Dashboard administrateur
│   └── shared/
│       ├── widgets/               # Widgets réutilisables
│       └── themes/                # Thème clair/sombre
├── android/                       # Config Android native
├── assets/                        # Images, polices, icônes
└── pubspec.yaml                   # Dépendances Flutter
```

### 5.2 Dépendances principales (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Requêtes HTTP vers le backend PHP
  http: ^1.2.0
  dio: ^5.4.0

  # Gestion de l'état
  provider: ^6.1.2
  # ou : flutter_riverpod: ^2.5.1

  # Navigation
  go_router: ^13.2.0

  # Stockage local (session utilisateur, token)
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Carte interactive
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # Calendrier de réservation
  table_calendar: ^3.1.1

  # UI & Icônes
  flutter_svg: ^2.0.10
  cached_network_image: ^3.3.1

  # Thème clair/sombre
  # (natif Flutter via ThemeMode)
```

---

## 6. Conversion Web → Mobile : stratégie et correspondances

### 6.1 Principe général

L'application web HAP utilise un rendu **côté serveur (PHP)** avec des pages HTML générées dynamiquement. La version mobile Flutter adopte une architecture **client léger** :

- Le **backend PHP** reste inchangé et expose ses fonctionnalités via les **endpoints API existants** (dossier `api/`)
- Le **frontend Flutter** consomme ces endpoints en JSON et gère l'affichage nativement
- La **base de données MySQL** (`project_hap`) reste identique, hébergée sur XAMPP

### 6.2 Tableau de correspondance Pages Web → Écrans Flutter

| Page Web (PHP) | Fichier source | Écran Flutter | Widget principal |
|----------------|---------------|---------------|-----------------|
| Accueil | `index.php` | `AccueilScreen` | `ListView`, `CarouselSlider` |
| Annonces | `forms/Annonce.form.php` | `AnnoncesScreen` | `GridView`, filtres `FilterChip` |
| Détail annonce | `forms/annonce_detail.php` | `DetailAnnonceScreen` | `PageView`, `ImageSlider` |
| Carte interactive | `map.php` | `CarteScreen` | `FlutterMap` + `Marker` |
| Points d'intérêt | `forms/PtsInteret.form.php` | Intégré à `CarteScreen` | `Marker` colorisés |
| Détail point d'intérêt | `forms/pts_interet_detail.php` | `PtsInteretDetailScreen` | `DetailCard` |
| Blog / Avis | `forms/blog.php` | `AvisScreen` | `ListView`, `RatingBar` |
| Réservation | `forms/annonce_detail.php` + `api/update_reservation.php` | `ReservationScreen` | `TableCalendar`, `DateRangePicker` |
| Profil | `auth/profile.php` | `ProfilScreen` | `UserInfoCard`, `HistoriqueList` |
| Favoris | `forms/mes_favoris.php` | `FavorisScreen` | `GridView` avec `FavoriCard` |
| Contact / Support | `contact.php` + `forms/manage_contacts.php` | `SupportScreen` | `Form`, `TicketCard` |
| Connexion | `auth/connexion.php` | `LoginScreen` | `TextFormField`, `ElevatedButton` |
| Inscription | `auth/inscription.php` | `InscriptionScreen` | `Stepper`, `Form` |
| Mot de passe oublié | `auth/forgot_password.php` | `ForgotPasswordScreen` | `TextFormField` |
| Réinitialisation MDP | `auth/reset_password.php` | `ResetPasswordScreen` | `TextFormField` |
| Dashboard admin | `apropos.php` + `forms/dashboard.php` | `AdminDashboardScreen` | `StatCard`, `DataTable` |
| Gestion biens | `forms/Bien.form.php` | `GestionBiensScreen` | `CRUD ListView` |
| Validation biens | `forms/validate_biens.php` | `ValidationBiensScreen` | `ReviewCard` |
| Validation avis | `forms/validate_reviews.php` | `ValidationAvisScreen` | `ReviewCard` |
| Gestion utilisateurs | `forms/Locataires.form.php` | `GestionUsersScreen` | `DataTable` |
| Gestion réservations | `forms/Reservation.form.php` | `GestionReservationsScreen` | `FilteredDataTable` |
| Gestion événements | `forms/Evenement.form.php` | `GestionEvenementsScreen` | `CRUD ListView` |
| Gestion tarifs | `forms/Tarif.form.php` + `forms/manage_tarifs.php` | `GestionTarifsScreen` | `DataTable` |
| Gestion saisons | `forms/Saison.form.php` | `GestionSaisonsScreen` | `CRUD ListView` |
| Gestion prestations | `forms/Prestation.form.php` + `forms/Compose.form.php` | `GestionPrestationsScreen` | `CRUD ListView` |
| Gestion communes | `forms/Commune.form.php` | `GestionCommunesScreen` | `CRUD ListView` |
| Archives | `forms/manage_archives.php` | `ArchivesScreen` | `FilteredList` |
| Tickets support (admin) | `forms/manage_contacts.php` | `GestionContactsScreen` | `TicketCard`, réponse admin |
| Thème clair/sombre | `theme_toggle.php` | Switch dans `ProfilScreen` | `Switch`, `ThemeMode` |

### 6.3 Gestion du thème clair/sombre

Le thème était géré côté serveur PHP via `localStorage` JS. En Flutter, il est géré nativement :

```dart
// Dans main.dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ref.watch(themeModeProvider), // Provider/Riverpod
);
```

---

## 7. Modules & Écrans Flutter

### 7.1 Authentification

#### 🔐 `LoginScreen` (`auth/connexion.php` → `api/login.php`)

**Fonctionnalités :**
- Formulaire email + mot de passe avec token CSRF géré côté PHP
- Protection anti-brute force : l'API retourne un statut de blocage après 5 tentatives infructueuses (blocage 15 min)
- Message contextuel si redirection depuis une tentative de réservation sans connexion
- Persistance de session via `shared_preferences` (token/user_id)
- Régénération de l'ID de session côté PHP à chaque connexion réussie
- Navigation vers `InscriptionScreen` et `ForgotPasswordScreen`
- Navigation automatique vers l'écran précédent après connexion réussie

**Widgets :** `TextFormField`, `ElevatedButton`, `SnackBar`  
**API :** `POST api/login.php`

---

#### 📝 `InscriptionScreen` (`auth/inscription.php`)

**Fonctionnalités :**
- Formulaire multi-étapes avec `Stepper` :
  - **Étape 1** : Choix du type de compte (particulier / entreprise)
  - **Étape 2** : Informations personnelles (nom, prénom, email, téléphone, date de naissance)
  - **Étape 3** : Adresse avec autocomplete via API `adresse.data.gouv.fr`
  - **Étape 4** : Pour les entreprises — saisie SIRET avec validation algorithme de Luhn
  - **Étape 5** : Mot de passe conforme CNIL (min. 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial)
- Vérification de la majorité (18+ ans) via calcul de date de naissance
- Captcha mathématique anti-bot (question simple générée côté PHP, validée côté serveur)
- Acceptation RGPD obligatoire (case à cocher)
- Protection anti-spam : blocage de l'IP après trop de tentatives
- Token CSRF pour sécuriser la soumission

**Widgets :** `Stepper`, `TextFormField`, `DropdownButton`, `Checkbox`  
**API :** `POST api/register.php`, `GET adresse.data.gouv.fr`, API SIREN

---

#### 🔑 `ForgotPasswordScreen` (`auth/forgot_password.php`)

**Fonctionnalités :**
- Saisie de l'adresse email
- Appel API → vérification existence du compte (réponse générique pour éviter l'énumération)
- Génération d'un token sécurisé côté PHP (valide 1 heure)
- En mode local XAMPP : affichage direct du lien de réinitialisation dans l'app
- Navigation vers `ResetPasswordScreen` avec le token

**API :** `POST api/forgot_password.php`

---

#### 🔓 `ResetPasswordScreen` (`auth/reset_password.php`)

**Fonctionnalités :**
- Saisie du nouveau mot de passe + confirmation
- Validation : longueur min. 8 caractères, correspondance des deux champs
- Vérification du token côté PHP (SHA-256, expiration 1h)
- Hash bcrypt du nouveau mot de passe côté PHP
- Suppression du token après utilisation
- Message de succès + redirection vers `LoginScreen`

**API :** `POST api/reset_password.php`

---

### 7.2 Accueil

#### 🏠 `AccueilScreen` (`index.php`)

**Fonctionnalités :**
- Hero banner avec slogan « Avec nous les soirées peuvent s'arroser »
- Boutons CTA :
  - « Voir les logements » → `AnnoncesScreen`
  - « Événements à proximité » → `EvenementsScreen`
- Carrousel de biens en avant (derniers biens ajoutés / mis en avant)
- Menu de navigation adaptatif selon le rôle :
  - Visiteur : Accueil, Annonces, Carte, Points d'intérêt, Blog
  - Utilisateur connecté : + Profil, Favoris
  - Admin : + Dashboard Admin
- Bouton de connexion / déconnexion dans l'`AppBar`
- Message de bienvenue avec le prénom de l'utilisateur si connecté
- Support thème clair/sombre (switch accessible depuis `ProfilScreen`)

**Widgets :** `CarouselSlider`, `ListView`, `AppBar`, `ElevatedButton`

---

### 7.3 Annonces & Recherche

#### 📋 `AnnoncesScreen` (`forms/Annonce.form.php`)

**Fonctionnalités :**
- Liste des biens disponibles affichée en `GridView` ou `ListView`
- **Filtres combinés** :
  - Prix (min / max)
  - Capacité (nombre de personnes)
  - Type de bien (appartement, maison, studio…)
  - Équipements / prestations
  - Commune (autocomplete via `api/search_communes.php`)
- Recherche textuelle avec autocomplete (`api/search_biens.php`)
- Galerie d'aperçu pour chaque bien (`cached_network_image`)
- Bouton cœur ❤️ pour ajouter/retirer des favoris (`api/favoris.php`, nécessite connexion)
- Navigation vers `DetailAnnonceScreen` au clic sur un bien

**Widgets :** `GridView`, `FilterChip`, `SearchBar`, `CachedNetworkImage`  
**API :** `GET api/search_biens.php`, `GET api/search_communes.php`, `POST api/favoris.php`

---

#### 🏡 `DetailAnnonceScreen` (`forms/annonce_detail.php`)

**Fonctionnalités :**
- Galerie d'images du bien en swipe (`PageView`)
- Informations complètes : titre, description, prix/nuit, capacité, type, adresse
- **Calendrier de disponibilité** (`TableCalendar`) :
  - Dates déjà réservées bloquées (`api/get_availability.php`)
  - Semaines spéciales (indisponibles) colorées en rouge (`api/get_reservations_bien.php`)
  - Date minimale de sélection = aujourd'hui
- **Calcul automatique du tarif** selon la plage sélectionnée :
  - Tarif de base (prix/nuit × nb nuits)
  - Modificateur saisonnier (`api/get_tarifs_week.php`)
  - Affichage du détail du coût (`api/calculate_reservation_cost.php`)
- Liste des avis / notes ⭐ du bien
- Bouton « Ajouter aux favoris » (toggle ❤️)
- Bouton « Réserver » :
  - Redirige vers `LoginScreen` si non connecté (avec message contextuel)
  - Ouvre `ReservationScreen` si connecté

**Widgets :** `PageView`, `TableCalendar`, `RatingBar`, `ElevatedButton`  
**API :** `GET api/get_bien.php`, `GET api/get_availability.php`, `GET api/get_reservations_bien.php`, `GET api/get_tarifs_week.php`, `POST api/calculate_reservation_cost.php`

---

### 7.4 Réservation

#### 📅 `ReservationScreen` (`api/update_reservation.php`)

**Fonctionnalités :**
- Sélection de la plage de dates avec `TableCalendar` (date de début + date de fin)
- Blocage dynamique des dates indisponibles (déjà réservées ou semaines spéciales)
- Date minimale = aujourd'hui (pas de réservation dans le passé)
- Calcul automatique du montant total :
  - Tarif de base × nombre de nuits
  - Application des modificateurs saisonniers ou de semaines spéciales
- **Récapitulatif** avant confirmation : bien, dates, montant total
- Confirmation → appel `POST api/update_reservation.php`
- Affichage du succès + navigation vers `ProfilScreen` (historique)
- Annulation possible depuis `ProfilScreen`

**Widgets :** `TableCalendar`, `Card`, `ElevatedButton`  
**API :** `GET api/get_availability.php`, `GET api/get_tarifs_week.php`, `POST api/calculate_reservation_cost.php`, `POST api/update_reservation.php`

---

### 7.5 Carte Interactive

#### 🗺️ `CarteScreen` (`map.php`)

**Fonctionnalités :**
- Carte OpenStreetMap via `FlutterMap` (gratuit, sans clé API)
- **Couche biens** : marqueurs colorisés selon le type de bien, cliquables
- **Couche points d'intérêt** : marqueurs distinctifs (clubs 🎵, bars 🍺, restaurants 🍽️…) en superposition (`api/get_poi.php`)
- Clic sur un marqueur de bien → fiche résumée (titre, prix, note) avec bouton vers `DetailAnnonceScreen`
- Clic sur un marqueur POI → fiche résumée avec bouton vers `PtsInteretDetailScreen`
- Centrage automatique sur la position de l'utilisateur (si permission accordée)

**Widgets :** `FlutterMap`, `MarkerLayer`, `Marker`, `BottomSheet`  
**API :** `GET api/get_poi.php`, `GET api/search_biens.php`

---

#### 📍 `PtsInteretDetailScreen` (`forms/pts_interet_detail.php`)

**Fonctionnalités :**
- Affichage des informations du point d'intérêt : nom, type, adresse, coordonnées GPS
- Liste des biens à proximité du point d'intérêt
- Navigation vers `DetailAnnonceScreen` pour chaque bien listé

**Widgets :** `DetailCard`, `ListView`

---

### 7.6 Favoris

#### ❤️ `FavorisScreen` (`forms/mes_favoris.php`)

**Fonctionnalités :**
- Affichage des biens mis en favoris par l'utilisateur connecté
- `GridView` avec `FavoriCard` (image, titre, prix/nuit, note)
- Suppression d'un favori via bouton cœur (toggle `api/favoris.php`)
- Navigation vers `DetailAnnonceScreen` au clic sur une carte
- Message « Aucun favori » si la liste est vide
- Accessible uniquement si connecté

**Widgets :** `GridView`, `FavoriCard`, `IconButton`  
**API :** `GET api/favoris.php`, `POST api/favoris.php`

---

### 7.7 Avis & Blog

#### 📝 `AvisScreen` (`forms/blog.php`)

**Fonctionnalités :**
- Liste des avis publiés (validés par l'admin) avec note ⭐ (1 à 5), commentaire, date, auteur
- Filtres : par bien, par note minimale
- Pagination de la liste
- **Soumission d'un avis** (utilisateur connecté uniquement) :
  - Sélection du bien concerné parmi les biens réservés par l'utilisateur
  - Note de 1 à 5 étoiles (`RatingBar`)
  - Commentaire libre
  - Les avis soumis sont **en attente de validation admin** avant publication
- Message informatif si aucun avis disponible

**Widgets :** `ListView`, `RatingBar`, `TextFormField`, `DropdownButton`  
**API :** `GET api/get_avis.php`, `POST api/submit_avis.php`

---

### 7.8 Profil

#### 👤 `ProfilScreen` (`auth/profile.php`)

**Fonctionnalités :**
- Affichage des informations personnelles de l'utilisateur connecté
- **Modification du profil** :
  - Champs : nom, prénom, email, téléphone, date de naissance, adresse, commune
  - Autocomplete adresse via `adresse.data.gouv.fr`
  - Acceptation RGPD obligatoire pour toute modification
  - Validation de tous les champs obligatoires avant soumission
- **Changement de mot de passe** :
  - Vérification de l'ancien mot de passe
  - Saisie + confirmation du nouveau mot de passe
  - Validation : les deux champs doivent correspondre
- **Historique des réservations** de l'utilisateur :
  - Statuts : en attente, confirmée, annulée, archivée
  - Annulation d'une réservation en cours (bouton dédié)
- **Switch thème clair/sombre** (persisté via `shared_preferences`)
- Bouton de déconnexion

**Widgets :** `UserInfoCard`, `ListView`, `Switch`, `TextFormField`, `ElevatedButton`  
**API :** `GET api/get_profil.php`, `POST api/update_profil.php`, `GET api/get_reservations.php`, `DELETE api/delete_reservation.php`

---

### 7.9 Support

#### 🎫 `SupportScreen` (`contact.php`)

**Fonctionnalités :**
- Formulaire de création de ticket :
  - **Type** : question / signalement / erreur / suggestion / autre
  - **Sujet** : champ texte court
  - **Message** : champ texte long
  - **Priorité** : basse / normale / haute / urgente
  - **Page concernée** : champ optionnel
- Si connecté : email et nom pré-remplis depuis la session
- Si non connecté : saisie email obligatoire avec validation `filter_var`
- Numéro de ticket affiché après soumission (ex: `#000042`)
- Tous les champs obligatoires (type, sujet, message) vérifiés avant envoi

**Widgets :** `Form`, `DropdownButton`, `TextFormField`, `ElevatedButton`, `SnackBar`  
**API :** `POST api/manage_contacts.php`

---

### 7.10 Dashboard Admin

#### 🛠️ `AdminDashboardScreen` (`apropos.php` + `forms/dashboard.php`)

**Fonctionnalités :**
- **Accès restreint** au rôle Administrateur (rôle `animateur` côté PHP), vérification côté serveur à chaque requête
- Statistiques globales en cards :
  - Nombre d'utilisateurs inscrits
  - Nombre de réservations (totales / en cours / archivées)
  - Nombre d'avis (publiés / en attente de validation)
  - Nombre de tickets support (ouverts / en cours / fermés)
- Navigation rapide vers tous les sous-modules de gestion

**API :** `GET api/dashboard_stats.php`

---

#### 🏠 `GestionBiensScreen` (`forms/Bien.form.php`)

**Fonctionnalités :**
- Liste complète de tous les biens (validés et en attente)
- **CRUD complet** : créer, afficher, modifier, supprimer un bien
- Champs : titre, description, prix/nuit, capacité, type de bien, adresse (autocomplete `adresse.data.gouv.fr`), coordonnées GPS, photos
- Upload multi-photos (ajout dynamique de lignes de photo)
- Liaison aux prestations (`Compose.form.php`) et points d'intérêt (`Dispose.form.php`)
- Filtre par statut (validé / en attente)

**API :** `GET/POST/PUT/DELETE api/bien.php`

---

#### ✅ `ValidationBiensScreen` (`forms/validate_biens.php`)

**Fonctionnalités :**
- Liste des biens en attente de validation soumis par des propriétaires
- Aperçu complet du bien (photos, description, adresse, prix)
- Actions : **Valider** (publier) ou **Refuser** (avec motif)
- Notification au propriétaire après décision

**API :** `POST api/validate_biens.php`

---

#### 🎭 `ValidationAvisScreen` (`forms/validate_reviews.php`)

**Fonctionnalités :**
- Liste des avis en attente de modération
- Affichage : auteur, note ⭐, commentaire, date, bien concerné
- Actions : **Valider** (publier l'avis) ou **Refuser** (supprimer l'avis)

**API :** `POST api/validate_reviews.php`

---

#### 👥 `GestionUsersScreen` (`forms/Locataires.form.php`)

**Fonctionnalités :**
- Liste paginée de tous les utilisateurs
- **CRUD complet** : créer, modifier, supprimer un utilisateur
- Bascule type de compte : **particulier** (nom, prénom, email, téléphone, date de naissance, adresse) / **entreprise** (SIRET, raison sociale)
- Validation SIREN avec algorithme de Luhn
- Vérification de la majorité (18+ ans) à la création
- Recherche par nom, prénom ou email (`api/search_locataires.php`)
- Modification de l'état du compte (actif / bloqué)
- Modal d'édition avec tous les champs pré-remplis

**Widgets :** `DataTable`, `AlertDialog`, `DropdownButton`  
**API :** `GET api/search_locataires.php`, `GET/POST/PUT/DELETE api/locataire.php`

---

#### 📋 `GestionReservationsScreen` (`forms/Reservation.form.php`)

**Fonctionnalités :**
- Vue globale de toutes les réservations (tous utilisateurs)
- **Filtres** : nom de bien, date de début, date de fin, nombre minimum de réservations, statut
- Modification du statut d'une réservation (en attente → confirmée → annulée → archivée)
- Calcul et affichage du montant total
- Navigation vers l'historique par utilisateur

**API :** `GET api/get_reservations.php`, `PUT api/update_reservation.php`

---

#### 🎉 `GestionEvenementsScreen` (`forms/Evenement.form.php`)

**Fonctionnalités :**
- **CRUD complet** des événements (concerts, festivals, soirées…)
- Champs : nom, type d'événement, date, adresse, description
- **CRUD des types d'événements** (`forms/TypeEvenement.form.php`)
- Liaison des événements aux points d'intérêt

**API :** `GET/POST/PUT/DELETE api/evenement.php`

---

#### 📍 `GestionPtsInteretScreen` (`forms/PtsInteret.form.php`)

**Fonctionnalités :**
- **CRUD complet** des points d'intérêt (clubs, bars, restaurants…)
- Champs : nom, type de POI, adresse, coordonnées GPS (latitude/longitude)
- **CRUD des types de POI** (`forms/TypePtsInteret.form.php`)
- Liaison POI ↔ biens (`forms/Dispose.form.php`)
- Aperçu sur carte intégrée

**API :** `GET api/get_poi.php`, `GET/POST/PUT/DELETE api/pts_interet.php`

---

#### 💰 `GestionTarifsScreen` (`forms/Tarif.form.php` + `forms/manage_tarifs.php`)

**Fonctionnalités :**
- **CRUD des tarifs** associés à un bien :
  - Tarif de base par nuit
  - Modificateur de prix par saison (multiplicateur, ex: 1.5 pour +50%)
  - Semaines spéciales (prix fixe ou multiplicateur)
- Visualisation du calendrier tarifaire par bien

**API :** `GET api/get_tarifs_week.php`, `GET/POST/PUT/DELETE api/tarif.php`

---

#### 📆 `GestionSaisonsScreen` (`forms/Saison.form.php`)

**Fonctionnalités :**
- **CRUD des saisons tarifaires** par bien
- Champs : nom de la saison (ex: « Été 2026 »), date de début, date de fin, modificateur de prix
- Vérification de la cohérence des dates (pas de chevauchement)

**API :** `GET/POST/PUT/DELETE api/saison.php`

---

#### 🛎️ `GestionPrestationsScreen` (`forms/Prestation.form.php` + `forms/Compose.form.php`)

**Fonctionnalités :**
- **CRUD des prestations** (Wi-Fi, parking, piscine, cuisine équipée…)
- Liaison prestation ↔ bien (`Compose.form.php`) : ajouter/retirer des équipements à un bien
- Recherche de prestations disponibles (`api/search_composition.php`)

**API :** `GET api/search_composition.php`, `GET/POST/DELETE api/prestation.php`

---

#### 🏘️ `GestionCommunesScreen` (`forms/Commune.form.php`)

**Fonctionnalités :**
- **CRUD des communes** référencées dans l'application
- Champs : nom, code INSEE, département
- Utilisé pour le filtre de recherche des biens et l'autocomplete d'adresse
- Intégration API `api/get_commune_by_insee.php`

**API :** `GET api/get_commune_by_insee.php`, `GET api/search_communes.php`

---

#### 📦 `ArchivesScreen` (`forms/manage_archives.php`)

**Fonctionnalités :**
- Liste des réservations archivées (statut `archivée`)
- Filtres : bien, utilisateur, période de dates
- Affichage détaillé : bien réservé, locataire, dates, montant, date d'archivage
- Consultation des détails via `api/get_archive_details.php`
- Export possible (à implémenter)

**API :** `GET api/get_archive_details.php`

---

#### 📬 `GestionContactsScreen` (`forms/manage_contacts.php`)

**Fonctionnalités :**
- Liste de tous les tickets support soumis par les utilisateurs
- **Filtres** : par statut (ouvert / en cours / fermé), par priorité, par type
- Affichage : sujet, message, priorité, page concernée, date de soumission, auteur
- **Réponse de l'admin** : champ de texte pour rédiger une réponse
- Changement de statut du ticket (ouvert → en cours → fermé)
- Mise en évidence des tickets urgents / haute priorité

**API :** `GET/POST api/manage_contacts.php`

---

## 8. Communication avec le backend

### 8.1 Service HTTP centralisé

```dart
// lib/core/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2/HAP/Projet_HAP(House_After_Party)/api';

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('
$baseUrl/$endpoint'),
      headers: headers,
    );
    return json.decode(response.body);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('
$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
    return json.decode(response.body);
  }
}
```

### 8.2 Endpoints API utilisés

| Action | Méthode | Endpoint PHP existant |
|--------|---------|----------------------|
| Connexion | POST | `api/login.php` |
| Inscription | POST | `api/register.php` |
| Mot de passe oublié | POST | `api/forgot_password.php` |
| Réinitialisation MDP | POST | `api/reset_password.php` |
| Liste des biens | GET | `api/search_biens.php` |
| Détail d'un bien | GET | `api/get_bien.php?id=X` |
| Favoris (liste / toggle) | GET/POST | `api/favoris.php` |
| Réservation | POST | `api/update_reservation.php` |
| Disponibilités | GET | `api/get_availability.php?bien_id=X` |
| Réservations par bien | GET | `api/get_reservations_bien.php?bien_id=X` |
| Réservations utilisateur | GET | `api/get_reservations.php` |
| Calcul coût réservation | POST | `api/calculate_reservation_cost.php` |
| Tarifs par semaine | GET | `api/get_tarifs_week.php?bien_id=X` |
| Liste avis | GET | `api/get_avis.php?bien_id=X` |
| Soumettre avis | POST | `api/submit_avis.php` |
| Valider avis (admin) | POST | `api/validate_reviews.php` |
| Valider bien (admin) | POST | `api/validate_biens.php` |
| Tickets support | GET/POST | `api/manage_contacts.php` |
| Points d'intérêt | GET | `api/get_poi.php` |
| Détail archive | GET | `api/get_archive_details.php` |
| Dashboard stats | GET | `api/dashboard_stats.php` |
| Recherche communes | GET | `api/search_communes.php` |
| Commune par INSEE | GET | `api/get_commune_by_insee.php` |
| Recherche locataires | GET | `api/search_locataires.php` |
| Recherche composition | GET | `api/search_composition.php` |

---

## 9. Gestion des rôles

L'application gère 4 rôles, identiques à l'application web :

| Rôle | Accès |
|------|-------|
| **Visiteur** | Accueil, annonces, carte, points d'intérêt, blog (lecture seule) |
| **Utilisateur** | + Réservation (connexion requise), favoris, soumettre un avis, profil, support |
| **Propriétaire** | + Gestion de ses biens, calendrier, suivi réservations |
| **Administrateur** (`animateur`) | + Dashboard complet, validation biens/avis, modération, archives, gestion contacts |

Le rôle est retourné lors de la connexion et stocké localement. La navigation Flutter adapte les menus et les accès selon le rôle. **La vérification des permissions est toujours effectuée côté serveur PHP** à chaque requête API.

---

## 10. Dictionnaire de données & Relations (schéma SQL)

Le schéma de base de données MySQL (`project_hap`) reste identique à celui de l'application web. Les tables principales et leurs champs sont décrits ci-dessous.

### Tables principales

#### `utilisateurs`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `nom` | VARCHAR(100) | Nom de famille |
| `prenom` | VARCHAR(100) | Prénom |
| `email` | VARCHAR(150) | Email (unique) |
| `mot_de_passe` | VARCHAR(255) | Hash bcrypt |
| `role` | ENUM('visiteur','utilisateur','proprietaire','admin') | Rôle dans l'application |
| `valide` | TINYINT(1) | Compte validé par admin |
| `date_inscription` | DATETIME | Date de création du compte |
| `tentatives_connexion` | INT | Compteur anti brute-force |
| `bloque_jusqu` | DATETIME | Blocage temporaire |

#### `biens`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `titre` | VARCHAR(200) | Titre de l'annonce |
| `description` | TEXT | Description détaillée |
| `prix_nuit` | DECIMAL(10,2) | Prix par nuit |
| `capacite` | INT | Nombre de personnes max |
| `type` | VARCHAR(50) | Type de logement (appartement, maison...) |
| `adresse` | VARCHAR(255) | Adresse complète |
| `latitude` | DECIMAL(10,7) | Coordonnée GPS |
| `longitude` | DECIMAL(10,7) | Coordonnée GPS |
| `proprietaire_id` | INT (FK) | Référence à `utilisateurs.id` |
| `valide` | TINYINT(1) | Validé par admin |
| `date_creation` | DATETIME | Date d'ajout |

#### `reservations`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `bien_id` | INT (FK) | Référence à `biens.id` |
| `locataire_id` | INT (FK) | Référence à `utilisateurs.id` |
| `date_debut` | DATE | Date d'arrivée |
| `date_fin` | DATE | Date de départ |
| `montant_total` | DECIMAL(10,2) | Montant calculé |
| `statut` | ENUM('en_attente','confirmee','annulee','archivee') | État de la réservation |
| `date_reservation` | DATETIME | Date de création |

#### `avis`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `bien_id` | INT (FK) | Référence à `biens.id` |
| `auteur_id` | INT (FK) | Référence à `utilisateurs.id` |
| `note` | TINYINT | Note de 1 à 5 |
| `commentaire` | TEXT | Texte de l'avis |
| `valide` | TINYINT(1) | Validé par admin avant publication |
| `date_avis` | DATETIME | Date de soumission |

#### `favoris`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `utilisateur_id` | INT (FK) | Référence à `utilisateurs.id` |
| `bien_id` | INT (FK) | Référence à `biens.id` |
| `date_ajout` | DATETIME | Date d'ajout aux favoris |

#### `tickets_support`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `utilisateur_id` | INT (FK, nullable) | Référence à `utilisateurs.id` |
| `sujet` | VARCHAR(200) | Sujet du ticket |
| `message` | TEXT | Contenu du message |
| `priorite` | ENUM('basse','normale','haute','urgente') | Priorité |
| `statut` | ENUM('ouvert','en_cours','ferme') | État du ticket |
| `reponse` | TEXT | Réponse de l'admin |
| `date_creation` | DATETIME | Date d'ouverture |

#### `points_interet`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `nom` | VARCHAR(150) | Nom du lieu |
| `type` | VARCHAR(50) | Type (club, bar, restaurant...) |
| `latitude` | DECIMAL(10,7) | Coordonnée GPS |
| `longitude` | DECIMAL(10,7) | Coordonnée GPS |
| `adresse` | VARCHAR(255) | Adresse |

#### `saisons_tarifs`
| Champ | Type | Description |
|-------|------|-------------|
| `id` | INT (PK, AUTO) | Identifiant unique |
| `bien_id` | INT (FK) | Référence à `biens.id` |
| `nom_saison` | VARCHAR(100) | Ex: "Été 2026" |
| `date_debut` | DATE | Début de la période |
| `date_fin` | DATE | Fin de la période |
| `modificateur_prix` | DECIMAL(5,2) | Multiplicateur de prix (ex: 1.5 pour +50%) |

### Relations entre tables

```
ul utilisateurs ──< biens             (un propriétaire possède plusieurs biens)
utilisateurs ──< reservations      (un utilisateur fait plusieurs réservations)
biens        ──< reservations      (un bien a plusieurs réservations)
ul utilisateurs ──< avis              (un utilisateur écrit plusieurs avis)
biens        ──< avis              (un bien reçoit plusieurs avis)
ul utilisateurs ──< favoris           (un utilisateur a plusieurs favoris)
biens        ──< favoris           (un bien peut être dans plusieurs listes de favoris)
ul utilisateurs ──< tickets_support   (un utilisateur ouvre plusieurs tickets)
biens        ──< saisons_tarifs    (un bien a plusieurs périodes tarifaires)
```

---

## 11. Sécurité

| Aspect | Solution retenue |
|--------|-----------------|
| Authentification | Token de session PHP + stockage `shared_preferences` |
| Mots de passe | Hash bcrypt côté PHP (inchangé) — min. 8 car., maj., min., chiffre, spécial |
| Anti brute-force connexion | Blocage IP après 5 tentatives (15 min) — géré PHP-side |
| Anti brute-force inscription | Blocage IP après trop de tentatives — géré PHP-side |
| Captcha inscription | Question mathématique simple, validée côté serveur |
| Réinitialisation MDP | Token SHA-256 valide 1h, supprimé après usage |
| Protection CSRF | Token CSRF validé côté PHP à chaque soumission de formulaire |
| Accès réseau | Local uniquement (XAMPP), pas d'exposition Internet |
| Rôles & permissions | Vérification côté serveur PHP à chaque requête API |
| Données sensibles | Jamais stockées en clair côté mobile |
| Majorité | Vérification 18+ ans à l'inscription (côté PHP) |
| RGPD | Consentement obligatoire à l'inscription et à la modification du profil |
| Admin | Accès via clé secrète + contrôle IP (en option), session 24h |

---

## 12. Démarrage du projet Flutter

### Lancement complet (première fois)

```bash
# 1. Cloner le dépôt mobile
git clone https://github.com/Omnous-Luminae/HAP_Mobile.git
cd HAP_Mobile

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Démarrer XAMPP (Apache + MySQL)
#    → Vérifier que le projet HAP web est dans C:\xampp\htdocs\HAP\

# 4. Lancer l'émulateur Android depuis Android Studio ou via :
flutter emulators --launch <nom_emulateur>

# 5. Lancer l'application
flutter run

# Pour un build Android (APK de debug)
flutter build apk --debug
```

### Commandes utiles

| Commande | Utilité |
|----------|---------|
| `flutter doctor` | Vérifier l'environnement |
| `flutter pub get` | Installer les dépendances |
| `flutter run` | Lancer l'app sur l'émulateur/appareil |
| `flutter hot reload` (r dans le terminal) | Recharger sans redémarrer |
| `flutter hot restart` (R dans le terminal) | Redémarrer l'app |
| `flutter build apk` | Générer l'APK de production |
| `flutter clean` | Nettoyer le cache de build |
| `flutter test` | Lancer les tests unitaires |
```

*Fiche technique mise à jour le 2026-03-05 — Projet HAP Mobile (Flutter) — Accès local gratuit via XAMPP*