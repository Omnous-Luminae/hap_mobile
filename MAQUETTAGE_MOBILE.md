# 📱 Maquettages Mobile — House After Party (HAP)

> **Format cible** : 390×844px (iPhone 14 / Android standard)
> **Framework** : Flutter (Dart)
> **Palette** : Violet principal `#a100b8` · Fond clair `#f5f5f5` · Fond sombre `#1e1e1e` · Accent `#3d0066`
> **Typographie** : Montserrat (Google Fonts)
> **Thème** : Clair ☀️ / Sombre 🌙 — bouton flottant fixe en bas à droite (toutes pages)
> **Géolocalisation** : `geolocator` + `permission_handler` (Flutter packages)

---

## 🗺️ Navigation globale — Structure de l'app

```
HAP Mobile App
│
├── BottomNavigationBar (5 onglets, toujours visible)
│   ├── 🏠  Accueil          → HomeScreen
│   ├── 📅  Annonces         → AnnoncesScreen
│   ├── 🗺️  Carte            → CarteScreen  ← géolocalisation
│   ├── 📝  Blog             → BlogScreen
│   └── 👤  Profil/Connexion → ProfilScreen
│
├── Routes modales / push
│   ├── AnnonceDetailScreen   (depuis AnnoncesScreen ou CarteScreen)
│   ├── ConnexionScreen        (depuis ProfilScreen ou bouton Réserver)
│   ├── InscriptionScreen
│   ├── ContactScreen
│   ├── PtsInteretScreen
│   └── DashboardAdminScreen  (rôle animateur uniquement)
│
└── Composants globaux
    ├── ThemeToggleFAB         (FloatingActionButton bas droite)
    ├── HapAppBar              (AppBar sticky avec logo + hamburger)
    └── HapDrawer              (Drawer latéral)
```

---

## 🔧 Composant global — BottomNavigationBar

```
┌────────────────────────────────────┐
│                                    │
│         [Contenu de la page]       │
│                                    │
├────────────────────────────────────┤
│  🏠      📅      🗺️      📝      👤 │
│ Accueil Annonces Carte  Blog  Profil│
│  (●)                               │  ← onglet actif : violet #a100b8
└────────────────────────────────────┘

Comportement :
→ Tap onglet  → navigation sans rechargement (IndexedStack)
→ Onglet actif : icône + label colorés en #a100b8, fond léger violet
→ Onglet inactif : gris #9e9e9e
→ Badge rouge sur 📝 si nouveaux avis en attente (admin)
→ Badge rouge sur 👤 si non connecté (pastille "!")
```

---

## 🔧 Composant global — HapAppBar + Drawer

```
AppBar (hauteur 60px) :
┌────────────────────────────────────┐
│  🎵 HAP                    [≡]     │
└────────────────────────────────────┘

Tap [≡] → Drawer depuis la gauche :
┌────────────────────────────────────┐
│  ┌──────────────────────────────┐  │
│  │  🎵 House After Party        │  │  ← Header drawer violet
│  │  👤 Bienvenue, Paul !        │  │    (ou "Connectez-vous")
│  └──────────────────────────────┘  │
│                                    │
│  🏠  Accueil                       │
│  📅  Annonces                      │
│  🗺️  Carte                         │
│  🎵  Points d'Intérêt              │
│  📝  Blog & Avis                   │
│  📬  Contact & Support             │
│  ℹ️  À propos                       │
│  ─────────────────────────────     │
│  🛠️  Dashboard Admin               │  ← visible si rôle animateur
│  ─────────────────────────────     │
│  🚪  Se déconnecter                │  ← si connecté
│       OU                           │
│  🔐  Se connecter                  │  ← si non connecté
│  📝  S'inscrire                    │
└────────────────────────────────────┘

Interactions :
→ Tap item → navigation + fermeture drawer
→ Swipe depuis gauche → ouverture drawer
→ Tap overlay sombre → fermeture drawer
→ Item actif : fond violet clair, texte violet
```

---

## 🔧 Composant global — ThemeToggleFAB

