import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../../services/api.dart';
import '../../models/dish.dart';
import 'dish_detail_screen.dart';

class MenusScreen extends StatefulWidget {
  const MenusScreen({super.key});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
  final _api = ApiService();
  List<_DayData> _week = [];
  int _selectedDay = 0;
  bool _loading = true;
  int _balance = 0;

  static const _dayLabels = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
  static const _months = ['jan.','fév.','mars','avr.','mai','juin','juil.','août','sept.','oct.','nov.','déc.'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ref = menuReferenceDate();
      final me = await _api.getMe();
      final menus = await _api.getMenusWeek(date: isoDate(ref));
      final byDate = <String, List<Dish>>{};
      for (final d in menus['days'] as List<dynamic>? ?? []) {
        byDate[d['date'] as String] = (d['dishes'] as List<dynamic>? ?? [])
            .map((x) => Dish.fromJson(x as Map<String, dynamic>))
            .toList();
      }
      final mon = _monday(ref);
      final week = List.generate(5, (i) {
        final ds = isoDate(mon.add(Duration(days: i)));
        return _DayData(date: ds, dishes: byDate[ds] ?? []);
      });
      final sel = week.indexWhere((d) => d.date == isoDate(ref));
      if (mounted) {
        setState(() {
          _week = week;
          _selectedDay = sel < 0 ? 0 : sel;
          _balance = (me['balance'] as int?) ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _week = _fakeWeek(); _selectedDay = _todayIndex(); _loading = false; });
    }
  }

  int _todayIndex() {
    final wd = DateTime.now().weekday;
    return (wd - 1).clamp(0, 4);
  }

  List<_DayData> _fakeWeek() {
    final mon = _monday(DateTime.now());
    return List.generate(5, (i) {
      final d = mon.add(Duration(days: i));
      final ds = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      return _DayData(date: ds, dishes: _fakeDishes());
    });
  }

  List<Dish> _fakeDishes() => [
    const Dish(id:1, name:'Alloco poulet braisé', description:'Banane plantain frite, poulet braisé en sauce tomate.', localAsset:'assets/images/alloco_poulet.jpg', priceFcfa:1000, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:18, visible:true),
    const Dish(id:2, name:'Attiéké poisson braisé', description:'Attiéké avec poisson braisé et sauce tomate.', localAsset:'assets/images/attieke_poisson.jpg', priceFcfa:1500, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:12, visible:true),
    const Dish(id:3, name:'Riz sauce tomate', description:'Riz blanc avec sauce tomate épicée.', localAsset:'assets/images/riz_sauce_tomate.jpg', priceFcfa:800, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:6, visible:true),
    const Dish(id:4, name:'Foutou sauce gombo', description:'Foutou banane avec sauce gombo.', localAsset:'assets/images/foutou_banane.jpg', priceFcfa:1500, serveDate:'', slotStart:'12:00', slotEnd:'13:30', quantity:0, visible:true),
  ];

  DateTime _monday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  String _weekLabel() {
    if (_week.isEmpty) return '';
    final first = DateTime.parse(_week.first.date);
    final last = DateTime.parse(_week.last.date);
    return '${first.day} – ${last.day} ${_months[last.month-1]}';
  }

  String _dayNum(String date) {
    try { return DateTime.parse(date).day.toString(); } catch(_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final dishes = _week.isNotEmpty ? _week[_selectedDay.clamp(0,_week.length-1)].dishes : <Dish>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
              Text('Menus', style:GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16,4,16,12),
            child: Align(alignment:Alignment.centerLeft,
              child: Text(_weekLabel(), style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary))),
          ),
          if (_week.isNotEmpty) _daySelector(),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: dishes.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 160),
                        Center(child: Text('Pas de menu publié pour ce jour.',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary))),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16,8,16,24),
                        itemCount: dishes.length,
                        itemBuilder: (_, i) => _dishRow(dishes[i]),
                      ),
                ),
          ),
        ]),
      ),
    );
  }

  Widget _daySelector() => SizedBox(
    height: 72,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal:16),
      itemCount: _week.length,
      separatorBuilder: (_,__) => const SizedBox(width:8),
      itemBuilder: (_, i) {
        final active = i == _selectedDay;
        final num = _dayNum(_week[i].date);
        final label = _dayLabels[DateTime.parse(_week[i].date).weekday - 1];
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds:200),
            width: 56, height: 68,
            decoration: BoxDecoration(
              color: active ? AppColors.green : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
              Text(label, style:GoogleFonts.inter(fontSize:11, fontWeight:FontWeight.w500,
                color: active ? Colors.white : AppColors.textSecondary)),
              const SizedBox(height:2),
              Text(num, style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700,
                color: active ? Colors.white : AppColors.textPrimary)),
            ]),
          ),
        );
      },
    ),
  );

  Widget _dishRow(Dish dish) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder:(_)=>DishDetailScreen(dish:dish, balance:_balance)));
        if (result is int && mounted) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom:10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color:AppColors.surface, borderRadius:BorderRadius.circular(14)),
        child: Row(children:[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width:72, height:72, child:_dishImg(dish)),
          ),
          const SizedBox(width:12),
          Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
            Text(dish.name, style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w600, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
            const SizedBox(height:2),
            Text('${_fmt(dish.priceFcfa)} FCFA', style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.orange)),
            Text(dish.availabilityLabel, style:GoogleFonts.inter(fontSize:12,
              color: dish.isAvailable ? AppColors.green : AppColors.textSecondary)),
          ])),
          const SizedBox(width:8),
          if (dish.isAvailable)
            Container(
              width:36, height:36,
              decoration:BoxDecoration(color:AppColors.orange, borderRadius:BorderRadius.circular(10)),
              child:const Icon(Icons.add, color:Colors.white, size:20),
            )
          else
            const SizedBox(width:36),
        ]),
      ),
    );
  }

  Widget _dishImg(Dish dish) {
    if (dish.localAsset != null) return Image.asset(dish.localAsset!, fit:BoxFit.cover);
    if (dish.photoUrl != null) return Image.network(dish.photoUrl!, fit:BoxFit.cover, errorBuilder:(_,__,___) => _ph());
    return _ph();
  }

  Widget _ph() => Container(color:AppColors.surfaceHigh, child:const Icon(Icons.restaurant, color:AppColors.textSecondary));

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i=0;i<s.length;i++) {
      if (i>0 && (s.length-i)%3==0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _DayData {
  final String date;
  final List<Dish> dishes;
  const _DayData({required this.date, required this.dishes});
}
