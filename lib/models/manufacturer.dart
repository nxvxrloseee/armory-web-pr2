class Manufacturer {
  final int id;
  final String name;
  final String country;
  final int founded;
  final DateTime? deletedAt;

  const Manufacturer({
    required this.id,
    required this.name,
    required this.country,
    required this.founded,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  /// Без параметра [clearDeletedAt] нельзя отличить «не менять поле» от
  /// «установить null»: оба случая выглядят как переданный null.
  Manufacturer copyWith({
    String? name,
    String? country,
    int? founded,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Manufacturer(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      founded: founded ?? this.founded,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
