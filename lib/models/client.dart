/// Покупатель и его лицензия на приобретение оружия — связь один к одному.
///
/// Отдельной сущности/репозитория/экрана для лицензии нет: по методичке
/// (раздел 3.3) 1:1 реализуется вложенной группой полей прямо в форме
/// владельца связи, поэтому её атрибуты (license*) свёрнуты в модель
/// Client, а не вынесены в шестую сущность.
class Client {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String licenseNumber;
  final DateTime licenseIssuedAt;
  final DateTime licenseExpiresAt;
  final DateTime? deletedAt;

  const Client({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.licenseIssuedAt,
    required this.licenseExpiresAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  bool get isLicenseExpired => licenseExpiresAt.isBefore(DateTime.now());

  Client copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? licenseNumber,
    DateTime? licenseIssuedAt,
    DateTime? licenseExpiresAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseIssuedAt: licenseIssuedAt ?? this.licenseIssuedAt,
      licenseExpiresAt: licenseExpiresAt ?? this.licenseExpiresAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'licenseNumber': licenseNumber,
        'licenseIssuedAt': licenseIssuedAt.toIso8601String(),
        'licenseExpiresAt': licenseExpiresAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        licenseNumber: json['licenseNumber'] as String? ?? '',
        licenseIssuedAt: json['licenseIssuedAt'] == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(json['licenseIssuedAt'] as String),
        licenseExpiresAt: json['licenseExpiresAt'] == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(json['licenseExpiresAt'] as String),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
      );
}
