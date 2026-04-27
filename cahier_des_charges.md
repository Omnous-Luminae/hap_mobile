# Cahier des charges - HAP Mobile

## 1. Contexte
HAP Mobile est l'application mobile du projet HAP permettant aux utilisateurs finaux de rechercher des biens, consulter les details, reserver et gerer leur compte.

## 2. Objectifs
- Offrir une experience mobile fluide de consultation et reservation.
- Centraliser les interactions utilisateur avec les APIs PHP existantes.
- Garantir l'absence de fonctionnalites administratives dans le client mobile.
- Maintenir la coherence entre donnees mobile et backend partage.

## 3. Perimetre fonctionnel
### Inclus
- Authentification: connexion, inscription, profil, deconnexion.
- Catalogue de biens: liste paginee, recherche texte, suggestions.
- Filtres avances et tri.
- Detail bien: photos, informations, disponibilites, avis, carte.
- Reservations: creation, consultation, annulation.
- Favoris: ajout, suppression, consultation.
- Notifications applicatives.
- Carte et points d'interet (POI).

### Exclu
- Administration, moderation, back-office.
- Outils techniques internes (scripts SQL/debug).
- Gestion des contenus admin depuis le mobile.

## 4. Exigences fonctionnelles
- L'utilisateur non connecte peut consulter les biens mais ne peut pas reserver ni gerer ses favoris.
- L'utilisateur connecte peut:
  - reserver un bien selon les disponibilites
  - consulter/annuler ses reservations selon regles metier
  - gerer ses favoris
  - modifier son profil
- Les filtres doivent etre combinables et appliques via requete API.
- Les erreurs reseau/API doivent etre comprehensibles et gerables par l'utilisateur.
- La session doit etre invalidee localement en cas de reponse 401.

## 5. Exigences non fonctionnelles
### 5.1 Performance
- Temps de reponse API cible: < 2 s en usage nominal.
- Timeout client centralise: 20 s.
- Pagination obligatoire pour les listes.

### 5.2 Securite
- Authentification JWT pour les endpoints proteges.
- Requetes SQL backend executees en requetes preparees.
- Aucun endpoint admin utilise par le client mobile.
- Secrets serveurs geres hors code source en production.

### 5.3 Qualite
- Gestion des etats UI: chargement, vide, erreur.
- Compatibilite Android/iOS.
- Analyse statique et tests Flutter executes avant livraison.

## 6. Contraintes techniques
- Frontend: Flutter (Dart).
- Backend: PHP + MySQL existants.
- Communication: HTTP JSON.
- Stockage local: shared_preferences.
- Cartographie: OpenStreetMap via flutter_map.

## 7. Livrables attendus
- Application mobile fonctionnelle (sources Flutter).
- APIs mobiles PHP operationnelles.
- Documentation fonctionnelle: spec_fonctionnelle.md.
- Documentation technique: spe_technique.
- Documentation installation/exploitation.

## 8. Criteres de recette
- Authentification complete fonctionnelle.
- Recherche + filtres + tri fonctionnels sur donnees reelles.
- Reservation possible uniquement sur plages disponibles.
- Favoris et profil persistants et coherents.
- Notifications visibles et marquage lu operationnel.
- Absence de parcours admin dans l'application mobile.

## 9. Risques et points de vigilance
- Disponibilite backend/API.
- Coherence des donnees partagees entre web et mobile.
- Gestion des secrets JWT et configuration CORS en production.
- Regressions lors des evolutions des endpoints.

## 10. Validation
Ce cahier des charges sert de reference de perimetre pour les evolutions futures et la recette fonctionnelle du projet HAP Mobile.
