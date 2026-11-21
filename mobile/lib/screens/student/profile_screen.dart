import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _classe = '';
  String _matricule = '';
  bool _notifReminder = true;
  bool _notifMenus = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('auth_user') ?? '';
    final map = <String,String>{};
    for (final p in raw.split('|')) {
      final idx = p.indexOf('=');
      if (idx > 0) map[p.substring(0,idx)] = p.substring(idx+1);
    }
    if (mounted) setState(() {
      _name = map['full_name'] ?? 'Élève';
      _classe = map['class'] ?? '';
      _matricule = map['matricule'] ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _initials() {
    final parts = _name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _name.isNotEmpty ? _name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: SingleChildScrollView(padding:const EdgeInsets.all(20), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        const SizedBox(height:8),
        Row(children:[
          Container(width:56, height:56,
            decoration:const BoxDecoration(shape:BoxShape.circle, color:AppColors.orange),
            alignment:Alignment.center,
            child:Text(_initials(), style:GoogleFonts.poppins(fontSize:20, fontWeight:FontWeight.w700, color:Colors.white))),
          const SizedBox(width:14),
          Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text(_name, style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
            Text('$_classe${_matricule.isNotEmpty ? ' · $_matricule' : ''}',
              style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
          ]),
        ]),
        const SizedBox(height:28),
        Text('Préférences', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        const SizedBox(height:12),
        Wrap(spacing:8, runSpacing:8, children:[
          _chip('Sans porc', active:true),
          _chip('Peu épicé', active:true),
          _chip('Végétarien'),
          _chip('Sans poisson'),
        ]),
        const SizedBox(height:8),
        Text('Allergie : arachide', style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
        const SizedBox(height:28),
        Text('Notifications', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        const SizedBox(height:8),
        _toggleRow('Rappel avant 10 h', _notifReminder, (v)=>setState(()=>_notifReminder=v)),
        const Divider(height:1, color:AppColors.surfaceHigh),
        _toggleRow('Nouveaux menus', _notifMenus, (v)=>setState(()=>_notifMenus=v)),
        const SizedBox(height:28),
        _navRow('Paramètres', Icons.settings_outlined, () {}),
        const Divider(height:1, color:AppColors.surfaceHigh),
        _navRow('Se déconnecter', Icons.logout, _logout, color:Colors.red),
      ]))),
    );
  }

  Widget _chip(String label, {bool active = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal:14, vertical:6),
    decoration: BoxDecoration(
      color: active ? AppColors.green.withValues(alpha:0.12) : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: active ? AppColors.green : AppColors.surfaceHigh),
    ),
    child: Text(label, style:GoogleFonts.inter(fontSize:13, fontWeight:FontWeight.w500,
      color: active ? AppColors.green : AppColors.textPrimary)),
  );

  Widget _toggleRow(String label, bool val, ValueChanged<bool> onChange) => Padding(
    padding: const EdgeInsets.symmetric(vertical:12),
    child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
      Text(label, style:GoogleFonts.inter(fontSize:14, color:AppColors.textPrimary)),
      Switch(value:val, onChanged:onChange, activeThumbColor:AppColors.green),
    ]),
  );

  Widget _navRow(String label, IconData icon, VoidCallback onTap, {Color? color}) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical:14),
      child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text(label, style:GoogleFonts.inter(fontSize:14, color: color ?? AppColors.textPrimary)),
        Icon(Icons.chevron_right, color:AppColors.textSecondary, size:20),
      ]),
    ),
  );
}
