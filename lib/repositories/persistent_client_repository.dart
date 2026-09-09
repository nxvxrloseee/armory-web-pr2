import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_clients.dart';
import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'client_repository.dart';
import 'local/json_list_store.dart';
import 'repository_exceptions.dart';

class PersistentClientRepository implements ClientRepository {
  PersistentClientRepository(SharedPreferences prefs)
      : _store = JsonListStore<Client>(
          key: 'clients_v1',
          prefs: prefs,
          toJson: (c) => c.toJson(),
          fromJson: Client.fromJson,
          seed: seedClients,
        );

  final JsonListStore<Client> _store;

  /// Не null, если локальные данные при старте оказались нечитаемыми и
  /// были сброшены к начальному набору — см. [JsonListStore.resetMessage].
  String? get storageResetMessage => _store.resetMessage;
  List<Client> get _clients => _store.items;

  @override
  Future<PageResult<Client>> find(ClientQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _clients.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((c) =>
              c.fullName.toLowerCase().contains(needle) ||
              c.email.toLowerCase().contains(needle))
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Client>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Client?> findById(int id) async {
    for (final c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool _emailTaken(String email, {int? excludingId}) => _clients.any(
        (c) => c.id != excludingId && c.email.toLowerCase() == email.toLowerCase(),
      );

  @override
  Future<Client> create(Client draft) async {
    if (_emailTaken(draft.email)) {
      throw UniqueConstraintException('email', 'Почта «${draft.email}» уже зарегистрирована');
    }
    final nextId =
        _clients.isEmpty ? 1 : _clients.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final withId = Client(
      id: nextId,
      fullName: draft.fullName,
      email: draft.email,
      phone: draft.phone,
      licenseNumber: draft.licenseNumber,
      licenseIssuedAt: draft.licenseIssuedAt,
      licenseExpiresAt: draft.licenseExpiresAt,
    );
    await _store.mutate((items) => items.add(withId));
    return withId;
  }

  @override
  Future<Client> update(Client client) async {
    if (_emailTaken(client.email, excludingId: client.id)) {
      throw UniqueConstraintException('email', 'Почта «${client.email}» уже зарегистрирована');
    }
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i == -1) throw StateError('Покупатель ${client.id} не найден');
    await _store.mutate(
      (items) => items[i] = client.copyWith(deletedAt: _clients[i].deletedAt),
    );
    return _clients[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Покупатель $id не найден');
    await _store.mutate((items) => items[i] = items[i].copyWith(deletedAt: DateTime.now()));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _store.mutate((items) => items.removeWhere((c) => c.id == id));
  }

  @override
  Future<void> restore(int id) async {
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Покупатель $id не найден');
    await _store.mutate((items) => items[i] = items[i].copyWith(clearDeletedAt: true));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    await _store.mutate((items) {
      for (final id in ids) {
        final i = items.indexWhere((c) => c.id == id && !c.isDeleted);
        if (i == -1) continue;
        items[i] = items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    });
    return count;
  }
}
