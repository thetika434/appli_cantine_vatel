import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository repo;
  const LoginScreen({super.key, required this.repo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isParent = false;
  bool _rememberMe = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _matriculeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _matriculeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final matricule = _matriculeCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (matricule.isEmpty || password.isEmpty) {
      setState(() => _error = 'Remplis tous les champs.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repo.login(matricule, password);
      final user = result['user'] as Map<String, dynamic>;
      final token = result['token'] as String;
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('auth_user',
            user.entries.map((e) => '${e.key}=${e.value}').join('|'));
      }
      if (!mounted) return;
      final role = user['role'] as String? ?? 'student';
      if (role == 'parent') {
        Navigator.pushReplacementNamed(context, '/parent/home');
      } else {
        Navigator.pushReplacementNamed(context, '/student/home');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Identifiants invalides. Vérifie et réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _AppIllustration(),
              const SizedBox(height: 32),
              Text(
                'Content de te revoir !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connecte-toi pour réserver.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _RoleToggle(
                isParent: _isParent,
                onChanged: (v) {
                  setState(() {
                    _isParent = v;
                    _matriculeCtrl.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _matriculeCtrl,
                keyboardType:
                    _isParent ? TextInputType.phone : TextInputType.text,
                decoration: InputDecoration(
                  hintText: _isParent ? 'Téléphone' : 'Matricule',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textSecondary),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _rememberMe ? AppColors.green : Colors.transparent,
                            border: Border.all(
                              color: _rememberMe ? AppColors.green : AppColors.textSecondary,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _rememberMe
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Se souvenir de moi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Mot de passe oublié ?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Première fois ? ',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Activer mon compte',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  final bool isParent;
  final ValueChanged<bool> onChanged;

  const _RoleToggle({required this.isParent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _Tab(label: 'Élève', active: !isParent, onTap: () => onChanged(false))),
          Expanded(child: _Tab(label: 'Parent', active: isParent, onTap: () => onChanged(true))),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AppIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(60),
            ),
          ),
          Container(
            width: 90,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.textPrimary, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.orange, width: 2),
                    color: AppColors.surface,
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                    width: 50, height: 6, decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 6),
                Container(
                    width: 40, height: 6, decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 10),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 60,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.orange),
            ),
          ),
          Positioned(
            top: 20,
            right: 70,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
  }
}
