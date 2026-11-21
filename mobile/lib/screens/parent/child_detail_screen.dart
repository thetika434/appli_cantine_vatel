import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import '../recharge_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final List<dynamic> children;
  final int initialIndex;
  const ChildDetailScreen({super.key, required this.children, required this.initialIndex});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late int _tab;

  @override
  void initState() { super.initState(); _tab = widget.initialIndex; }

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
    final c = widget.children[_tab];
    final name = c.name as String;
    final classe = c.classe as String;
    final balance = c.balance as int;
    final id = c.id as int;

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
      ),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          if (widget.children.length > 1) _childTabs(),
          const SizedBox(height:20),
          Row(children:[
            Container(width:52, height:52,
              decoration:const BoxDecoration(shape:BoxShape.circle, color:AppColors.orange),
              alignment:Alignment.center,
              child:Text(_initials(name), style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:Colors.white))),
            const SizedBox(width:12),
            Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(name, style:GoogleFonts.poppins(fontSize:18, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
              Text('$classe · ${c.id}', style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
            ]),
          ]),
          const SizedBox(height:20),
          Text('Solde', style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
            Text('${_fmt(balance)} FCFA', style:GoogleFonts.poppins(fontSize:28, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder:(_) => RechargeScreen(studentId:id, studentName:name, currentBalance:balance))),
              child: Text('+ Recharger', style:GoogleFonts.inter(fontSize:14, color:AppColors.orange, fontWeight:FontWeight.w600)),
            ),
          ]),
          const Divider(height:28, color:AppColors.surfaceHigh),
          Text('Préférences', style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
          const SizedBox(height:6),
          Text('Sans porc · Peu épicé', style:GoogleFonts.inter(fontSize:13, color:AppColors.textSecondary)),
          const SizedBox(height:20),
          Text('Derniers repas', style:GoogleFonts.poppins(fontSize:14, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
          const SizedBox(height:8),
          Expanded(child: ListView(children:[
            _mealRow('Alloco poulet braisé', "Aujourd'hui", 1000, 'assets/images/alloco_poulet.jpg'),
            const Divider(height:1, color:AppColors.surfaceHigh),
            _mealRow('Foutou banane', 'Jeu. 19', 1200, 'assets/images/foutou_banane.jpg'),
            const Divider(height:1, color:AppColors.surfaceHigh),
            _mealRow('Riz sauce tomate poulet', 'Mer. 18', 1000, 'assets/images/riz_sauce_tomate.jpg'),
          ])),
        ]),
      )),
    );
  }

  Widget _childTabs() => Row(
    children: List.generate(widget.children.length, (i) {
      final child = widget.children[i];
      final active = i == _tab;
      return GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: Padding(
          padding: const EdgeInsets.only(right:20, bottom:4),
          child: Column(children:[
            Text(child.name.split(' ').first,
              style:GoogleFonts.poppins(fontSize:15, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.textPrimary : AppColors.textSecondary)),
            const SizedBox(height:4),
            Container(height:2, width:30, color: active ? AppColors.green : Colors.transparent),
          ]),
        ),
      );
    }),
  );

  Widget _mealRow(String name, String date, int amount, String asset) => Padding(
    padding: const EdgeInsets.symmetric(vertical:10),
    child: Row(children:[
      ClipRRect(borderRadius:BorderRadius.circular(8),
        child:Image.asset(asset, width:44, height:44, fit:BoxFit.cover,
          errorBuilder:(_,__,___) => Container(width:44,height:44,color:AppColors.surfaceHigh,child:const Icon(Icons.restaurant,color:AppColors.textSecondary)))),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(name, style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
        Text(date, style:GoogleFonts.inter(fontSize:12, color:AppColors.textSecondary)),
      ])),
      Text('– ${_fmt(amount)} FCFA', style:GoogleFonts.poppins(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.red)),
    ]),
  );

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
