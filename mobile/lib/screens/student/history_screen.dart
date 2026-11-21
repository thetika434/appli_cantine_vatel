import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _tab = 0; // 0=Tout 1=Repas 2=Recharges
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  final _api = ApiService();

  static const _tabs = ['Tout', 'Repas', 'Recharges'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await _api.getTransactions();
      final list = r['transactions'] as List<dynamic>? ?? [];
      if (mounted) setState(() {
        _all = list.map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _all = _fakeData(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _fakeData() => [
    {'id':1,'type':'debit','amount_fcfa':1000,'label':'Alloco poulet braisé','created_at':'Aujourd\'hui','local_asset':'assets/images/alloco_poulet.jpg'},
    {'id':2,'type':'debit','amount_fcfa':1200,'label':'Foutou banane','created_at':'Jeu. 19','local_asset':'assets/images/foutou_banane.jpg'},
    {'id':3,'type':'credit','amount_fcfa':5000,'label':'Recharge','created_at':'Mer. 18','local_asset':null},
    {'id':4,'type':'debit','amount_fcfa':1000,'label':'Riz sauce tomate poulet','created_at':'Mer. 18','local_asset':'assets/images/riz_sauce_tomate.jpg'},
    {'id':5,'type':'debit','amount_fcfa':1500,'label':'Attiéké poisson braisé','created_at':'Mar. 17','local_asset':'assets/images/attieke_poisson.jpg'},
    {'id':6,'type':'debit','amount_fcfa':1000,'label':'Riz sauce arachide','created_at':'Lun. 16','local_asset':'assets/images/riz_sauce_arachide.jpg'},
    {'id':7,'type':'credit','amount_fcfa':2000,'label':'Recharge','created_at':'Ven. 13','local_asset':null},
    {'id':8,'type':'debit','amount_fcfa':1200,'label':'Riz cantonais poulet','created_at':'Ven. 13','local_asset':'assets/images/riz_cantonais.jpg'},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_tab == 1) return _all.where((e) => e['type'] == 'debit').toList();
    if (_tab == 2) return _all.where((e) => e['type'] == 'credit').toList();
    return _all;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children:[
        Padding(
          padding: const EdgeInsets.fromLTRB(16,16,16,12),
          child: Text('Historique', style:GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
        ),
        _tabBar(),
        Expanded(
          child: _loading
            ? const Center(child:CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16,8,16,24),
                itemCount: _filtered.length,
                separatorBuilder:(_,__) => const Divider(height:1, color:AppColors.surfaceHigh),
                itemBuilder:(_,i) => _row(_filtered[i]),
              ),
        ),
      ])),
    );
  }

  Widget _tabBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal:16),
    child: Row(children: List.generate(_tabs.length, (i) {
      final active = i == _tab;
      return GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Padding(
          padding: const EdgeInsets.only(right:20, bottom:4),
          child: Column(children:[
            Text(_tabs[i], style:GoogleFonts.poppins(fontSize:14, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.textPrimary : AppColors.textSecondary)),
            const SizedBox(height:4),
            Container(height:2, width:30, color: active ? AppColors.green : Colors.transparent),
          ]),
        ),
      );
    })),
  );

  Widget _row(Map<String, dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final amount = tx['amount_fcfa'] as int? ?? 0;
    final label = tx['label'] as String? ?? '';
    final date = tx['created_at'] as String? ?? '';
    final asset = tx['local_asset'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical:12),
      child: Row(children:[
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width:48, height:48,
            child: isCredit
              ? Container(color:AppColors.green.withValues(alpha:0.12),
                  child:const Icon(Icons.add, color:AppColors.green))
              : (asset != null ? Image.asset(asset, fit:BoxFit.cover) : Container(color:AppColors.surfaceHigh, child:const Icon(Icons.restaurant, color:AppColors.textSecondary)))),
        ),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text(label, style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
          Text(date, style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary)),
        ])),
        Text(
          isCredit ? '+ ${_fmt(amount)} FCFA' : '– ${_fmt(amount)} FCFA',
          style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700,
            color: isCredit ? AppColors.green : AppColors.red),
        ),
      ]),
    );
  }
}
