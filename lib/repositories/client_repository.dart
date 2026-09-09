import '../models/client.dart';
import '../models/client_query.dart';
import 'list_repository.dart';

abstract interface class ClientRepository implements ListRepository<Client, ClientQuery> {
  Future<Client?> findById(int id);

  /// [draft.id] игнорируется — идентификатор назначает репозиторий.
  /// Бросает [UniqueConstraintException], если адрес почты уже занят.
  Future<Client> create(Client draft);

  /// Бросает [UniqueConstraintException], если адрес почты занят другой
  /// записью.
  Future<Client> update(Client client);

  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
}
