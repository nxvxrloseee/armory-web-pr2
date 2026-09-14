class Order {
  const Order({
    required this.id,
    required this.clientId,
    required this.weaponId,
    required this.status,
    this.serialNumber,
    required this.createdAt,
    this.pickedUpAt,
    required this.clientName,
    required this.weaponName,
    required this.price,
  });

  final int id;
  final int clientId;
  final int weaponId;
  final String status; // ordered | picked_up | cancelled
  final String? serialNumber;
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final String clientName;
  final String weaponName;
  final int price;

  bool get isOrdered => status == 'ordered';

  String get statusLabel => switch (status) {
        'ordered' => 'Оформлен',
        'picked_up' => 'Выдан',
        'cancelled' => 'Отменён',
        _ => status,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] is int ? json['id'] as int : 0,
        clientId: json['clientId'] is int ? json['clientId'] as int : 0,
        weaponId: json['weaponId'] is int ? json['weaponId'] as int : 0,
        status: json['status']?.toString() ?? 'ordered',
        serialNumber: json['serialNumber']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        pickedUpAt: json['pickedUpAt'] == null ? null : DateTime.tryParse(json['pickedUpAt'].toString()),
        clientName: json['clientName']?.toString() ?? '',
        weaponName: json['weaponName']?.toString() ?? '',
        price: json['price'] is int ? json['price'] as int : 0,
      );
}
