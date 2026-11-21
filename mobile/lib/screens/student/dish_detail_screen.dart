import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../models/dish.dart';
import 'reservation_summary_screen.dart';

class DishDetailScreen extends StatefulWidget {
  final Dish dish;
  final int balance;
  const DishDetailScreen({super.key, required this.dish, required this.balance});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _qty = 1;

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
    final dish = widget.dish;
    final total = dish.priceFcfa * _qty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(padding: EdgeInsets.zero, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(height: 240, child: _heroImage(dish)),
            ),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(20,20,20,24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dish.name, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('${_fmt(dish.priceFcfa)} FCFA', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.orange)),
                const SizedBox(height: 12),
                if (dish.description.isNotEmpty)
                  Text(dish.description, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _infoTile('Retrait', '${dish.slotStart.substring(0,5)} – ${dish.slotEnd.substring(0,5)}')),
                  const SizedBox(width: 12),
                  Expanded(child: _infoTile('Disponible', dish.availabilityLabel, valueColor: dish.isAvailable ? AppColors.green : AppColors.textSecondary)),
                ]),
                const SizedBox(height: 16),
                Text('Allergènes : non communiqués.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ]),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20,12,20,12),
            color: AppColors.background,
            child: Row(children: [
              _qtyButton(Icons.remove, () { if (_qty > 1) setState(() => _qty--); }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('$_qty', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              _qtyButton(Icons.add, () { if (_qty < dish.quantity) setState(() => _qty++); }),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: dish.isAvailable
                    ? () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ReservationSummaryScreen(dish: dish, qty: _qty, balance: widget.balance)))
                      .then((newBal) { if (newBal is int && mounted) Navigator.of(context).pop(newBal); })
                    : null,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Ajouter · ${_fmt(total)} FCFA', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
      ),
    );
  }

  Widget _heroImage(Dish dish) {
    if (dish.localAsset != null) return Image.asset(dish.localAsset!, fit: BoxFit.cover, width: double.infinity);
    if (dish.photoUrl != null) return Image.network(dish.photoUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_,__,___) => _ph());
    return _ph();
  }

  Widget _ph() => Container(color: AppColors.surfaceHigh, child: const Icon(Icons.restaurant, size: 64, color: AppColors.textSecondary));

  Widget _infoTile(String label, String value, {Color? valueColor}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
    ]),
  );

  Widget _qtyButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: AppColors.textPrimary),
    ),
  );
}
