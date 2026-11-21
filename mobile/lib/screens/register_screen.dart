import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/api.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthRepository repo;
  const RegisterScreen({super.key, required this.repo});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isParent = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _childCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nameCtrl, _matriculeCtrl, _classCtrl, _phoneCtrl, _childCtrl, _passwordCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_nameCtrl.text.trim().length < 3) return 'Saisis ton nom complet.';
    if (_isParent) {
      if (_phoneCtrl.text.trim().isEmpty) return 'Saisis ton numéro de téléphone.';
      if (_childCtrl.text.trim().isEmpty) return 'Saisis le matricule de ton enfant.';
    } else {
      if (_matriculeCtrl.text.trim().isEmpty) return 'Saisis ton matricule.';
      if (_classCtrl.text.trim().isEmpty) return 'Saisis ta classe.';
    }
    if (_passwordCtrl.text.length < 6) return 'Le mot de passe doit faire au moins 6 caractères.';
    if (_passwordCtrl.text != _confirmCtrl.text) return 'Les deux mots de passe ne correspondent pas.';
    return null;
  }

  Map<String, dynamic> _body() {
    final body = <String, dynamic>{
      'role': _isParent ? 'parent' : 'student',
      'full_name': _nameCtrl.text.trim(),
      'password': _passwordCtrl.text,
    };
    if (_isParent) {
      body['phone'] = normalizeCiPhone(_phoneCtrl.text);
      body['child_matricule'] = _childCtrl.text.trim().toUpperCase();
    } else {
      body['matricule'] = _matriculeCtrl.text.trim().toUpperCase();
      body['class'] = _classCtrl.text.trim();
      if (_phoneCtrl.text.trim().isNotEmpty) body['phone'] = _phoneCtrl.text.trim();
    }
    return body;
  }

  Future<void> _register() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.repo.register(_body());
      final user = result['user'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token'] as String);
      await prefs.setString('auth_user', user.entries.map((e) => '${e.key}=${e.value}').join('|'));
      if (!mounted) return;
      final route = user['role'] == 'parent' ? '/parent/home' : '/student/home';
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _loading = false;
        _error = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : e.response?.statusCode == 404
                ? "L'inscription n'est pas encore disponible sur le serveur."
                : 'Impossible de joindre le serveur. Vérifie ta connexion internet.';
      });
    } catch (_) {
      setState(() { _loading = false; _error = 'Inscription impossible. Réessaie.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Créer un compte', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(_isParent ? 'Suis les repas de ton enfant et recharge son compte.' : 'Réserve tes repas à la cantine.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            RoleToggle(isParent: _isParent, onChanged: (v) => setState(() { _isParent = v; _error = null; })),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Nom complet', Icons.person_outline, caps: TextCapitalization.words),
            if (_isParent) ...[
              _field(_phoneCtrl, 'Téléphone (ex : 07 00 00 00 00)', Icons.phone_outlined, type: TextInputType.phone),
              _field(_childCtrl, "Matricule de l'enfant (ex : VAT-24-0157)", Icons.badge_outlined, caps: TextCapitalization.characters),
            ] else ...[
              _field(_matriculeCtrl, 'Matricule (ex : VAT-24-0157)', Icons.badge_outlined, caps: TextCapitalization.characters),
              _field(_classCtrl, 'Classe (ex : Terminale D)', Icons.school_outlined, caps: TextCapitalization.sentences),
              _field(_phoneCtrl, 'Téléphone (facultatif)', Icons.phone_outlined, type: TextInputType.phone),
            ],
            _field(_passwordCtrl, 'Mot de passe (6 caractères min.)', Icons.lock_outline, password: true),
            _field(_confirmCtrl, 'Confirmer le mot de passe', Icons.lock_outline, password: true),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.red), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Créer mon compte'),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Déjà un compte ? ', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Se connecter', style: GoogleFonts.inter(fontSize: 14, color: AppColors.green, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type, bool password = false, TextCapitalization caps = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        textCapitalization: caps,
        obscureText: password && _obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: password
            ? GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textSecondary),
              )
            : null,
        ),
      ),
    );
  }
}