```
Position : fixe, bottom: 20px, right: 20px
Sur TOUTES les pages.

Mode clair :              Mode sombre :
┌──────┐                 ┌──────┐
│  🌙  │  → tap →        │  ☀️  │
└──────┘                 └──────┘
 50×50px                  50×50px
 fond blanc               fond #2a2a2a
 bordure #ddd             bordure #444
 ombre légère             ombre forte

Comportement :
→ Tap → bascule thème instantanément
→ Sauvegarde dans SharedPreferences
→ Appliqué globalement via ThemeProvider (Provider/Riverpod)
→ Transition douce 300ms sur tous les éléments
```

---

## 📱 ÉCRAN 1 — Accueil (`HomeScreen`)

```
┌────────────────────────────────────┐
│ 🎵 HAP                    [≡]      │  ← AppBar violet
├────────────────────────────────────┤
│                                    │
│  ██  HERO (ScrollView)  ████████   │
│  ┌──────────────────────────────┐  │
│  │  [Image de fond soirée]      │  │  ← Stack : image + overlay
│  │  (dégradé violet en overlay) │  │    violet semi-transparent
│  │                              │  │
│  │  🎵 House After Party        │  │  ← texte blanc, 28sp bold
│  │  "Les soirées peuvent        │  │
│   s'arroser"                 │  │  ← 16sp, blanc 80%
│  │                              │  │
│  │ [ 🏠 Voir les logements ]    │  │  ← ElevatedButton blanc
│  │ [ 🎉 Événements proches  ]   │  │  ← OutlinedButton blanc
│  └──────────────────────────────┘  │
│                                    │
│  ── Pourquoi nous choisir ? ─────  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  🏠                          │  │  ← Card Material
│  │  Logements de qualité        │  │    elevation: 4
│  │  Sélectionnés pour vous      │  │    borderRadius: 18px
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  🗺️                          │  │
│  │  Proximité festive           │  │
│  │  Proche des clubs & bars     │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  ⭐                          │  │
│  │  Avis communautaires         │  │
│  │  Notés par les locataires    │  │
│  └──────────────────────────────┘  │
│                                    │
│  ── Comment ça marche ? ─────────  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  ①  Recherchez              │  │
│  │  Filtres, carte, POI         │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  ②  Réservez                │  │
│  │  Calendrier + tarif auto     │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  ③  Profitez !              │  │
│  │  Confirmation email          │  │
│  └──────────────────────────────┘  │
│                                    │
│  ── Galerie photos ──────────────  │
│                                    │
│  ┌─────────┐ ┌─────────┐           │
│  │[photo 1]│ │[photo 2]│           │  ← GridView 2 colonnes
│  └─────────┘ └─────────┘           │    photos 150×120px
│  ┌─────────┐ ┌─────────┐           │    object-fit: cover
│  │[photo 3]│ │[photo 4]│           │
│  └─────────┘ └─────────┘           │
│                                    │
│  ── Témoignages ─────────────────  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  ⭐⭐⭐⭐⭐                   │  │  ← PageView (swipeable)
│  │  "Super séjour, proche du    │  │
│   festival !" — Paul D.      │  │
│  └──────────────────────────────┘  │
│           ·●·○·○                   │  ← indicateurs PageView
│                                    │
├────────────────────────────────────┤
│  🏠      📅      🗺️      📝      👤 │  ← BottomNavigationBar
└────────────────────────────────────┘
                              [🌙/☀️]

Interactions :
→ Scroll vertical (SingleChildScrollView)
→ Tap photo → ouverture photo_view plein écran (zoom, swipe)
→ Swipe témoignages gauche/droite (PageView)
→ Tap [Voir les logements] → onglet Annonces
→ Tap [Événements proches] → PtsInteretScreen
```

---

## 📱 ÉCRAN 2 — Annonces (`AnnoncesScreen`)

