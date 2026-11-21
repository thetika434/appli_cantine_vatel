import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../../services/api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _classe = '';
  String _matricule = '';

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
    if (mounted) {
      setState(() {
        _name = map['full_name'] ?? 'Élève';
        _classe = map['class'] ?? '';
      });
    }
    try {
      final user = (await ApiService().getMe())['user'] as Map<String, dynamic>?;
      if (user != null && mounted) {
        setState(() {
          _name = user['full_name'] as String? ?? _name;
          _classe = user['class'] as String? ?? _classe;
          _matricule = user['matricule'] as String? ?? '';
        });
      }
    } catch (_) {}
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
          Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text(_name, style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
            Text('$_classe${_matricule.isNotEmpty ? ' · $_matricule' : ''}',
              style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
          ])),
        ]),
        const SizedBox(height:32),
        InkWell(
          onTap: _logout,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical:14),
            child: Row(children:[
              const Icon(Icons.logout, color:AppColors.red, size:20),
              const SizedBox(width:12),
              Expanded(child: Text('Se déconnecter', style:GoogleFonts.inter(fontSize:15, fontWeight:FontWeight.w500, color:AppColors.red))),
              const Icon(Icons.chevron_right, color:AppColors.textSecondary, size:20),
            ]),
          ),
        ),
      ]))),
    );
  }
}
