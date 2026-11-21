import 'package:material_ui/material_ui.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/parent/parent_shell.dart';
import 'services/api.dart';

void main() {
  runApp(const CantineApp());
}

class CantineApp extends StatelessWidget {
  const CantineApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ApiService tente d'abord la vraie API (https://cantine-vatel.duckdns.org/api)
    // Tant que /api/auth/login n'est pas prête, l'écran affiche l'erreur et
    // on peut passer FakeAuthRepository() pour la démo en changeant cette ligne.
    final repo = ApiService();

    return MaterialApp(
      title: 'Dabali',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => LoginScreen(repo: repo),
        '/student/home': (_) => const StudentShell(),
        '/parent/home': (_) => const ParentShell(),
      },
    );
  }
}