```
┌────────────────────────────────────┐
│ 📅 Annonces                [≡]     │
├────────────────────────────────────┤
│                                    │
│  ┌──────────────────────────────┐  │
│  │ 🔍 Rechercher un logement... │  │  ← TextField avec SearchBar
│  └──────────────────────────────┘  │
│                                    │
│  [ 🎚️ Filtres ▼ ]  Tri : [Prix ▼] │  ← Row : bouton + dropdown
│                                    │
│  ┌── Panneau filtres (AnimatedContainer, repliable) ──┐
│  │ Prix min : [—●————————] 0€    │  │  ← RangeSlider
│  │ Prix max : [————————●—] 500€  │  │
│  │                               │  │
│  │ Capacité   : [  2+  ▼ ]       │  │  ← DropdownButton
│  │ Type bien  : [ Appart ▼ ]     │  │
│  │ Commune    : [_____________]  │  │  ← Autocomplete gouv.fr
│  │                               │  │
│  │ Équipements :                 │  │
│  │ [✓] Wifi  [✓] Parking         │  │  ← FilterChip
│  │ [ ] Piscine [ ] Terrasse      │  │
│  │                               │  │
│  │  [ Appliquer ] [ Réinitialiser]│  │
│  └───────────────────────────────┘  │
│                                    │
│  12 logements trouvés              │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  [  Photo principale  ]      │  │  ← Image.network
│  │                    [♡]       │  │  ← IconButton favori
│  ├──────────────────────────────┤  │
│  │  🏠 Appartement City Center  │  │  ← titre 16sp bold
│  │  📍 Paris 11e                │  │  ← subtitle 13sp gris
│  │  👥 4 couchages · 📐 65m²    │  │
│  │  ⭐ 4.5  (12 avis)           │  │
│  │  💶 85€ / nuit               │  │  ← prix violet bold
│  │  [ Voir le détail → ]        │  │  ← ElevatedButton violet
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │  [  Photo principale  ]      │  │
│  │                    [♡]       │  │
│  ├──────────────────────────────┤  │
│  │  🏡 Maison festive Bastille  │  │
│  │  📍 Paris 12e                │  │
│  │  👥 8 couchages · 📐 120m²   │  │
│  │  ⭐ 4.2  (7 avis)            │  │
│  │  💶 145€ / nuit              │  │
│  │  [ Voir le détail → ]        │  │
│  └──────────────────────────────┘  │
│                                    │
│  (ListView.builder → cards)        │
│                                    │
│  [  ←  ]  Page 1 / 3  [  →  ]     │  ← pagination simple
│                                    │
├────────────────────────────────────┤
│  🏠      📅      🗺️      📝      👤 │
└────────────────────────────────────┘
                              [🌙/☀️]

Interactions :
→ Tap [♡] → toggle favori (AJAX/API, icône rouge si actif)
           → si non connecté : SnackBar "Connectez-vous pour
             ajouter aux favoris" + bouton [Se connecter]
→ Tap filtres → AnimatedContainer expand/collapse (300ms)
→ Champ commune → FutureBuilder autocomplete API gouv.fr
→ Tap card → push AnnonceDetailScreen
→ Swipe card gauche → action rapide "Ajouter aux favoris"
→ Pull to refresh → rechargement liste
```

---

## 📱 ÉCRAN 3 — Détail Annonce (`AnnonceDetailScreen`)

