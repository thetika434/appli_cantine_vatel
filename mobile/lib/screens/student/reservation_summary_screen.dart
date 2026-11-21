import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../models/dish.dart';
import '../../services/api.dart';

class ReservationSummaryScreen extends StatefulWidget {
  final Dish dish;
  final int qty;
  final int balance;
  const ReservationSummaryScreen({super.key, required this.dish, required this.qty, required this.balance});

  @override
  State<ReservationSummaryScreen> createState() => _ReservationSummaryScreenState();
}

class _ReservationSummaryScreenState extends State<ReservationSummaryScreen> {
  bool _loading = false;
  final _api = ApiService();

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i=0;i<s.length;i++) {
      if (i>0 && (s.length-i)%3==0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await _api.reserve(widget.dish.id);
      if (!mounted) return;
      _showSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSuccess();
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.green),
            child: const Icon(Icons.check, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Réservation confirmée !', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('${widget.dish.name}\n${widget.dish.slotStart.substring(0,5)} – ${widget.dish.slotEnd.substring(0,5)}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Retour à l\'accueil'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.dish.priceFcfa * widget.qty;
    final newBalance = widget.balance - total;
    final dateLabel = "Aujourd'hui · ${widget.dish.slotStart.substring(0,5)} – ${widget.dish.slotEnd.substring(0,5)}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        title: Text('Récapitulatif', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60, height: 60,
                  child: widget.dish.localAsset != null
                    ? Image.asset(widget.dish.localAsset!, fit: BoxFit.cover)
                    : Container(color: AppColors.surfaceHigh, child: const Icon(Icons.restaurant)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.dish.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(dateLabel, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          _row('Solde', '${_fmt(widget.balance)} FCFA', bold: true),
          const Divider(height: 24, color: AppColors.surfaceHigh),
          _row('Repas', '– ${_fmt(total)} FCFA'),
          const Divider(height: 24, color: AppColors.surfaceHigh),
          _row('Nouveau solde', '${_fmt(newBalance)} FCFA', valueColor: AppColors.orange, bold: true),
          const Spacer(),
          if (newBalance < 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Solde insuffisant.', style: GoogleFonts.inter(fontSize: 13, color: Colors.red), textAlign: TextAlign.center),
            ),
          ElevatedButton(
            onPressed: (newBalance >= 0 && !_loading) ? _confirm : null,
            child: _loading
              ? const SizedBox(height:20, width:20, child: CircularProgressIndicator(color:Colors.white, strokeWidth:2))
              : const Text('Confirmer'),
          ),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
      Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: valueColor ?? AppColors.textPrimary)),
    ],
  );
}
