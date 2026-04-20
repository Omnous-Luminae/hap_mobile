import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';

Future<bool> showEditProfileSheet(BuildContext context, User user) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditProfileSheet(user: user),
  );
  return result ?? false;
}

class EditProfileSheet extends StatefulWidget {
  final User user;

  const EditProfileSheet({super.key, required this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  static const Color _bg = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent = Color(0xFFe94560);

  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telephoneCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _rueCtrl;
  late final TextEditingController _complementCtrl;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prenomCtrl = TextEditingController(text: widget.user.prenom);
    _nomCtrl = TextEditingController(text: widget.user.nom);
    _telephoneCtrl = TextEditingController(text: widget.user.telephone ?? '');
    _dateCtrl = TextEditingController(text: widget.user.dateNaissance ?? '');
    _rueCtrl = TextEditingController(text: widget.user.rue ?? '');
    _complementCtrl = TextEditingController(text: widget.user.complement ?? '');
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _dateCtrl.dispose();
    _rueCtrl.dispose();
    _complementCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = widget.user.dateNaissance != null
        ? DateTime.tryParse(widget.user.dateNaissance!) ?? DateTime(now.year - 25)
        : DateTime(now.year - 25);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 12),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              surface: _surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> _save() async {
    final prenom = _prenomCtrl.text.trim();
    final nom = _nomCtrl.text.trim();

    if (prenom.isEmpty || nom.isEmpty) {
      setState(() => _error = 'Le prénom et le nom sont obligatoires.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile({
      'prenom': prenom,
      'nom': nom,
      'telephone': _telephoneCtrl.text.trim(),
      'date_naissance': _dateCtrl.text.trim(),
      'rue': _rueCtrl.text.trim(),
      'complement': _complementCtrl.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _error = auth.error ?? 'Impossible de mettre à jour le profil.';
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Modifier le profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mettez à jour vos informations personnelles et votre adresse.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _field('Prénom', _prenomCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _field('Nom', _nomCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _field('Téléphone', _telephoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _dateField(),
                const SizedBox(height: 12),
                _field('Rue', _rueCtrl, Icons.home_outlined),
                const SizedBox(height: 12),
                _field('Complément', _complementCtrl, Icons.add_location_alt_outlined),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13)),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
      ),
    );
  }

  Widget _dateField() {
    return TextField(
      controller: _dateCtrl,
      readOnly: true,
      onTap: _pickDate,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Date de naissance',
        prefixIcon: const Icon(Icons.cake_outlined, color: Colors.white54),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, color: Colors.white54),
          onPressed: _pickDate,
        ),
      ),
    );
  }
}
