import 'package:flutter/foundation.dart';
import '../models/cat_model.dart';
import '../../../map_territory/models/territory_model.dart';
import '../../../constants/app_assets.dart';

class MockCatRepository extends ChangeNotifier {
  // Singleton pattern for simple state sharing across screens
  static final MockCatRepository _instance = MockCatRepository._internal();
  factory MockCatRepository() => _instance;
  MockCatRepository._internal();

  int userExpeditionPoints = 185;
  int userTotalObservations = 24;

  final List<CatModel> _cats = [
    const CatModel(
      id: 'cat_001',
      name: 'Si Oyen',
      qrHash: 'TELCAT-TULT-001',
      zone: 'Area TULT',
      locationDetail: 'Lobby Utama Gedung TULT Lt. 1',
      avatarAsset: AppAssets.catSiOyen,
      photoAsset: AppAssets.catPhotoOyen,
      healthStatus: 'Sehat & Steril',
      personality: 'Pemberani & Suka Camilan',
      friendshipLevel: 4,
      trustPercentage: 90,
      observationCount: 16,
      lastObservedDate: 'Hari ini, 10:45 WIB',
      mementoName: 'Daun Emas Situ Techno',
      mementoDescription: 'Daun kering gugur yang sering dijadikan mainan Si Oyen sebelum menyapa mahasiswa.',
      isCollected: true,
      isCurrentlyInCafe: true,
      cafePose: 'pillow',
      cafeQuote: 'Purrr... Elus daguku lagi dong, teman!',
    ),
    const CatModel(
      id: 'cat_002',
      name: 'Mochi',
      qrHash: 'TELCAT-ASRAMA-002',
      zone: 'Area Asrama',
      locationDetail: 'Teras Gazebo Asrama Putri',
      avatarAsset: AppAssets.catMochi,
      photoAsset: AppAssets.catMochi,
      healthStatus: 'Sehat & Terawat',
      personality: 'Manja & Suka Mendengkur',
      friendshipLevel: 3,
      trustPercentage: 80,
      observationCount: 11,
      lastObservedDate: 'Kemarin, 16:20 WIB',
      mementoName: 'Pita Bunga Tel-U',
      mementoDescription: 'Pita merah mungil yang pernah dipakai Mochi saat acara sambut mahasiswa baru.',
      isCollected: true,
      isCurrentlyInCafe: true,
      cafePose: 'box',
      cafeQuote: 'Kardus hangat ini adalah singgasana terbaikku!',
    ),
    const CatModel(
      id: 'cat_003',
      name: 'Kuro',
      qrHash: 'TELCAT-DANAU-003',
      zone: 'Area Danau Techno',
      locationDetail: 'Tepian Jalur Jogging Situ Techno',
      avatarAsset: AppAssets.catSiOyen,
      photoAsset: AppAssets.catPhotoOyen,
      healthStatus: 'Sehat & Lincah',
      personality: 'Misterius & Mandiri',
      friendshipLevel: 2,
      trustPercentage: 65,
      observationCount: 7,
      lastObservedDate: '3 hari lalu',
      mementoName: 'Batu Kerikil Danau',
      mementoDescription: 'Batu hitam bundar halus yang Kuro suka dorong dengan cakarnya.',
      isCollected: true,
      isCurrentlyInCafe: true,
      cafePose: 'carpet',
      cafeQuote: 'Aku suka mengamati orang lalu-lalang dari sudut tenang ini.',
    ),
    const CatModel(
      id: 'cat_004',
      name: 'Belang',
      qrHash: 'TELCAT-GKU-004',
      zone: 'Area GKU',
      locationDetail: 'Koridor Depan Gedung Kuliah Bersama Lt. 2',
      avatarAsset: AppAssets.catSiOyen,
      photoAsset: AppAssets.catPhotoOyen,
      healthStatus: 'Dalam Pantauan Relawan',
      personality: 'Waspada tapi Penasaran',
      friendshipLevel: 1,
      trustPercentage: 30,
      observationCount: 2,
      lastObservedDate: '1 minggu lalu',
      mementoName: 'Gantungan Kunci Kuliah',
      mementoDescription: 'Suvenir gantungan tas mahasiswa yang pernah dicakar ramah oleh Belang.',
      isCollected: false,
      isCurrentlyInCafe: false,
      cafePose: 'tree',
      cafeQuote: 'Ssst... aku sedang menyimak kuliah umum dari koridor!',
    ),
    const CatModel(
      id: 'cat_005',
      name: 'Boba',
      qrHash: 'TELCAT-OPLIB-005',
      zone: 'Area Perpustakaan',
      locationDetail: 'Bawah Tangga Utama Open Library',
      avatarAsset: AppAssets.catMochi,
      photoAsset: AppAssets.catMochi,
      healthStatus: 'Sehat & Gemuk',
      personality: 'Santai & Hobi Tidur',
      friendshipLevel: 1,
      trustPercentage: 15,
      observationCount: 1,
      lastObservedDate: '2 minggu lalu',
      mementoName: 'Pembatas Buku Akademik',
      mementoDescription: 'Kertas pembatas novel yang jatuh di lantai perpustakaan.',
      isCollected: false,
      isCurrentlyInCafe: false,
      cafePose: 'stool',
      cafeQuote: 'Jangan bising ya, tempat membaca buku harus tenang.',
    ),
    const CatModel(
      id: 'cat_006',
      name: 'Luna',
      qrHash: 'TELCAT-TN-006',
      zone: 'Area Tokong Nanas',
      locationDetail: 'Bawah Pohon Rindang Gedung Deli',
      avatarAsset: AppAssets.catMochi,
      photoAsset: AppAssets.catMochi,
      healthStatus: 'Sehat & Steril',
      personality: 'Ramah & Suka Dibelai',
      friendshipLevel: 2,
      trustPercentage: 70,
      observationCount: 5,
      lastObservedDate: '2 hari lalu',
      mementoName: 'Bunga Kamboja Putih',
      mementoDescription: 'Kelopak bunga harum yang sering jatuh tepat di atas kepala Luna.',
      isCollected: true,
      isCurrentlyInCafe: true,
      cafePose: 'tree',
      cafeQuote: 'Selamat pagi civitas akademika! Semangat kuliahnya ya!',
    ),
    const CatModel(
      id: 'cat_007',
      name: 'Chiko',
      qrHash: 'TELCAT-CACUK-007',
      zone: 'Area Gedung Cacuk',
      locationDetail: 'Area Parkir Dosen Barat',
      avatarAsset: AppAssets.catSiOyen,
      photoAsset: AppAssets.catPhotoOyen,
      healthStatus: 'Sehat',
      personality: 'Cepat & Gesit',
      friendshipLevel: 1,
      trustPercentage: 10,
      observationCount: 1,
      lastObservedDate: '5 hari lalu',
      mementoName: 'Tutup Botol Minum',
      mementoDescription: 'Mainan favorit Chiko saat mengejar bayangan sore hari.',
      isCollected: false,
      isCurrentlyInCafe: false,
      cafePose: 'carpet',
      cafeQuote: 'Kecepatan adalah keunggulanku!',
    ),
    const CatModel(
      id: 'cat_008',
      name: 'Milo',
      qrHash: 'TELCAT-SC-008',
      zone: 'Area Student Center',
      locationDetail: 'Depan Pintu Koperasi Mahasiswa SC',
      avatarAsset: AppAssets.catSiOyen,
      photoAsset: AppAssets.catPhotoOyen,
      healthStatus: 'Sehat & Steril',
      personality: 'Penyambut Tamu Handal',
      friendshipLevel: 3,
      trustPercentage: 85,
      observationCount: 9,
      lastObservedDate: 'Hari ini, 08:15 WIB',
      mementoName: 'Sedotan Ramah Lingkungan',
      mementoDescription: 'Sedotan kertas dari kantin SC yang selalu dibawa Milo bermain.',
      isCollected: true,
      isCurrentlyInCafe: true,
      cafePose: 'pillow',
      cafeQuote: 'Ada yang mau pesan es kopi? Mampir ke SC yuk!',
    ),
  ];

