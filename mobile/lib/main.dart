import 'package:material_ui/material_ui.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/api.dart';

void main() {
  runApp(const CantineApp());
}

class CantineApp extends StatelessWidget {
  const CantineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ApiService();

    return MaterialApp(
      title: 'Dabali',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => LoginScreen(repo: repo),
        '/student/home': (_) => const _PlaceholderScreen(title: 'Accueil élève'),
        '/parent/home': (_) => const _PlaceholderScreen(title: 'Accueil parent'),
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
