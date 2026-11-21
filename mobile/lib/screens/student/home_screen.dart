import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../../services/api.dart';
import '../../models/dish.dart';
import 'dish_detail_screen.dart';
import '../recharge_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceVisible = true;
  int _balance = 0;
  String _userName = '';
  List<Dish> _todayDishes = [];
  String? _menuDate;
  bool _loading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('auth_user') ?? '';
      for (final part in raw.split('|')) {
        if (part.startsWith('full_name=')) {
          _userName = part.substring(10);
        }
      }
      final me = await _api.getMe();
      _balance = (me['balance'] as int?) ?? 0;
      final todayStr = isoDate(DateTime.now());
      final menus = await _api.getMenusWeek(date: isoDate(menuReferenceDate()));
      final days = menus['days'] as List<dynamic>? ?? [];
      List<Dish> dishes = [];
      String? menuDate;
      for (final d in days) {
        final dayDate = d['date'] as String? ?? '';
        if (dayDate.compareTo(todayStr) >= 0) {
          dishes = (d['dishes'] as List<dynamic>? ?? [])
              .map((x) => Dish.fromJson(x as Map<String, dynamic>))
              .toList();
          menuDate = dayDate;
          break;
        }
      }
      if (mounted) setState(() { _todayDishes = dishes; _menuDate = menuDate; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _todayDishes = _fakeDishes(); _balance = 5000; });
    }
  }

  List<Dish> _fakeDishes() => [
    const Dish(id:1, name:'Alloco poulet braisé', description:'Banane plantain frite, poulet braisé en sauce tomate.', localAsset:'assets/images/alloco_poulet.jpg', priceFcfa:1000, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:18, visible:true),
    const Dish(id:2, name:'Attiéké poisson braisé', description:'Attiéké avec poisson braisé, accompagné de sauce tomate et salade.', localAsset:'assets/images/attieke_poisson.jpg', priceFcfa:1500, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:12, visible:true),
    const Dish(id:3, name:'Riz sauce tomate', description:'Riz blanc avec sauce tomate épicée.', localAsset:'assets/images/riz_sauce_tomate.jpg', priceFcfa:800, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:6, visible:true),
    const Dish(id:4, name:'Foutou sauce gombo', description:'Foutou banane avec sauce gombo et viande.', localAsset:'assets/images/foutou_banane.jpg', priceFcfa:1500, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:0, visible:true),
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final hero = _todayDishes.isNotEmpty ? _todayDishes[0] : null;
    final others = _todayDishes.length > 1 ? _todayDishes.sublist(1) : <Dish>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header()),
                  SliverToBoxAdapter(child: _balanceCard()),
                  if (hero != null) ...[
                    SliverToBoxAdapter(child: _sectionHeader()),
                    SliverToBoxAdapter(child: _heroCard(hero)),
                  ] else
                    SliverToBoxAdapter(child: _emptyMenu()),
                  if (others.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16,16,16,8),
                        child: Text('Aussi au menu', style: GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
                      ),
                    ),
                    SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) => _miniCard(others[i]),
                      childCount: others.length,
                    )),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16,16,16,0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_greeting()},', style: GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
          Text(_userName.isNotEmpty ? _userName.split(' ').first : 'Élève',
            style: GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        ]),
        Container(
          width:40, height:40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius:8)],
          ),
          child: const Icon(Icons.notifications_outlined, color:AppColors.textPrimary, size:20),
        ),
      ],
    ),
  );

  Widget _balanceCard() => Container(
    margin: const EdgeInsets.fromLTRB(16,16,16,0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Mon solde', style: GoogleFonts.inter(fontSize:13, color: Colors.white.withValues(alpha:0.85))),
        GestureDetector(
          onTap: () => setState(() => _balanceVisible = !_balanceVisible),
          child: Icon(_balanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color:Colors.white, size:20),
        ),
      ]),
      const SizedBox(height:4),
      Text(
        _balanceVisible ? '${_formatFcfa(_balance)} FCFA' : '• • • • •',
        style: GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:Colors.white),
      ),
      const SizedBox(height:12),
      GestureDetector(
        onTap: _openRecharge,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add, size:16, color:AppColors.textPrimary),
            const SizedBox(width:4),
            Text('Recharger', style: GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary)),
          ]),
        ),
      ),
    ]),
  );

  Widget _emptyMenu() => Container(
    margin: const EdgeInsets.fromLTRB(16,20,16,0),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      const Icon(Icons.restaurant_menu_outlined, size: 40, color: AppColors.textSecondary),
      const SizedBox(height: 12),
      Text('Aucun menu publié', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text('Les prochains plats apparaîtront ici dès que la cantine les aura publiés.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
    ]),
  );

  Widget _sectionHeader() {
    final date = _menuDate != null ? DateTime.parse(_menuDate!) : DateTime.now();
    final isToday = _menuDate == null || _menuDate == isoDate(DateTime.now());
    final days = ['Lun.','Mar.','Mer.','Jeu.','Ven.','Sam.','Dim.'];
    final months = ['jan.','fév.','mars','avr.','mai','juin','juil.','août','sept.','oct.','nov.','déc.'];
    final label = '${days[date.weekday-1]} ${date.day} ${months[date.month-1]}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16,20,16,8),
      child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text(isToday ? "Aujourd'hui" : 'Prochain menu', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        Text(label, style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
      ]),
    );
  }

  Widget _heroCard(Dish dish) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16/9,
            child: _dishImage(dish),
          ),
        ),
        const SizedBox(height:12),
        Row(crossAxisAlignment:CrossAxisAlignment.start, mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
          Expanded(child: Text(dish.name, style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:AppColors.textPrimary))),
          Text('${_formatFcfa(dish.priceFcfa)} FCFA', style:GoogleFonts.poppins(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.orange)),
        ]),
        const SizedBox(height:4),
        Text(
          '${dish.slotStart.substring(0,5)} – ${dish.slotEnd.substring(0,5)} · ${dish.availabilityLabel}',
          style: GoogleFonts.inter(fontSize:13, color: dish.isAvailable ? AppColors.green : AppColors.textSecondary),
        ),
        const SizedBox(height:12),
        ElevatedButton(
          onPressed: dish.isAvailable ? () => _openDish(dish) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: dish.isAvailable ? AppColors.orange : AppColors.surfaceHigh,
            foregroundColor: dish.isAvailable ? Colors.white : AppColors.textSecondary,
          ),
          child: Text(dish.isAvailable ? 'Réserver' : 'Épuisé'),
        ),
      ]),
    );
  }

  Future<void> _openRecharge() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => RechargeScreen(currentBalance: _balance)));
    if (mounted) _load();
  }

  Future<void> _openDish(Dish dish) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish, balance: _balance)));
    if (result is int && mounted) {
      setState(() => _balance = result);
      _load();
    }
  }

  Widget _miniCard(Dish dish) {
    return GestureDetector(
      onTap: () => _openDish(dish),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16,0,16,8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children:[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width:72, height:72, child: _dishImage(dish)),
          ),
          const SizedBox(width:12),
          Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text(dish.name, style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w600, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
            const SizedBox(height:2),
            Text('${_formatFcfa(dish.priceFcfa)} FCFA', style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.orange)),
            Text(dish.availabilityLabel,
              style:GoogleFonts.inter(fontSize:12, color: dish.isAvailable ? AppColors.green : AppColors.textSecondary)),
          ])),
          if (dish.isAvailable)
            Container(
              width:36, height:36,
              decoration: BoxDecoration(color:AppColors.orange, borderRadius:BorderRadius.circular(10)),
              child: const Icon(Icons.add, color:Colors.white, size:20),
            ),
        ]),
      ),
    );
  }

  Widget _dishImage(Dish dish) {
    if (dish.localAsset != null) {
      return Image.asset(dish.localAsset!, fit:BoxFit.cover);
    }
    if (dish.photoUrl != null) {
      return Image.network(dish.photoUrl!, fit:BoxFit.cover,
        errorBuilder:(_,__,___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    color: AppColors.surfaceHigh,
    child: const Icon(Icons.restaurant, color:AppColors.textSecondary, size:32),
  );

  String _formatFcfa(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i=0; i<s.length; i++) {
      if (i>0 && (s.length-i)%3==0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
