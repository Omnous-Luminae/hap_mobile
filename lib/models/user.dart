/// user.dart — Modèle de données représentant un Locataire (utilisateur mobile)
///
/// Correspond aux champs de la table MySQL `Locataire` + `Commune` (join).
library;

class User {
  /// Identifiant unique du locataire
  final int id;

  /// Nom de famille
  final String nom;

  /// Prénom
  final String prenom;

  /// Adresse email (identifiant de connexion)
  final String email;

  /// Numéro de téléphone
  final String? telephone;

  /// Date de naissance (format ISO 8601 : yyyy-MM-dd)
  final String? dateNaissance;

  /// Adresse — rue
  final String? rue;

  /// Adresse — complément
  final String? complement;

  /// Identifiant de la commune (clé étrangère)
  final int? idCommune;

  /// Nom de la commune (résolu par JOIN)
  final String? nomCommune;

  /// Code postal de la commune (résolu par JOIN)
  final String? cpCommune;

  const User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.dateNaissance,
    this.rue,
    this.complement,
    this.idCommune,
    this.nomCommune,
    this.cpCommune,
  });

  // ── Désérialisation ────────────────────────────────────────────────────────

  /// Crée un [User] à partir d'une Map JSON (réponse de l'API PHP).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String?,
      dateNaissance: json['date_naissance'] as String?,
      rue: json['rue'] as String?,
      complement: json['complement'] as String?,
      idCommune: json['id_commune'] != null ? _parseInt(json['id_commune']) : null,
      nomCommune: json['nom_commune'] as String?,
      cpCommune: json['cp_commune'] as String?,
    );
  }

  // ── Sérialisation ──────────────────────────────────────────────────────────

  /// Convertit le [User] en Map JSON pour le stockage local ou l'envoi API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'date_naissance': dateNaissance,
      'rue': rue,
      'complement': complement,
      'id_commune': idCommune,
      'nom_commune': nomCommune,
      'cp_commune': cpCommune,
    };
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Nom complet : "Prénom Nom"
  String get fullName => '$prenom $nom'.trim();

  /// Convertit une valeur JSON en [int] (accepte int ou String).
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() => 'User(id: $id, email: $email, fullName: $fullName)';
}
