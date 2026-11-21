import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api.dart';

class NotificationsScreen extends StatefulWidget {
  final String title;
  final bool showBack;
  const NotificationsScreen({super.key, this.title = 'Notifications', this.showBack = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _api.getNotifications();
      final list = (r['notifications'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _items = list; _loading = false; _error = false; });
      if (list.any((n) => n['read'] != true)) {
        unawaited(_api.markNotificationsRead().catchError((_) {}));
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  static (IconData, Color) _style(String? type) => switch (type) {
        'reservation' => (Icons.restaurant_menu_outlined, AppColors.green),
        'served' => (Icons.check_circle_outline, AppColors.green),
        'cancelled' => (Icons.undo_outlined, AppColors.red),
        'recharge' => (Icons.account_balance_wallet_outlined, AppColors.orange),
        _ => (Icons.notifications_outlined, AppColors.textSecondary),
      };

  // Les titres serveur commencent par un emoji : l'icône le remplace.
  static String _cleanTitle(String t) =>
      t.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');

  static String _timeAgo(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    const months = ['jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showBack
          ? AppBar(
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
              title: Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            )
          : null,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!widget.showBack)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(widget.title, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 140),
                            Icon(_error ? Icons.wifi_off_outlined : Icons.notifications_none_outlined,
                                size: 44, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              _error ? 'Impossible de charger les notifications.' : 'Aucune notification pour le moment.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.surfaceHigh),
                            itemBuilder: (_, i) => _row(_items[i]),
                          ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _row(Map<String, dynamic> n) {
    final (icon, color) = _style(n['type'] as String?);
    final unread = n['read'] != true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_cleanTitle(n['title']?.toString() ?? ''),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: unread ? FontWeight.w700 : FontWeight.w600, color: AppColors.textPrimary)),
            if ((n['body']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(n['body'].toString(), style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.35)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_timeAgo(n['created_at']?.toString()), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          if (unread) ...[
            const SizedBox(height: 6),
            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green)),
          ],
        ]),
      ]),
    );
  }
}

// Icône cloche avec pastille du nombre de notifications non lues.
class NotificationBell extends StatelessWidget {
  final Color color;
  final double size;
  final VoidCallback? onTap;
  const NotificationBell({super.key, this.color = AppColors.textPrimary, this.size = 24, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<int>(
        valueListenable: unreadNotifications,
        builder: (_, count, _) => Stack(clipBehavior: Clip.none, children: [
          Icon(count > 0 ? Icons.notifications : Icons.notifications_outlined, color: color, size: size),
          if (count > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ]),
      ),
    );
  }
}

// Interroge le serveur toutes les 30 s tant que l'écran parent est affiché.
mixin NotificationPolling<T extends StatefulWidget> on State<T> {
  Timer? _notifTimer;

  void startNotificationPolling() {
    final api = ApiService();
    Future<void> poll() => api.getNotifications().then((_) {}, onError: (_) {});
    poll();
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) => poll());
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }
}
