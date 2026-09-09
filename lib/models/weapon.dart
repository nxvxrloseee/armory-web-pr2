class Weapon {
  final int id;
  final String name;
  final String sku;
  final int year;
  final String caliber;
  final int manufacturerId;
  final List<int> categoryIds;
  final List<int> designerIds;
  final int price;
  final int stockTotal;
  final int stockAvailable;
  final DateTime? deletedAt;

  const Weapon({
    required this.id,
    required this.name,
    required this.sku,
    required this.year,
    required this.caliber,
    required this.manufacturerId,
    required this.categoryIds,
    required this.designerIds,
    required this.price,
    required this.stockTotal,
    required this.stockAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// Без параметра [clearDeletedAt] нельзя отличить «не менять поле» от
  /// «установить null»: оба случая выглядят как переданный null.
  Weapon copyWith({
    String? name,
    String? sku,
    int? year,
    String? caliber,
    int? manufacturerId,
    List<int>? categoryIds,
    List<int>? designerIds,
    int? price,
    int? stockTotal,
    int? stockAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Weapon(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      year: year ?? this.year,
      caliber: caliber ?? this.caliber,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      categoryIds: categoryIds ?? this.categoryIds,
      designerIds: designerIds ?? this.designerIds,
      price: price ?? this.price,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'year': year,
        'caliber': caliber,
        'manufacturerId': manufacturerId,
        'categoryIds': categoryIds,
        'designerIds': designerIds,
        'price': price,
        'stockTotal': stockTotal,
        'stockAvailable': stockAvailable,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  /// Устойчиво к отсутствующим/`null`/чужим по типу полям: тот же разбор
  /// в ПР4 будет применяться к ответу настоящего сервера.
  factory Weapon.fromJson(Map<String, dynamic> json) => Weapon(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        year: json['year'] as int? ?? 0,
        caliber: json['caliber'] as String? ?? '',
        manufacturerId: json['manufacturerId'] as int? ?? 0,
        categoryIds: (json['categoryIds'] as List?)?.cast<int>() ?? const [],
        designerIds: (json['designerIds'] as List?)?.cast<int>() ?? const [],
        price: json['price'] as int? ?? 0,
        stockTotal: json['stockTotal'] as int? ?? 0,
        stockAvailable: json['stockAvailable'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
