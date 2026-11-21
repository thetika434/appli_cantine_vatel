import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifLow = true;
  bool _notifServed = true;
  bool _notifMenus = false;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(padding:const EdgeInsets.all(20), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        const SizedBox(height:8),
        Text('Réglages', style:GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
        const SizedBox(height:28),
        Text('Compte', style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        const SizedBox(height:4),
        _navRow('Mes informations', () {}),
        const Divider(height:1, color:AppColors.surfaceHigh),
        _navRow('Mot de passe', () {}),
        const SizedBox(height:28),
        Text('Alertes', style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        const SizedBox(height:4),
        _toggleRow('Solde faible', _notifLow, (v)=>setState(()=>_notifLow=v)),
        const Divider(height:1, color:AppColors.surfaceHigh),
        _toggleRow('Repas servis', _notifServed, (v)=>setState(()=>_notifServed=v)),
        const Divider(height:1, color:AppColors.surfaceHigh),
        _toggleRow('Nouveaux menus', _notifMenus, (v)=>setState(()=>_notifMenus=v)),
        const SizedBox(height:28),
        _navRowWithValue('Langue', 'Français', () {}),
        const Divider(height:1, color:AppColors.surfaceHigh),
        _navRow('Se déconnecter', _logout, color:Colors.red),
      ]))),
    );
  }

  Widget _navRow(String label, VoidCallback onTap, {Color? color}) => InkWell(
    onTap: onTap,
    child: Padding(padding:const EdgeInsets.symmetric(vertical:14),
      child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text(label, style:GoogleFonts.inter(fontSize:14, color: color ?? AppColors.textPrimary)),
        Icon(Icons.chevron_right, color:AppColors.textSecondary, size:20),
      ])),
  );

  Widget _navRowWithValue(String label, String value, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(padding:const EdgeInsets.symmetric(vertical:14),
      child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text(label, style:GoogleFonts.inter(fontSize:14, color:AppColors.textPrimary)),
        Row(children:[
          Text(value, style:GoogleFonts.inter(fontSize:14, color:AppColors.textSecondary)),
          const SizedBox(width:4),
          const Icon(Icons.chevron_right, color:AppColors.textSecondary, size:20),
        ]),
      ])),
  );

  Widget _toggleRow(String label, bool val, ValueChanged<bool> onChange) => Padding(
    padding: const EdgeInsets.symmetric(vertical:12),
    child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
      Text(label, style:GoogleFonts.inter(fontSize:14, color:AppColors.textPrimary)),
      Switch(value:val, onChanged:onChange, activeThumbColor:AppColors.green),
    ]),
  );
}
