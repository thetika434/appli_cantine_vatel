import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    if (token != null) {
      final userRaw = prefs.getString('auth_user') ?? '';
      final role = _extractRole(userRaw);
      if (role == 'parent') {
        Navigator.pushReplacementNamed(context, '/parent/home');
      } else {
        Navigator.pushReplacementNamed(context, '/student/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _extractRole(String raw) {
    for (final part in raw.split('|')) {
      if (part.startsWith('role=')) return part.substring(5);
    }
    return 'student';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1626200419199-391ae4be7a41?w=800',
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(color: AppColors.orange),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0xBB000000),
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Venez réserver\nvotre ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dabali ',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                      Text(
                        'chap chap',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Dot(active: true),
                      const SizedBox(width: 8),
                      _Dot(active: false),
                      const SizedBox(width: 8),
                      _Dot(active: false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.orange : Colors.white38,
      ),
    );
  }
}
