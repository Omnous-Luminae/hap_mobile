# Document fonctionnel - HAP Mobile

## 1. Objet du document
Ce document décrit le fonctionnement utilisateur de l'application HAP Mobile telle qu'implémentée dans ce depot.

## 2. Positionnement
HAP Mobile est l'application client (Flutter) pour la consultation et la reservation de biens.
Le mobile est reserve aux utilisateurs finaux. Aucune interface d'administration n'est exposee dans l'application.

## 3. Profils utilisateurs
- Visiteur non connecte
- Utilisateur connecte (locataire)

## 4. Parcours fonctionnels
### 4.1 Demarrage et session
- Ecran splash au lancement.
- Verification de session locale.
- Redirection automatique vers connexion ou accueil.

### 4.2 Authentification
- Connexion par email/mot de passe.
- Inscription (nom, prenom, email, mot de passe, champs complementaires).
- Recuperation du profil connecte.
- Deconnexion avec purge de session locale.

### 4.3 Accueil et recherche
- Liste paginee des biens disponibles.
- Recherche texte avec suggestions.
- Pull-to-refresh.
- Gestion des erreurs avec action de reprise.

### 4.4 Filtres
- Ouverture d'un panneau de filtres.
- Critères supportes:
  - type de bien
  - prix min/max
  - couchages min
  - superficie min/max
  - animaux
  - note minimale
  - commune
  - tri
- Application immediate des filtres sur la liste.

### 4.5 Detail d'un bien
- Affichage detail complet du bien.
- Galerie photo.
- Localisation sur carte.
- Avis, notes et tarifs.
- Consultation des disponibilites.

### 4.6 Reservation
- Selection de plage de dates.
- Verification des disponibilites.
- Confirmation de reservation.
- Affichage de feedback utilisateur.

### 4.7 Favoris
- Consultation des favoris du compte.
- Ajout/retrait de favoris.
- Navigation vers le detail d'un bien favori.

### 4.8 Mes reservations
- Liste des reservations de l'utilisateur.
- Affichage des statuts.
- Annulation des reservations a venir.

### 4.9 Profil
- Consultation des informations personnelles.
- Modification des donnees profil.
- Onglets infos / reservations / parametres.

### 4.10 Notifications
- Ecran notifications.
- Marquage lu/non lu.
- Marquer tout comme lu.
- Compteur de notifications non lues.

### 4.11 Carte et POI
- Affichage des biens sur carte.
- Recuperation des points d'interet et evenements proches.
- Fiche d'information POI.

## 5. Regles fonctionnelles transverses
- Les actions reservees (favoris, reservation, profil) necessitent une authentification.
- En cas de 401 API, la session locale est nettoyee.
- Les messages de succes/erreur sont affiches en interface.
- Le mobile n'embarque aucun module d'administration.

## 6. Cas hors perimetre mobile
- Administration des contenus, moderation, back-office.
- Gestion administrative des POI.
- Outils SQL/debug internes.

## 7. Endpoints fonctionnels utilises
- Auth:
  - /php_api/api/mobile/auth_login.php
  - /php_api/api/mobile/auth_register.php
  - /php_api/api/mobile/auth_me.php
  - /php_api/api/mobile/auth_logout.php
- Biens:
  - /php_api/api/mobile/get_biens_mobile.php
  - /php_api/api/mobile/get_bien_detail.php
  - /php_api/api/mobile/search_biens.php
  - /php_api/api/search_communes.php
- Favoris/Reservations/Profil:
  - /php_api/api/mobile/favoris.php
  - /php_api/api/mobile/get_disponibilites.php
  - /php_api/api/mobile/create_reservation.php
  - /php_api/api/mobile/get_mes_reservations.php
  - /php_api/api/mobile/cancel_reservation.php
  - /php_api/api/mobile/update_profile.php
- POI:
  - /php_api/api/mobile/get_pois.php

## 8. Criteres d'acceptation fonctionnels
- L'utilisateur peut se connecter, chercher, filtrer, consulter un bien et reserver.
- L'utilisateur peut gerer ses favoris et ses reservations.
- L'utilisateur peut modifier son profil.
- Les ecrans critiques gerent chargement, erreur et reprise.
- Aucune fonctionnalite admin n'est accessible depuis l'app.
