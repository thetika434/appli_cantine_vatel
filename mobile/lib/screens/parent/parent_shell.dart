import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../notifications_screen.dart';
import 'parent_home_screen.dart';
import 'parent_history_screen.dart';
import 'settings_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> with NotificationPolling {
  int _index = 0;
  int _alertsVisit = 0;

  @override
  void initState() {
    super.initState();
    startNotificationPolling();
  }

  @override
  Widget build(BuildContext context) {
    // L'onglet Alertes n'est construit qu'à l'ouverture : il marque les notifications comme lues.
    final pages = [
      const ParentHomeScreen(),
      const ParentHistoryScreen(),
      _index == 2
          ? NotificationsScreen(key: ValueKey(_alertsVisit), title: 'Alertes', showBack: false)
          : const SizedBox.shrink(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceHigh, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() {
            if (i == 2 && _index != 2) _alertsVisit++;
            _index = i;
          }),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.green,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), activeIcon: Icon(Icons.access_time), label: 'Historique'),
            BottomNavigationBarItem(
              icon: NotificationBell(color: AppColors.textSecondary),
              activeIcon: NotificationBell(color: AppColors.green),
              label: 'Alertes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Réglages'),
          ],
        ),
      ),
    );
  }
}
