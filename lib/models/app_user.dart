import 'role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.clientId,
  });

  final int id;
  final String username;
  final String fullName;
  final Role role;
  final int? clientId;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] is int ? json['id'] as int : 0,
        username: json['username']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        role: Role.fromWire(json['role']?.toString() ?? 'buyer'),
        clientId: json['clientId'] is int ? json['clientId'] as int : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'role': role.wireValue,
        if (clientId != null) 'clientId': clientId,
      };
}
