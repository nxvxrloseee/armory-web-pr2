import '../models/category.dart';

/// Категории оружия — небольшой статичный справочник (не отдельная сущность
/// со своим списком/карточкой, а простая таблица соответствия id -> название,
/// как жанры книг в примере методички).
const List<Category> categories = [
  Category(id: 1, name: 'Пистолеты'),
  Category(id: 2, name: 'Винтовки'),
  Category(id: 3, name: 'Дробовики'),
  Category(id: 4, name: 'Пистолеты-пулемёты'),
  Category(id: 5, name: 'Ножи'),
  Category(id: 6, name: 'Оптика и аксессуары'),
];

String categoryName(int id) {
  for (final c in categories) {
    if (c.id == id) return c.name;
  }
  return '—';
}
