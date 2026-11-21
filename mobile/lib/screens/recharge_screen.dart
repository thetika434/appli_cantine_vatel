import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api.dart';

class RechargeScreen extends StatefulWidget {
  final int? studentId;
  final String? studentName;
  final int currentBalance;

  const RechargeScreen({super.key, this.studentId, this.studentName, this.currentBalance = 0});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  static const _presets = [1000, 2000, 5000, 10000];
  int? _selected = 5000;
  final _customCtrl = TextEditingController();
  final String _channel = 'waveCI';
  bool _loading = false;
  final _api = ApiService();

  @override
  void dispose() { _customCtrl.dispose(); super.dispose(); }

  int get _amount {
    if (_selected != null) return _selected!;
    return int.tryParse(_customCtrl.text) ?? 0;
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

  Future<void> _pay() async {
    if (_amount <= 0) return;
    setState(() => _loading = true);
    try {
      await _api.initiateRecharge(
        amount: _amount,
        phone: '0700000000',
        channel: _channel,
        studentId: widget.studentId,
      );
      if (!mounted) return;
      _showSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSuccess();
    }
  }

  void _showSuccess() {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width:64, height:64,
            decoration:const BoxDecoration(shape:BoxShape.circle, color:AppColors.green),
            child:const Icon(Icons.check, color:Colors.white, size:36)),
          const SizedBox(height:16),
          Text('Recharge en cours !', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary), textAlign:TextAlign.center),
          const SizedBox(height:8),
          Text('Le solde sera mis à jour\nautomatiquement.', style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary), textAlign:TextAlign.center),
          const SizedBox(height:20),
          ElevatedButton(onPressed:()=>Navigator.of(context).pop(), child:const Text('OK')),
        ]),
      ),
    ).then((_) => nav.pop());
  }

  @override
  Widget build(BuildContext context) {
    final newBalance = widget.currentBalance + _amount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin:const EdgeInsets.all(8),
            decoration:BoxDecoration(color:AppColors.surface, borderRadius:BorderRadius.circular(12)),
            child:const Icon(Icons.chevron_left, color:AppColors.textPrimary, size:28)),
        ),
        title: Text('Recharger', style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment:CrossAxisAlignment.stretch, children:[
          Text('Solde : ${_fmt(widget.currentBalance)} FCFA',
            style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
          const SizedBox(height:20),
          Text('${_fmt(_amount > 0 ? _amount : 0)} FCFA',
            style:GoogleFonts.poppins(fontSize:36, fontWeight:FontWeight.w800, color:AppColors.textPrimary),
            textAlign:TextAlign.center),
          const SizedBox(height:20),
          Row(children: _presets.map((p) {
            final active = _selected == p;
            return Expanded(child: GestureDetector(
              onTap: () { setState(() { _selected = p; _customCtrl.clear(); }); },
              child: Container(
                margin: const EdgeInsets.only(right:8),
                padding: const EdgeInsets.symmetric(vertical:12),
                decoration:BoxDecoration(
                  color: active ? AppColors.green : AppColors.surface,
                  borderRadius:BorderRadius.circular(12),
                ),
                alignment:Alignment.center,
                child:Text('${_fmt(p)}', style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600,
                  color: active ? Colors.white : AppColors.textPrimary)),
              ),
            ));
          }).toList()),
          const SizedBox(height:12),
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() { _selected = null; }),
            decoration: InputDecoration(
              hintText: 'Autre montant',
              hintStyle: GoogleFonts.inter(color:AppColors.textSecondary),
              suffixText: 'FCFA',
              suffixStyle: GoogleFonts.inter(color:AppColors.textSecondary, fontWeight:FontWeight.w600),
            ),
          ),
          const SizedBox(height:20),
          _operatorTile('assets/images/wave.png', 'Wave'),
          const SizedBox(height:16),
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
            Text('Nouveau solde', style:GoogleFonts.inter(fontSize:14, color:AppColors.textSecondary)),
            Text('${_fmt(newBalance > 0 ? newBalance : widget.currentBalance)} FCFA',
              style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.green)),
          ]),
          const Spacer(),
          ElevatedButton(
            onPressed: (_amount > 0 && !_loading) ? _pay : null,
            child: _loading
              ? const SizedBox(height:20, width:20, child:CircularProgressIndicator(color:Colors.white, strokeWidth:2))
              : Text('Payer ${_fmt(_amount > 0 ? _amount : 0)} FCFA'),
          ),
          const SizedBox(height:8),
          Text('Paiement simulé', style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary), textAlign:TextAlign.center),
        ]),
      ),
    );
  }

  Widget _operatorTile(String asset, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:BoxDecoration(
        color: AppColors.surface,
        borderRadius:BorderRadius.circular(14),
        border:Border.all(color: AppColors.green, width:2),
      ),
      child:Row(children:[
        ClipRRect(borderRadius:BorderRadius.circular(8),
          child:Image.asset(asset, width:36, height:36, fit:BoxFit.contain,
            errorBuilder:(_,__,___) => Container(width:36, height:36, color:AppColors.surfaceHigh))),
        const SizedBox(width:8),
        Text(label, style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary)),
      ]),
    );
  }
}