```
┌────────────────────────────────────┐
│ ← [Retour]            [♡] [Partager│  ← AppBar transparent + actions
├────────────────────────────────────┤
│                                    │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │   [Photo principale]         │  │  ← PageView photos
│  │                              │  │    hauteur 240px
│  │              ●○○○            │  │  ← indicateur photos
│  └──────────────────────────────┘  │
│                                    │
│  [img1][img2][img3][img4][+5]      │  ← strip photos ScrollView H
│  → Tap → photo_view plein écran    │
│                                    │
│  🏠 Appartement City Center        │  ← 22sp bold
│  📍 12 Rue de la Paix, Paris 11e   │  ← 13sp gris
│  ⭐ 4.5  (12 avis)     [♡ Favori] │
│                                    │
│  ┌── Infos rapides ─────────────┐  │
│  │ 👥 4 couchages               │  │  ← Wrap de Chips
│  │ 📐 65 m²                     │  │
│  │ 🏷️ Appartement               │  │
│  │ ✅ Disponible                 │  │
│  └──────────────────────────────┘  │
│                                    │
│  📋 Description                    │
│  Magnifique appartement situé à    │
│  2 min du Club XYZ...              │
│  [ Lire la suite ▼ ]               │  ← ExpandableText
│                                    │
│  🎯 Équipements & Prestations      │
│  ✅ Wifi  ✅ Parking  ✅ Cuisine   │  ← Wrap de FilterChip (lecture)
│  ✅ Clim  ✅ Terrasse              │
│                                    │
│  🎵 Points d'intérêt proches       │
│  ┌──────────────────────────────┐  │
│  │ 🎶 Club XYZ — 200m           │  │  ← BottomSheet modal
│  │  🍸 Bar Le Duplex — 450m      │  │    (distance depuis GPS)
│  │  🎪 Concerts — 1km            │  │
│  └──────────────────────────────┘  │
│                                    │
│  ── 📅 RÉSERVER ─────────────────  │
│  ┌──────────────────────────────┐  │
│  │ Date arrivée :               │  │
│  │ [ 📅  15 / 03 / 2026 ]       │  │  ← DatePicker natif
│  │ Date départ  :               │  │
│  │ [ 📅  17 / 03 / 2026 ]       │  │
│  │                              │  │
│  │ ⚠️ Semaine spéciale : +20%   │  │  ← Container orange
│  │ 🔴 20/03 → 22/03 indisponible│  │  ← dates bloquées
│  │                              │  │
│  │ ── Calcul tarifaire ──────── │  │
│  │  2 nuits × 85€   =  170€     │  │
│  │  + Frais ménage  =   30€     │  │  ← calculé via API AJAX
│  │  ──────────────────────────  │  │
│  │  💶 Total estimé : 200€      │  │  ← mis à jour dynamique
│  │                              │  │
│  │  [ 🎉 Réserver maintenant ]  │  │  ← ElevatedButton violet
│  │    (si non connecté →        │  │
│  │     push ConnexionScreen)    │  │
│  └──────────────────────────────┘  │
│                                    │
│  ── ⭐ Avis (12) ────────────────  │
│  ┌──────────────────────────────┐  │
│  │ ⭐⭐⭐⭐⭐  Paul D.          │  │
│  │ "Parfait pour notre after !" │  │
│  │ il y a 3 jours               │  │
│  └──────────────────────────────┘  │
│  [ Voir tous les avis → ]          │
│                                    │
├────────────────────────────────────┤
│  🏠      📅      🗺️      📝      👤 │
└────────────────────────────────────┘
                              [🌙/☀️]

Interactions :
→ Swipe photos gauche/droite (PageView)
→ Tap photo → photo_view plein écran (zoom pinch)
→ Strip photos → scroll horizontal
→ DatePicker → bloque dates passées (setDateInputMin)
→ Changement date → appel API calculate_reservation_cost.php
→ [Réserver] → si connecté : dialog confirmation
                si non connecté : push ConnexionScreen avec
                retour automatique après connexion
→ [♡] → toggle favori + haptic feedback
→ Scroll → AppBar devient opaque progressivement (SliverAppBar)
```

---

## 📱 ÉCRAN 4 — Carte (`CarteScreen`) ★ GÉOLOCALISATION

