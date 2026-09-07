class Weapon {
  final int id;
  final String name;
  final String sku;
  final int year;
  final String caliber;
  final int manufacturerId;
  final List<int> categoryIds;
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
      price: price ?? this.price,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
