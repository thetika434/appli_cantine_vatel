import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../../services/api.dart';
import '../recharge_screen.dart';
import 'child_detail_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  String _parentName = 'Mme Koffi';
  List<_Child> _children = [];
  List<Map<String, dynamic>> _recent = [];
  bool _loading = true;
  final _api = ApiService();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('auth_user') ?? '';
      for (final p in raw.split('|')) {
        if (p.startsWith('full_name=')) _parentName = p.substring(10);
      }
      final r = await _api.getParentChildren();
      final list = r['children'] as List<dynamic>? ?? [];
      List<_Child> children = list.map((c) {
        final s = c['student'] as Map<String, dynamic>;
        return _Child(
          id: s['id'] as int,
          name: s['full_name'] as String,
          classe: s['class'] as String? ?? '',
          balance: c['balance'] as int? ?? 0,
        );
      }).toList();
      final txR = await _api.getParentTransactions();
      final txList = (txR['transactions'] as List<dynamic>? ?? []).take(5).map((e) => e as Map<String, dynamic>).toList();
      if (mounted) setState(() { _children = children; _recent = txList; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        _children = [
          _Child(id:2, name:'Aya Koffi', classe:'Terminale D', balance:4500),
          _Child(id:3, name:'Yao Koffi', classe:'2nde B', balance:500),
        ];
        _recent = _fakeRecent();
        _loading = false;
      });
    }
  }

  List<Map<String,dynamic>> _fakeRecent() => [
    {'label':'Alloco poulet','student_name':'Aya','date':"Aujourd'hui",'type':'debit','amount_fcfa':1000,'local_asset':'assets/images/alloco_poulet.jpg'},
    {'label':'Wrap poulet','student_name':'Yao','date':'Hier','type':'debit','amount_fcfa':1000,'local_asset':'assets/images/wrap_poulet.jpg'},
    {'label':'Recharge Aya','student_name':'Aya','date':'Mer. 18','type':'credit','amount_fcfa':5000,'local_asset':null},
  ];

  Future<void> _openRecharge(_Child child) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => RechargeScreen(studentId: child.id, studentName: child.name, currentBalance: child.balance)));
    if (mounted) _load();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i=0;i<s.length;i++) {
      if (i>0 && (s.length-i)%3==0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final lowBalance = _children.where((c) => c.balance < 1000).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _loading
        ? const Center(child:CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                const SizedBox(height:8),
                Text(_greeting(), style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
                Text(_parentName, style:GoogleFonts.poppins(fontSize:24, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
                const SizedBox(height:24),
                Text('Mes enfants', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
                const SizedBox(height:12),
                ..._children.map((c) => _childRow(c)),
                if (lowBalance.isNotEmpty) ...[
                  const SizedBox(height:12),
                  ElevatedButton(
                    onPressed: () => _openRecharge(lowBalance.first),
                    child: Text('+ Recharger ${lowBalance.first.name.split(' ').first}'),
                  ),
                ],
                const SizedBox(height:28),
                Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
                  Text('Récemment', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
                  Text('Tout voir', style:GoogleFonts.inter(fontSize:13, color:AppColors.orange, fontWeight:FontWeight.w600)),
                ]),
                const SizedBox(height:12),
                ..._recent.map((tx) => _txRow(tx)),
                const SizedBox(height:16),
              ]),
            ),
          )),
    );
  }

  Widget _childRow(_Child c) {
    final low = c.balance < 1000;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder:(_) => ChildDetailScreen(children:_children, initialIndex:_children.indexOf(c)))),
      child: Container(
        margin: const EdgeInsets.only(bottom:8),
        padding: const EdgeInsets.symmetric(horizontal:16, vertical:14),
        decoration:BoxDecoration(color:AppColors.surface, borderRadius:BorderRadius.circular(14)),
        child: Row(children:[
          Container(width:40, height:40,
            decoration:const BoxDecoration(shape:BoxShape.circle, color:AppColors.surfaceHigh),
            alignment:Alignment.center,
            child:Text(_initials(c.name), style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w700, color:AppColors.textPrimary))),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text(c.name.split(' ').first, style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w600, color:AppColors.textPrimary)),
            Text(low ? 'Solde faible' : c.classe,
              style:GoogleFonts.inter(fontSize:12, color: low ? AppColors.orange : AppColors.textSecondary)),
          ])),
          Text('${_fmt(c.balance)} FCFA',
            style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w700, color: low ? AppColors.orange : AppColors.textPrimary)),
          const SizedBox(width:4),
          const Icon(Icons.chevron_right, color:AppColors.textSecondary, size:18),
        ]),
      ),
    );
  }

  Widget _txRow(Map<String,dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final amount = tx['amount_fcfa'] as int? ?? 0;
    final label = tx['label'] as String? ?? '';
    final student = tx['student_name'] as String? ?? '';
    final date = tx['date'] as String? ?? '';
    final asset = tx['local_asset'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:8),
      child: Row(children:[
        ClipRRect(borderRadius:BorderRadius.circular(10),
          child:SizedBox(width:48, height:48,
            child: isCredit
              ? Container(color:AppColors.green.withValues(alpha:0.12), child:const Icon(Icons.add, color:AppColors.green))
              : (asset != null ? Image.asset(asset, fit:BoxFit.cover) : Container(color:AppColors.surfaceHigh, child:const Icon(Icons.restaurant, color:AppColors.textSecondary))))),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text('$student · $label', style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
          Text(date, style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary)),
        ])),
        Text(isCredit ? '+ ${_fmt(amount)} FCFA' : '– ${_fmt(amount)} FCFA',
          style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700, color: isCredit ? AppColors.green : AppColors.red)),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _Child {
  final int id;
  final String name;
  final String classe;
  final int balance;
  const _Child({required this.id, required this.name, required this.classe, required this.balance});
}