```
┌────────────────────────────────────┐
│ 🗺️ Carte                   [≡]     │
├────────────────────────────────────┤
│                                    │
│  ┌── Barre outils carte ────────┐  │
│  │ [ Tous ▼ ] [Logements][POI]  │  │  ← FilterChips sur la carte
│  │ [ 📍 Ma position ]           │  │  ← bouton géolocalisation
│  └──────────────────────────────┘  │
│                                    │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │  ┌───────────────────────┐   │  │
│  │  │  [CARTE FLUTTER MAP   │   │  │  ← flutter_map + Leaflet
│  │  │   ou google_maps]     │   │  │    hauteur : ~65% écran
│  │  │                       │   │  │
│  │  │  🔵 [Ma position]     │   │  │  ← marqueur bleu animé
│  │  │   ╰── Cercle rayon    │   │  │    (pulse animation)
│  │  │       500m            │   │  │    cercle de précision
│  │  │                       │   │  │
│  │  │  📍 [Appart. City]    │   │  │  ← marqueur violet
│  │  │  📍 [Maison Bastille] │   │  │    logements
│  │  │  🎶 [Club XYZ]        │   │  │  ← marqueur orange
│  │  │  🍸 [Bar Duplex]      │   │  │    POI
│  │  │                       │   │  │
│  │  │  [+]  [-]  [⊙ Centrer]│   │  │  ← contrôles zoom
│  │  └───────────────────────┘   │  │
│  └──────────────────────────────┘  │
│                                    │
│  ── Dialog géolocalisation ──────  │
│  (apparaît au 1er lancement)       │
│  ┌──────────────────────────────┐  │
│  │  📍 Autoriser la            │  │
│  │  géolocalisation ?           │  │
│  │                              │  │
│  │  HAP souhaite accéder à      │  │
│  │  votre position pour         │  │
│  │  afficher les logements      │  │
│  │  et POI les plus proches.    │  │
│  │                              │  │
│  │  [ ✅ Autoriser ]            │  │  ← vert
│  │  [ ✗ Refuser    ]            │  │  ← gris
│  └──────────────────────────────┘  │
│                                    │
│  ── Bannière si refus GPS ───────  │
│  ⚠️ Géoloc. désactivée            │
│  [ Activer dans les paramètres ]   │  ← ouvre Settings
│                                    │
│  ── Popup marqueur logement ─────  │
│  (tap sur 📍 violet)               │
│  ┌──────────────────────────────┐  │
│  │  🏠 Appart. City Center      │  │  ← BottomSheet modal
│  │  📍 Paris 11e  · 🚶 350m    │  │    (distance depuis GPS)
│  │  ⭐ 4.5  💶 85€/nuit         │  │
│  │  [Photo miniature]           │  │
│  │  [ 📋 Voir l'annonce → ]     │  │  ← push AnnonceDetailScreen
│  └──────────────────────────────┘  │
│                                    │
│  ── Popup marqueur POI ──────────  │
│  (tap sur 🎶 / 🍸 orange)          │
│  ┌──────────────────────────────┐  │
│  │  🎶 Club XYZ                 │  │  ← BottomSheet modal
│  │  Type : Discothèque          │  │
│  │  📍 Paris 11e  · 🚶 200m    │  │    (distance depuis GPS)
│  │  Description courte...       │  │
│  │  [ 🗺️ Itinéraire Google Maps]│  │  ← url_launcher
│  └──────────────────────────────┘  │
│                                    │
│  ── Légende ─────────────────────  │
│  📍 Logement   🎶 POI   🔵 Moi    │
│                                    │
├────────────────────────────────────┤
│  🏠      📅      🗺️      📝      👤 │
└────────────────────────────────────┘
                              [🌙/☀️]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GÉOLOCALISATION — Détail technique Flutter

Package : geolocator: ^13.x + permission_handler: ^11.x

Flux de permission :
  1. Lancement CarteScreen
     ↓
  2. checkPermission()
     ├── granted    → getCurrentPosition() → centrer carte
     ├── denied     → requestPermission()
     │    ├── granted → getCurrentPosition() → centrer carte
     │    └── denied  → bannière ⚠️ + bouton paramètres
     └── deniedForever → openAppSettings()

Fonctionnalités GPS :
  [📍 Ma position] :
    → Appui court : centre la carte sur position actuelle
    → Appui long  : activer suivi en temps réel (Stream)
    → Icône animée (rotation) pendant la localisation

  Marqueur position :
    → Cercle bleu pulsant (AnimationController)
    → Rayon précision GPS affiché
    → Coordonnées affichées en bas (optionnel)

  Distance logements/POI :
    → Calculée avec Geolocator.distanceBetween()
    → Affichée sur chaque marqueur popup : "🚶 350m"
    → Tri possible "Par distance"

  Permissions requises :
    Android → AndroidManifest.xml :
      <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
      <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    iOS → Info.plist :
      NSLocationWhenInUseUsageDescription
      → "HAP utilise votre position pour trouver
         les logements les plus proches de vous."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Interactions carte (résumé) :
→ Pinch zoom / drag pour naviguer
→ Tap [📍 Ma position] → requête permission → centrer
→ Tap marqueur logement → BottomSheet avec distance GPS
→ Tap marqueur POI → BottomSheet + bouton itinéraire
→ FilterChips → affiche/masque logements ou POI
→ [⊙ Centrer] → recentre sur position GPS actuelle
→ Tap [Itinéraire] → ouvre Google Maps / Apple Maps (url_launcher)
```