  final List<TerritoryModel> _territories = const [
    TerritoryModel(
      id: 'territory_tult',
      name: 'Zona TULT & Asrama',
      description: 'Gedung Kuliah Terpadu 19 Lantai Telkom University. Wilayah berkumpul paling ramai kucing kampus karena banyak sisa tempat teduh dan civitas yang peduli.',
      landmark: 'Menara Biru TULT & Gazebo Asrama',
      activeCatsCount: 3,
      imageAsset: AppAssets.zoneTult,
      residentCatIds: ['cat_001', 'cat_002'],
      latitude: -6.9730,
      longitude: 107.6300,
    ),
    TerritoryModel(
      id: 'territory_gku',
      name: 'Zona GKU & Fakultas',
      description: 'Kawasan Gedung Kuliah Bersama Fakultas Teknik dan Ekonomi. Kucing di zona ini sering beristirahat di tangga koridor luar yang sejuk.',
      landmark: 'Koridor Utama GKU & Kantin Baru',
      activeCatsCount: 2,
      imageAsset: AppAssets.campusMap,
      residentCatIds: ['cat_004', 'cat_007'],
      latitude: -6.9745,
      longitude: 107.6315,
    ),
    TerritoryModel(
      id: 'territory_danau',
      name: 'Zona Danau & Open Library',
      description: 'Lingkungan hijau asri di sekitar danau Situ Techno dan gedung Perpustakaan Pusat. Suasana tenang sangat cocok untuk kucing bersantai.',
      landmark: 'Danau Situ Techno & Gedung Perpustakaan',
      activeCatsCount: 2,
      imageAsset: AppAssets.campusMap,
      residentCatIds: ['cat_003', 'cat_005'],
      latitude: -6.9710,
      longitude: 107.6285,
    ),
    TerritoryModel(
      id: 'territory_sc',
      name: 'Zona Student Center & Deli',
      description: 'Pusat aktivitas organisasi mahasiswa dan UKM kampus Telkom University, selalu dipenuhi tawa dan interaksi hangat.',
      landmark: 'Gedung SC & Kantin Rindang Tokong Nanas',
      activeCatsCount: 2,
      imageAsset: AppAssets.zoneTult,
      residentCatIds: ['cat_006', 'cat_008'],
      latitude: -6.9720,
      longitude: 107.6330,
    ),
  ];

