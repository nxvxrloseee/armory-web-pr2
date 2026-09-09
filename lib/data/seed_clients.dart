import '../models/client.dart';

final List<Client> seedClients = [
  Client(
    id: 1,
    fullName: 'Андрей Волков',
    email: 'a.volkov@example.com',
    phone: '+7 900 111-22-33',
    licenseNumber: 'RU-77-000145',
    licenseIssuedAt: DateTime(2022, 3, 10),
    licenseExpiresAt: DateTime(2027, 3, 10),
  ),
  Client(
    id: 2,
    fullName: 'Мария Кузнецова',
    email: 'm.kuznetsova@example.com',
    phone: '+7 900 222-33-44',
    licenseNumber: 'RU-77-000398',
    licenseIssuedAt: DateTime(2021, 7, 22),
    licenseExpiresAt: DateTime(2026, 7, 22),
  ),
  Client(
    id: 3,
    fullName: 'Сергей Титов',
    email: 's.titov@example.com',
    phone: '+7 900 333-44-55',
    licenseNumber: 'RU-78-001102',
    licenseIssuedAt: DateTime(2019, 1, 15),
    licenseExpiresAt: DateTime(2024, 1, 15),
  ),
];
