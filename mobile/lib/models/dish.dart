String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Le week-end, la cantine est fermée : on affiche la semaine suivante.
DateTime menuReferenceDate([DateTime? now]) {
  final d = now ?? DateTime.now();
  return d.weekday >= DateTime.saturday ? d.add(Duration(days: 8 - d.weekday)) : d;
}

class Dish {
  final int id;
  final String name;
  final String description;
  final String? photoUrl;
  final String? localAsset;
  final int priceFcfa;
  final String serveDate;
  final String slotStart;
  final String slotEnd;
  final int quantity;
  final bool visible;

  const Dish({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    this.localAsset,
    required this.priceFcfa,
    required this.serveDate,
    required this.slotStart,
    required this.slotEnd,
    required this.quantity,
    required this.visible,
  });

  static const _assetsByKeyword = [
    ('alloco', 'alloco_poulet.jpg'),
    ('attiéké', 'attieke_poisson.jpg'),
    ('attieke', 'attieke_poisson.jpg'),
    ('foutou', 'foutou_banane.jpg'),
    ('klaklo', 'klaklo.jpg'),
    ('wrap', 'wrap_poulet.jpg'),
    ('shawarma', 'shawarma_poulet.jpg'),
    ('igname frite poulet', 'igname_frite_poulet.jpg'),
    ('igname', 'igname_frite.jpg'),
    ('cantonais', 'riz_cantonais.jpg'),
    ('haricot', 'riz_haricot.jpg'),
    ('arachide', 'riz_sauce_arachide.jpg'),
    ('boeuf', 'riz_boeuf.jpg'),
    ('bœuf', 'riz_boeuf.jpg'),
    ('légume', 'riz_legumes.jpg'),
    ('legume', 'riz_legumes.jpg'),
    ('feuille', 'riz_legumes.jpg'),
    ('riz', 'riz_sauce_tomate.jpg'),
  ];

  static String? assetFor(String name) {
    final n = name.toLowerCase();
    for (final (keyword, file) in _assetsByKeyword) {
      if (n.contains(keyword)) return 'assets/images/$file';
    }
    return null;
  }

  factory Dish.fromJson(Map<String, dynamic> j) => Dish(
        id: j['id'] as int,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        photoUrl: j['photo_url'] as String?,
        localAsset: assetFor(j['name'] as String),
        priceFcfa: j['price_fcfa'] as int,
        serveDate: j['serve_date'] as String,
        slotStart: j['slot_start'] as String,
        slotEnd: j['slot_end'] as String,
        quantity: j['quantity'] as int,
        visible: j['visible'] as bool? ?? true,
      );

  String get availabilityLabel {
    if (quantity == 0) return 'Épuisé';
    if (quantity <= 6) return 'Plus que $quantity';
    return '$quantity restantes';
  }

  bool get isAvailable => quantity > 0;
}

class Transaction {
  final int id;
  final String type;
  final int amountFcfa;
  final String label;
  final String createdAt;
  final String? dishAsset;

  const Transaction({
    required this.id,
    required this.type,
    required this.amountFcfa,
    required this.label,
    required this.createdAt,
    this.dishAsset,
  });

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as int,
        type: j['type'] as String,
        amountFcfa: j['amount_fcfa'] as int,
        label: j['label'] as String? ?? '',
        createdAt: j['created_at'] as String,
      );
}
