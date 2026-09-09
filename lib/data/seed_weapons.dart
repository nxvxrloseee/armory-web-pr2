import '../models/weapon.dart';

final List<Weapon> seedWeapons = [
  const Weapon(
    id: 1, name: 'Пистолет Кречет-9', sku: 'KR-P9-001', year: 2015, caliber: '9x19mm',
    manufacturerId: 1, categoryIds: [1], designerIds: [1], price: 45000, stockTotal: 12, stockAvailable: 7,
  ),
  const Weapon(
    id: 2, name: 'Пистолет Кречет-17', sku: 'KR-P17-002', year: 2019, caliber: '9x19mm',
    manufacturerId: 1, categoryIds: [1], designerIds: [1], price: 52000, stockTotal: 8, stockAvailable: 3,
  ),
  const Weapon(
    id: 3, name: 'Винтовка Норд-БР8', sku: 'NS-VR8-010', year: 2012, caliber: '7.62x54',
    manufacturerId: 2, categoryIds: [2], designerIds: [2], price: 98000, stockTotal: 5, stockAvailable: 2,
  ),
  const Weapon(
    id: 4, name: 'Винтовка Норд-Сокол', sku: 'NS-VRS-011', year: 2018, caliber: '5.45x39',
    manufacturerId: 2, categoryIds: [2], designerIds: [2], price: 87000, stockTotal: 6, stockAvailable: 4,
  ),
  const Weapon(
    id: 5, name: 'Дробовик Норд-Гром', sku: 'NS-SG12-020', year: 2010, caliber: '12/76',
    manufacturerId: 2, categoryIds: [3], designerIds: [2], price: 41000, stockTotal: 10, stockAvailable: 6,
  ),
  const Weapon(
    id: 6, name: 'Falcon M9 Compact', sku: 'FO-M9C-030', year: 2016, caliber: '9x19mm',
    manufacturerId: 3, categoryIds: [1], designerIds: [3], price: 61000, stockTotal: 9, stockAvailable: 5,
  ),
  const Weapon(
    id: 7, name: 'Falcon Sentinel-15', sku: 'FO-SNT15-031', year: 2020, caliber: '5.56x45',
    manufacturerId: 3, categoryIds: [2], designerIds: [3], price: 145000, stockTotal: 4, stockAvailable: 1,
  ),
  const Weapon(
    id: 8, name: 'Falcon Streetsweeper', sku: 'FO-SW12-032', year: 2008, caliber: '12/70',
    manufacturerId: 3, categoryIds: [3], designerIds: [3], price: 39000, stockTotal: 7, stockAvailable: 7,
  ),
  const Weapon(
    id: 9, name: 'Alpine AP-100', sku: 'AP-AP100-040', year: 2013, caliber: '9x19mm',
    manufacturerId: 4, categoryIds: [1, 6], designerIds: [4, 1], price: 72000, stockTotal: 6, stockAvailable: 2,
  ),
  const Weapon(
    id: 10, name: 'Alpine Jagdgewehr-7', sku: 'AP-JG7-041', year: 2005, caliber: '.308 Win',
    manufacturerId: 4, categoryIds: [2, 6], designerIds: [4], price: 132000, stockTotal: 3, stockAvailable: 3,
  ),
  const Weapon(
    id: 11, name: 'Solar SDW-Compakt', sku: 'SDW-CMP-050', year: 2017, caliber: '9x19mm',
    manufacturerId: 5, categoryIds: [4], designerIds: [5], price: 68000, stockTotal: 5, stockAvailable: 0,
  ),
  const Weapon(
    id: 12, name: 'Solar Viper-PDW', sku: 'SDW-VPR-051', year: 2021, caliber: '9x19mm',
    manufacturerId: 5, categoryIds: [4], designerIds: [5], price: 74000, stockTotal: 4, stockAvailable: 4,
  ),
  const Weapon(
    id: 13, name: 'Ironclad Trailblazer', sku: 'IC-TB-060', year: 1998, caliber: '12/70',
    manufacturerId: 6, categoryIds: [3], designerIds: [6], price: 33000, stockTotal: 11, stockAvailable: 9,
  ),
  const Weapon(
    id: 14, name: 'Ironclad Ranger-30', sku: 'IC-RG30-061', year: 2004, caliber: '.30-06',
    manufacturerId: 6, categoryIds: [2], designerIds: [6], price: 91000, stockTotal: 6, stockAvailable: 5,
  ),
  const Weapon(
    id: 15, name: 'Ironclad Bowie Classic', sku: 'IC-BWC-062', year: 1990, caliber: '—',
    manufacturerId: 6, categoryIds: [5], designerIds: [6], price: 8500, stockTotal: 20, stockAvailable: 18,
  ),
  const Weapon(
    id: 16, name: 'Полярная Сталь Барс', sku: 'PS-BARS-070', year: 2011, caliber: '9x18mm',
    manufacturerId: 7, categoryIds: [1], designerIds: [2], price: 38000, stockTotal: 8, stockAvailable: 3,
  ),
  const Weapon(
    id: 17, name: 'Полярная Сталь Клинок-М', sku: 'PS-KLM-071', year: 1985, caliber: '—',
    manufacturerId: 7, categoryIds: [5], designerIds: [2], price: 6200, stockTotal: 15, stockAvailable: 14,
  ),
  const Weapon(
    id: 18, name: 'Meridian Duetto-12', sku: 'MRD-D12-080', year: 2003, caliber: '12/76',
    manufacturerId: 8, categoryIds: [3], designerIds: [6], price: 105000, stockTotal: 3, stockAvailable: 1,
  ),
  const Weapon(
    id: 19, name: 'Meridian Ottica-4x', sku: 'MRD-OPT4-081', year: 2022, caliber: '—',
    manufacturerId: 8, categoryIds: [6], designerIds: [6], price: 18500, stockTotal: 12, stockAvailable: 10,
  ),
  const Weapon(
    id: 20, name: 'Meridian Falco-9', sku: 'MRD-F9-082', year: 2014, caliber: '9x19mm',
    manufacturerId: 8, categoryIds: [1], designerIds: [6], price: 56000, stockTotal: 7, stockAvailable: 4,
  ),
  const Weapon(
    id: 21, name: 'Кречет Тактик', sku: 'KR-TAK-090', year: 2022, caliber: '7.62x39',
    manufacturerId: 1, categoryIds: [2], designerIds: [1], price: 112000, stockTotal: 4, stockAvailable: 2,
  ),
  const Weapon(
    id: 22, name: 'Falcon Prism-6x', sku: 'FO-PR6-091', year: 2019, caliber: '—',
    manufacturerId: 3, categoryIds: [6], designerIds: [3, 6], price: 27000, stockTotal: 9, stockAvailable: 6,
  ),
];