  // Getters
  List<CatModel> get allCats => List.unmodifiable(_cats);

  List<CatModel> get collectedCats =>
      _cats.where((c) => c.isCollected).toList();

  List<CatModel> get uncollectedCats =>
      _cats.where((c) => !c.isCollected).toList();

  List<CatModel> get cafeActiveCats =>
      _cats.where((c) => c.isCollected && c.isCurrentlyInCafe).toList();

  List<TerritoryModel> get territories => List.unmodifiable(_territories);

  CatModel getCatById(String id) {
    return _cats.firstWhere(
      (c) => c.id == id,
      orElse: () => _cats.first,
    );
  }

  CatModel getCatByQr(String qr) {
    return _cats.firstWhere(
      (c) => c.qrHash.toUpperCase() == qr.toUpperCase() || c.id == qr,
      orElse: () => _cats.first,
    );
  }

  TerritoryModel getTerritoryById(String id) {
    return _territories.firstWhere(
      (t) => t.id == id,
      orElse: () => _territories.first,
    );
  }

  // Action: Meluluhkan kucing & klaim observasi
  void completeEncounter({
    required String catId,
    required int earnedPoints,
    required String lastObservationDate,
  }) {
    final index = _cats.indexWhere((c) => c.id == catId);
    if (index != -1) {
      final old = _cats[index];
      _cats[index] = old.copyWith(
        isCollected: true,
        isCurrentlyInCafe: true,
        friendshipLevel: old.friendshipLevel + 1,
        trustPercentage: 100,
        observationCount: old.observationCount + 1,
        lastObservedDate: lastObservationDate,
      );
      userExpeditionPoints += earnedPoints;
      userTotalObservations += 1;
      notifyListeners();
    }
  }
}
