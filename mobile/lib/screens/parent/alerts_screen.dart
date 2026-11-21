import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static const _alerts = [
    _Alert(icon: Icons.credit_card_outlined, title: 'Solde faible', subtitle: 'Yao : 500 FCFA', time: '7 h 30', unread: true, iconColor: AppColors.orange),
    _Alert(icon: Icons.check_circle_outline, title: 'Réservation confirmée', subtitle: 'Aya · Alloco poulet', time: '8 h 41', unread: true, iconColor: AppColors.green),
    _Alert(icon: Icons.restaurant_menu_outlined, title: 'Nouveaux menus', subtitle: 'Semaine du 23 nov.', time: 'Hier', unread: true, iconColor: AppColors.orange),
    _Alert(icon: Icons.check_circle_outline, title: 'Repas servi', subtitle: 'Yao · Wrap poulet', time: 'Hier', unread: false, iconColor: AppColors.green),
    _Alert(icon: Icons.add_circle_outline, title: 'Recharge réussie', subtitle: 'Aya · + 5 000 FCFA', time: 'Mer.', unread: false, iconColor: AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Padding(padding:const EdgeInsets.fromLTRB(16,16,16,0),
          child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
            Text('Alertes', style:GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
            Text('Tout lire', style:GoogleFonts.inter(fontSize:13, color:AppColors.orange, fontWeight:FontWeight.w600)),
          ])),
        const SizedBox(height:12),
        Expanded(child:ListView.separated(
          padding:const EdgeInsets.symmetric(horizontal:16),
          itemCount:_alerts.length,
          separatorBuilder:(_,__) => const Divider(height:1, color:AppColors.surfaceHigh),
          itemBuilder:(_,i) => _alertRow(_alerts[i]),
        )),
        Padding(padding:const EdgeInsets.all(16),
          child:Text('Alertes de démonstration', style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary), textAlign:TextAlign.center)),
      ])),
    );
  }

  Widget _alertRow(_Alert a) => Padding(
    padding: const EdgeInsets.symmetric(vertical:14),
    child: Row(children:[
      Container(width:44, height:44,
        decoration:BoxDecoration(color:AppColors.surface, borderRadius:BorderRadius.circular(12)),
        child:Icon(a.icon, color:a.iconColor, size:22)),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(a.title, style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        Text(a.subtitle, style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary)),
      ])),
      Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
        Text(a.time, style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary)),
        if (a.unread) ...[
          const SizedBox(height:4),
          Container(width:8, height:8, decoration:const BoxDecoration(shape:BoxShape.circle, color:AppColors.orange)),
        ],
      ]),
    ]),
  );
}

class _Alert {
  final IconData icon;
  final String title, subtitle, time;
  final bool unread;
  final Color iconColor;
  const _Alert({required this.icon, required this.title, required this.subtitle, required this.time, required this.unread, required this.iconColor});
}
