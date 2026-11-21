import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/api.dart';

class ParentHistoryScreen extends StatefulWidget {
  const ParentHistoryScreen({super.key});

  @override
  State<ParentHistoryScreen> createState() => _ParentHistoryScreenState();
}

class _ParentHistoryScreenState extends State<ParentHistoryScreen> {
  int _childTab = 0; // 0=Tous 1=Aya 2=Yao
  int _typeTab = 0;  // 0=Tout 1=Repas 2=Recharges
  List<Map<String,dynamic>> _all = [];
  bool _loading = true;
  final _api = ApiService();

  final _childLabels = ['Tous','Aya','Yao'];
  final _typeLabels = ['Tout','Repas','Recharges'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await _api.getParentTransactions();
      final list = r['transactions'] as List<dynamic>? ?? [];
      if (mounted) setState(() {
        _all = list.map((e) => e as Map<String,dynamic>).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _all = _fakeData(); _loading = false; });
    }
  }

  List<Map<String,dynamic>> _fakeData() => [
    {'type':'debit','amount_fcfa':1000,'label':'Alloco poulet braisé','student_name':'Aya','date':"Aujourd'hui",'local_asset':'assets/images/alloco_poulet.jpg'},
    {'type':'debit','amount_fcfa':1000,'label':'Wrap poulet','student_name':'Yao','date':'Jeu. 19','local_asset':'assets/images/wrap_poulet.jpg'},
    {'type':'debit','amount_fcfa':1200,'label':'Foutou banane','student_name':'Aya','date':'Jeu. 19','local_asset':'assets/images/foutou_banane.jpg'},
    {'type':'credit','amount_fcfa':5000,'label':'Recharge','student_name':'Aya','date':'Mer. 18','local_asset':null},
    {'type':'debit','amount_fcfa':1200,'label':'Riz cantonais poulet','student_name':'Yao','date':'Mer. 18','local_asset':'assets/images/riz_cantonais.jpg'},
    {'type':'debit','amount_fcfa':1000,'label':'Shawarma poulet','student_name':'Yao','date':'Mar. 17','local_asset':'assets/images/shawarma_poulet.jpg'},
    {'type':'debit','amount_fcfa':1500,'label':'Attiéké poisson braisé','student_name':'Aya','date':'Mar. 17','local_asset':'assets/images/attieke_poisson.jpg'},
    {'type':'credit','amount_fcfa':4000,'label':'Recharge','student_name':'Yao','date':'Dim. 15','local_asset':null},
  ];

  List<Map<String,dynamic>> get _filtered {
    var list = _all;
    if (_childTab == 1) list = list.where((e) => (e['student_name'] as String? ?? '').contains('Aya')).toList();
    if (_childTab == 2) list = list.where((e) => (e['student_name'] as String? ?? '').contains('Yao')).toList();
    if (_typeTab == 1) list = list.where((e) => e['type'] == 'debit').toList();
    if (_typeTab == 2) list = list.where((e) => e['type'] == 'credit').toList();
    return list;
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
      body: SafeArea(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),
          child:Text('Historique', style:GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:AppColors.textPrimary))),
        _tabs(_childLabels, _childTab, (i)=>setState(()=>_childTab=i)),
        const SizedBox(height:8),
        Padding(padding:const EdgeInsets.symmetric(horizontal:16),
          child:Row(children: List.generate(_typeLabels.length, (i) {
            final active = i == _typeTab;
            return GestureDetector(
              onTap:()=>setState(()=>_typeTab=i),
              child:Container(
                margin:const EdgeInsets.only(right:8),
                padding:const EdgeInsets.symmetric(horizontal:14, vertical:6),
                decoration:BoxDecoration(
                  color: active ? AppColors.textPrimary : AppColors.surface,
                  borderRadius:BorderRadius.circular(20),
                ),
                child:Text(_typeLabels[i], style:GoogleFonts.inter(fontSize:13, fontWeight:FontWeight.w600,
                  color: active ? Colors.white : AppColors.textPrimary)),
              ),
            );
          }))),
        const SizedBox(height:8),
        Expanded(child: _loading
          ? const Center(child:CircularProgressIndicator())
          : ListView.separated(
              padding:const EdgeInsets.fromLTRB(16,8,16,24),
              itemCount:_filtered.length,
              separatorBuilder:(_,__) => const Divider(height:1, color:AppColors.surfaceHigh),
              itemBuilder:(_,i) => _row(_filtered[i]),
            )),
      ])),
    );
  }

  Widget _tabs(List<String> labels, int selected, ValueChanged<int> onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal:16),
    child: Row(children: List.generate(labels.length, (i) {
      final active = i == selected;
      return GestureDetector(
        onTap: () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.only(right:20, bottom:4),
          child: Column(children:[
            Text(labels[i], style:GoogleFonts.poppins(fontSize:14, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.textPrimary : AppColors.textSecondary)),
            const SizedBox(height:4),
            Container(height:2, width:30, color: active ? AppColors.green : Colors.transparent),
          ]),
        ),
      );
    })),
  );

  Widget _row(Map<String,dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final amount = tx['amount_fcfa'] as int? ?? 0;
    final label = tx['label'] as String? ?? '';
    final student = tx['student_name'] as String? ?? '';
    final date = tx['date'] as String? ?? '';
    final asset = tx['local_asset'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:12),
      child: Row(children:[
        ClipRRect(borderRadius:BorderRadius.circular(10), child:SizedBox(width:48, height:48,
          child: isCredit
            ? Container(color:AppColors.green.withValues(alpha:0.12), child:const Icon(Icons.add, color:AppColors.green))
            : (asset != null ? Image.asset(asset, fit:BoxFit.cover) : Container(color:AppColors.surfaceHigh, child:const Icon(Icons.restaurant, color:AppColors.textSecondary))))),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text(label, style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
          Text('$student · $date', style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary)),
        ])),
        Text(isCredit ? '+ ${_fmt(amount)} FCFA' : '– ${_fmt(amount)} FCFA',
          style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700, color: isCredit ? AppColors.green : AppColors.red)),
      ]),
    );
  }
}