---

## 📕 Design System — Tokens

```
COULEURS
  Primary       : #a100b8  (violet HAP)
  PrimaryDark   : #3d0066
  Accent        : #667eea
  Secondary     : #764ba2
  Success       : #10b981
  Error         : #ef4444
  Warning       : #f59e0b
  BgLight       : #f5f5f5
  BgDark        : #1e1e1e
  CardLight     : #ffffff
  CardDark      : #2a2a2a
  TextLight     : #333333
  TextDark      : #f0f0f0

TYPOGRAPHIE (Montserrat)
  Display  : 28sp, bold
  Headline : 22sp, bold
  Title    : 18sp, semibold
  Body     : 14sp, regular
  Caption  : 12sp, regular
  Button   : 14sp, semibold, uppercase

ESPACEMENTS
  xs  :  4px
  sm  :  8px
  md  : 16px
  lg  : 24px
  xl  : 32px
  xxl : 48px

BORDURES
  radius-sm  :  8px
  radius-md  : 16px
  radius-lg  : 24px
  radius-full: 50px (pills)

OMBRES (elevation Flutter)
  card    : elevation 2
  modal   : elevation 8
  fab     : elevation 6

FLUTTER PACKAGES RECOMMANDÉS
  flutter_map ou google_maps_flutter → carte
  geolocator: ^13.x                  → GPS
  permission_handler: ^11.x          → permissions
  flutter_rating_bar: ^4.x           → étoiles avis
  photo_view: ^0.14.x                → galerie plein écran
  provider ou riverpod               → state management
  shared_preferences: ^2.x           → thème persistant
  url_launcher: ^6.x                 → liens externes / itinéraires
  google_fonts: ^6.x                 → Montserrat
  cached_network_image: ^3.x         → images réseau
  dio: ^5.x                          → requêtes HTTP API HAP
```

---

## 🗺️ Flux de navigation complet

```
                    ┌──────────────┐
                    │  🏠 Accueil  │
                    └──────┬───────┘
        ┌──────────────────┼───────────────────┐
        ▼                  ▼                   ▼
 ┌────────────┐    ┌──────────────┐    ┌──────────────┐
 │📅 Annonces │    │  🗺️ Carte    │    │  📝 Blog     │
 └──────┬─────┘    │  +GPS 📍     │    └──────┬───────┘
        ▼          └──────┬───────┘           ▼
 ┌────────────┐           ▼           ┌──────────────┐
 │🔍 Détail   │   ┌──────────────┐   │ Soumettre    │
 │  Annonce  │   │BottomSheet   │   │ Avis         │
 └──────┬─────┘   │Logement/POI  │   └──────────────┘
        ▼          └──────┬───────┘
 ┌────────────┐           ▼
 │📅 Réserver │   ┌──────────────┐
 └──────┬─────┘   │ Itinéraire   │
        ▼          │ Google Maps  │
 ┌────────────┐   └──────────────┘
 │🔐 Connexion│
 └──────┬─────┘
        ▼
 ┌────────────┐
 │ 👤 Profil  │
 │  Favoris   │
 │  Réserv.   │
 └────────────┘

BottomNav (toujours visible) :
🏠 Accueil ──┐
📅 Annonces──┤
🗺️ Carte   ──┤─→ IndexedStack (pas de rechargement)
📝 Blog    ──┤
👤 Profil  ──┘

Drawer (≡) :
→ 🎵 POI · 📬 Contact · ℹ️ À propos
→ 🛠️ Dashboard Admin (animateur)
```

---

*📄 Maquettage généré le 05/03/2026 — House After Party (HAP) Mobile v1.0*
*Basé sur le code source de Omnous-Luminae/Projet_SLAM*
*Géolocalisation : geolocator + permission_handler (Flutter)*