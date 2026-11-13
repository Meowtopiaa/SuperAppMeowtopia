import '../../cat/data/cat_model.dart';
import 'adoption_constants.dart';
import 'adoption_enums.dart';
import 'adoption_model.dart';
import 'adoption_repository.dart';

/// Implementasi Mock Repository dengan Data Tiruan Lengkap & Kasus Uji Sesuai PRD
class MockAdoptionRepository implements AdoptionRepository {
  /// Flag untuk simulasi jaringan gagal (diuji di unit/widget test)
  bool simulateNetworkError = false;

  /// User type aktif untuk simulasi (mahasiswa, dosen, staf)
  String currentUserType = 'mahasiswa';
  String currentUserName = 'M. Helmi Afriza';
  String currentUserEmail = 'helmi.afriza@student.telkomuniversity.ac.id';
  String currentUserId = 'USR-MAHASISWA-001';

  // In-memory data store
  final List<CatModel> _readyCats = [];
  final Map<int, AdoptionExtraCat> _catExtras = {};
  final List<AdoptionApplicationModel> _applications = [];
  final List<ActiveAdoptionModel> _activeAdoptions = [];
  final Map<int, List<AdoptionFollowupModel>> _followups = {};
  final List<AdoptionIssueReportModel> _issueReports = [];
  final Map<String, AdoptionPickupLockModel> _pickupLocks = {};

  MockAdoptionRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // 1. Kucing Siap Adopsi (ADP-05) - nama fiktif kampus
    _readyCats.addAll([
      CatModel(
        id: 101,
        name: 'Miko Selasar',
        qrCodeToken: 'MTP1.C.MIKO101',
        gender: 'male',
        breed: 'Domestik Campuran',
        primaryColor: 'Putih Belang Oranye',
        pattern: 'Tuxedo Bicolor',
        sterilizationStatus: true,
        healthStatus: 'healthy',
        adoptionStatus: 'ready',
        description:
            'Kucing ramah dan aktif yang sering menyapa mahasiswa di selasar gedung kuliah. Sangat suka dibelai dan bersahabat.',
        lastSeenLocationName: 'Selasar Gedung Utama',
      ),
      CatModel(
        id: 102,
        name: 'Luna Taman Asrama',
        qrCodeToken: 'MTP1.C.LUNA102',
        gender: 'female',
        breed: 'Domestik Short Hair',
        primaryColor: 'Calico Tiga Warna',
        pattern: 'Calico',
        sterilizationStatus: true,
        healthStatus: 'healthy',
        adoptionStatus: 'ready',
        description:
            'Kucing betina anggun yang tenang dan suka tempat hangat. Sudah divaksin lengkap dan steril.',
        lastSeenLocationName: 'Taman Asrama Barat',
      ),
      CatModel(
        id: 103,
        name: 'Boni Kantin Barat',
        qrCodeToken: 'MTP1.C.BONI103',
        gender: 'male',
        breed: 'Domestik Tabby',
        primaryColor: 'Abu-Abu Loreng',
        pattern: 'Classic Mackerel Tabby',
        sterilizationStatus: true,
        healthStatus: 'healthy',
        adoptionStatus: 'ready',
        description:
            'Boni lincah dan pintar bergaul dengan kucing lain. Siap menjadi sahabat setia di rumah baru.',
        lastSeenLocationName: 'Area Kantin Barat Kampus',
      ),
      CatModel(
        id: 104,
        name: 'Kiko Perpus',
        qrCodeToken: 'MTP1.C.KIKO104',
        gender: 'female',
        breed: 'Domestik',
        primaryColor: 'Kuning Jahe',
        pattern: 'Ginger Tabby',
        sterilizationStatus: true,
        healthStatus: 'healthy',
        adoptionStatus: 'ready',
        description:
            'Kiko sangat tenang, cocok bagi keluarga atau adopter yang mencari ketenangan. Suka tidur dekat jendela.',
        lastSeenLocationName: 'Balkon Perpustakaan Pusat',
      ),
    ]);

    // Data ekstra untuk modul adopsi
    _catExtras[101] = const AdoptionExtraCat(
      catId: 101,
      readyReason: 'Telah selesai observasi kesehatan & sterilisasi 14 hari penuh.',
      personalityNote: 'Manja, aktif bermain tali pancingan, suka dipangku.',
      locationArea: 'Zona Selasar Kampus',
      tags: ['Sudah Steril', 'Vaksin F3 Lengkap', 'Ramah'],
    );
    _catExtras[102] = const AdoptionExtraCat(
      catId: 102,
      readyReason: 'Siap diadopsi setelah pemulihan sterilisasi selesai.',
      personalityNote: 'Tenang, mandiri, cocok untuk lingkungan kos tenang.',
      locationArea: 'Area Asrama Barat',
      tags: ['Sudah Steril', 'Vaksin F4', 'Tenang'],
    );
    _catExtras[103] = const AdoptionExtraCat(
      catId: 103,
      readyReason: 'Telah lolos uji sosialisasi dan vaksinasi tahunan.',
      personalityNote: 'Suka diajak bercanda, pandai menggunakan litter box.',
      locationArea: 'Area Kantin',
      tags: ['Sudah Steril', 'Litter Trained'],
    );
    _catExtras[104] = const AdoptionExtraCat(
      catId: 104,
      readyReason: 'Disetujui dokter hewan shelter kampus untuk adopsi.',
      personalityNote: 'Penyayang, pendiam, suka dielus di dagu.',
      locationArea: 'Area Perpustakaan',
      tags: ['Sudah Steril', 'Pendiam'],
    );

    // 2. Daftar Pengajuan Kelayakan dengan Semua Status (ADP-01..04)
    // 2.a. REVISION_REQUESTED: Ada catatan admin, bisa kirim ulang
    _applications.add(
      AdoptionApplicationModel(
        id: 201,
        catId: 102,
        catName: 'Luna Taman Asrama',
        applicantName: currentUserName,
        applicantEmail: currentUserEmail,
        applicantUserType: 'mahasiswa',
        housingType: 'kos',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Akan memelihara di kamar kos berlantai dua yang tenang.',
        homePhotoPath: 'mock://evidence/room_sample.jpg',
        commitmentVersion: 'v1.0',
        commitmentAccepted: true,
        commitmentAcceptedAt: now.subtract(const Duration(days: 3)),
        precheckPassed: true, // Otomatis lolos precheck
        status: ApplicationStatus.REVISION_REQUESTED,
        adminNotes:
            'Mohon lampirkan foto sirkulasi jendela dan surat keterangan izin tertulis dari pemilik kos.',
        createdAt: now.subtract(const Duration(days: 4)),
        submittedAt: now.subtract(const Duration(days: 3)),
        cat: _readyCats[1],
      ),
    );

    // 2.b. SUBMITTED: Menunggu review admin
    _applications.add(
      AdoptionApplicationModel(
        id: 202,
        catId: 101,
        catName: 'Miko Selasar',
        applicantName: currentUserName,
        applicantEmail: currentUserEmail,
        applicantUserType: 'mahasiswa',
        housingType: 'rumah_kontrakan',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Tinggal bersama rekan mahasiswa pecinta kucing.',
        homePhotoPath: 'mock://evidence/home_gate.jpg',
        commitmentVersion: 'v1.0',
        commitmentAccepted: true,
        commitmentAcceptedAt: now.subtract(const Duration(days: 1)),
        precheckPassed: true,
        status: ApplicationStatus.SUBMITTED,
        adminNotes: null,
        createdAt: now.subtract(const Duration(days: 1)),
        submittedAt: now.subtract(const Duration(days: 1)),
        cat: _readyCats[0],
      ),
    );

    // 2.c. APPROVED: Disetujui admin, SIAP PICKUP (Bukan adopsi aktif)
    _applications.add(
      AdoptionApplicationModel(
        id: 203,
        catId: 103,
        catName: 'Boni Kantin Barat',
        applicantName: currentUserName,
        applicantEmail: currentUserEmail,
        applicantUserType: 'mahasiswa',
        housingType: 'rumah_pribadi',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Rumah keluarga dengan pagar aman dan halaman terlindung.',
        homePhotoPath: 'mock://evidence/living_room.jpg',
        commitmentVersion: 'v1.0',
        commitmentAccepted: true,
        commitmentAcceptedAt: now.subtract(const Duration(days: 2)),
        precheckPassed: true,
        status: ApplicationStatus.APPROVED,
        adminNotes:
            'Pengajuan disetujui. Silakan lakukan pengambilan di Shelter Kampus dalam batas waktu 48 jam dengan memindai QR kalung.',
        createdAt: now.subtract(const Duration(days: 5)),
        submittedAt: now.subtract(const Duration(days: 4)),
        cat: _readyCats[2],
      ),
    );

    // 2.d. DRAFT: Draf formulir tanpa memilih kucing (ADP-02)
    _applications.add(
      AdoptionApplicationModel(
        id: 204,
        catId: null,
        catName: null,
        applicantName: currentUserName,
        applicantEmail: currentUserEmail,
        applicantUserType: 'mahasiswa',
        housingType: 'kos',
        financialReadiness: true,
        familyPermission: false,
        longTermPlan: 'Masih menunggu kepastian izin pemilik kos bulan depan.',
        homePhotoPath: null,
        commitmentVersion: 'v1.0',
        commitmentAccepted: false,
        precheckPassed: false,
        status: ApplicationStatus.DRAFT,
        adminNotes: null,
        createdAt: now.subtract(const Duration(hours: 12)),
        submittedAt: null,
        cat: null,
      ),
    );

    // 2.e. REJECTED: Pengajuan ditolak
    _applications.add(
      AdoptionApplicationModel(
        id: 205,
        catId: 104,
        catName: 'Kiko Perpus',
        applicantName: currentUserName,
        applicantEmail: currentUserEmail,
        applicantUserType: 'mahasiswa',
        housingType: 'kos',
        financialReadiness: false,
        familyPermission: false,
        longTermPlan: 'Kos tidak membolehkan hewan peliharaan.',
        homePhotoPath: 'mock://evidence/kos.jpg',
        commitmentVersion: 'v1.0',
        commitmentAccepted: true,
        commitmentAcceptedAt: now.subtract(const Duration(days: 10)),
        precheckPassed: false,
        status: ApplicationStatus.REJECTED,
        adminNotes:
            'Kriteria tempat tinggal belum memenuhi standar kesejahteraan hewan peliharaan (tidak ada izin pemilik kos).',
        createdAt: now.subtract(const Duration(days: 12)),
        submittedAt: now.subtract(const Duration(days: 11)),
        cat: _readyCats[3],
      ),
    );

    // 3. Adopsi Aktif (ADP-08) - Data seed contoh adopsi aktif
    // Adopter ID USR-MAHASISWA-002 (adopter rekan mahasiswa lain) agar Helmi (USR-001)
    // dapat menguji pengajuan kelayakan & pengambilan kucing sendiri tanpa terblokir ALREADY_ADOPTING di awal.
    final activeCat = CatModel(
      id: 105,
      name: 'Oyen Asrama Putra',
      qrCodeToken: 'MTP1.C.OYEN105',
      gender: 'male',
      breed: 'Domestik Ginger',
      primaryColor: 'Oranye Belang Putih',
      pattern: 'Striped Tabby',
      sterilizationStatus: true,
      healthStatus: 'healthy',
      adoptionStatus: 'adopted',
      description: 'Kucing manis dan ceria yang kini hidup bahagia di rumah adopter.',
      lastSeenLocationName: 'Rumah Adopter (Telah Diadopsi)',
    );

    final activeAdoption = ActiveAdoptionModel(
      id: 501,
      applicationId: 199,
      catId: 105,
      adopterName: 'Rian Pratama',
      adopterId: 'USR-MAHASISWA-002',
      status: ActiveAdoptionStatus.ACTIVE,
      adoptedAt: now.subtract(const Duration(days: 35)),
      nextFollowupDue: now.add(const Duration(days: 7)),
      completedFollowups: 2,
      totalFollowups: 6,
      cat: activeCat,
    );
    _activeAdoptions.add(activeAdoption);

    // Follow-up untuk adopsi 501
    _followups[501] = [
      AdoptionFollowupModel(
        id: 'FLW-01',
        adoptionId: 501,
        cycleNumber: 1,
        dueDate: now.subtract(const Duration(days: 21)),
        submittedAt: now.subtract(const Duration(days: 21)),
        status: FollowupStatus.REVIEWED,
        photoPath: 'mock://evidence/flw1.jpg',
        condition: 'Sangat Sehat & Adaptif',
        notes: 'Oyen makan lahap dan sudah terbiasa dengan kotak pasir.',
        issues: null,
        adminFeedback: 'Bagus! Pertahankan gizi dan jangan lupa sisir bulunya berkala.',
      ),
      AdoptionFollowupModel(
        id: 'FLW-02',
        adoptionId: 501,
        cycleNumber: 2,
        dueDate: now.subtract(const Duration(days: 7)),
        submittedAt: now.subtract(const Duration(days: 5)),
        status: FollowupStatus.REVIEWED,
        photoPath: 'mock://evidence/flw2.jpg',
        condition: 'Sehat & Ceria',
        notes: 'Sempat flu ringan 2 hari tapi sudah sembuh setelah diberi vitamin.',
        issues: 'Flu ringan sudah sembuh',
        adminFeedback: 'Terima kasih atas laporannya. Terus pantau suhu tubuhnya.',
      ),
      AdoptionFollowupModel(
        id: 'FLW-03',
        adoptionId: 501,
        cycleNumber: 3,
        dueDate: now.add(const Duration(days: 7)),
        submittedAt: null,
        status: FollowupStatus.PENDING,
        photoPath: null,
        condition: 'Belum Dilaporkan',
        notes: null,
      ),
    ];
  }

  void _checkNetwork() {
    if (simulateNetworkError) {
      throw Exception('Gagal menghubungi server. Periksa koneksi internet Anda.');
    }
  }

  @override
  Future<List<CatModel>> getReadyCats() async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_readyCats);
  }

  @override
  Future<CatModel?> getCatById(int catId) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _readyCats.firstWhere((c) => c.id == catId);
    } catch (_) {
      for (final a in _activeAdoptions) {
        if (a.catId == catId) return a.cat;
      }
      return null;
    }
  }

  @override
  Future<AdoptionExtraCat?> getCatExtra(int catId) async {
    return _catExtras[catId];
  }

  @override
  Future<List<AdoptionApplicationModel>> getMyApplications() async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_applications);
  }

  @override
  Future<AdoptionApplicationModel?> getApplicationById(int applicationId) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _applications.firstWhere((app) => app.id == applicationId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AdoptionApplicationModel> saveDraft({
    int? applicationId,
    int? catId,
    String? catName,
    required String applicantName,
    required String applicantEmail,
    required String applicantUserType,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    String? longTermPlan,
    String? homePhotoPath,
    bool commitmentAccepted = false,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 300));

    CatModel? matchedCat;
    if (catId != null) {
      try {
        matchedCat = _readyCats.firstWhere((c) => c.id == catId);
      } catch (_) {}
    }

    if (applicationId != null) {
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        final existing = _applications[index];
        final updated = existing.copyWith(
          catId: catId ?? existing.catId,
          catName: catName ?? existing.catName,
          applicantName: applicantName,
          applicantEmail: applicantEmail,
          applicantUserType: applicantUserType,
          housingType: housingType,
          financialReadiness: financialReadiness,
          familyPermission: familyPermission,
          longTermPlan: longTermPlan,
          homePhotoPath: homePhotoPath,
          commitmentAccepted: commitmentAccepted,
          status: ApplicationStatus.DRAFT,
          cat: matchedCat ?? existing.cat,
        );
        _applications[index] = updated;
        return updated;
      }
    }

    final newId = 200 + _applications.length + 1;
    final draft = AdoptionApplicationModel(
      id: newId,
      catId: catId,
      catName: catName,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      applicantUserType: applicantUserType,
      housingType: housingType,
      financialReadiness: financialReadiness,
      familyPermission: familyPermission,
      longTermPlan: longTermPlan,
      homePhotoPath: homePhotoPath,
      commitmentVersion: kCommitmentVersion,
      commitmentAccepted: commitmentAccepted,
      precheckPassed: false,
      status: ApplicationStatus.DRAFT,
      createdAt: DateTime.now(),
      cat: matchedCat,
    );
    _applications.insert(0, draft);
    return draft;
  }

  @override
  Future<AdoptionApplicationModel> submitApplication({
    int? applicationId,
    int? catId,
    String? catName,
    required String applicantName,
    required String applicantEmail,
    required String applicantUserType,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    required String longTermPlan,
    required String homePhotoPath,
    required bool commitmentAccepted,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 400));

    // PRD ADP-01: Validasi user_type - Dosen & staf melihat pesan NOT_STUDENT
    if (applicantUserType.toLowerCase() != 'mahasiswa') {
      throw Exception(
        'NOT_STUDENT: Hanya mahasiswa dengan email kampus aktif yang dapat mengajukan adopsi kucing.',
      );
    }

    // PRD ADP-03 & §4.6: Cek apakah pemohon ini sudah memiliki 1 adopsi aktif
    final hasActiveAdoption = _activeAdoptions.any(
      (a) =>
          (a.adopterName == applicantName || a.adopterId == currentUserId) &&
          a.status == ActiveAdoptionStatus.ACTIVE,
    );
    if (hasActiveAdoption) {
      throw Exception(
        'ALREADY_ADOPTING: Anda telah memiliki 1 adopsi aktif. Selesaikan proses adopsi saat ini terlebih dahulu.',
      );
    }

    // Validasi kelengkapan form wajib (ADP-02)
    if (longTermPlan.trim().isEmpty) {
      throw Exception('Rencana jangka panjang wajib diisi.');
    }
    if (homePhotoPath.trim().isEmpty) {
      throw Exception('Foto tempat tinggal dari kamera aplikasi wajib diunggah.');
    }
    if (!commitmentAccepted) {
      throw Exception('Anda wajib menyetujui lembar komitmen adopter.');
    }

    // PRD ADP-03: Precheck otomatis
    final precheckPassed =
        financialReadiness && familyPermission && homePhotoPath.isNotEmpty;

    CatModel? matchedCat;
    if (catId != null) {
      try {
        matchedCat = _readyCats.firstWhere((c) => c.id == catId);
      } catch (_) {}
    }

    final now = DateTime.now();

    if (applicationId != null) {
      final index = _applications.indexWhere((a) => a.id == applicationId);
      if (index != -1) {
        final updated = _applications[index].copyWith(
          catId: catId ?? _applications[index].catId,
          catName: catName ?? _applications[index].catName,
          applicantName: applicantName,
          applicantEmail: applicantEmail,
          applicantUserType: applicantUserType,
          housingType: housingType,
          financialReadiness: financialReadiness,
          familyPermission: familyPermission,
          longTermPlan: longTermPlan,
          homePhotoPath: homePhotoPath,
          commitmentAccepted: commitmentAccepted,
          commitmentAcceptedAt: now,
          precheckPassed: precheckPassed,
          status: ApplicationStatus.SUBMITTED,
          submittedAt: now,
          cat: matchedCat ?? _applications[index].cat,
        );
        _applications[index] = updated;
        return updated;
      }
    }

    final newId = 200 + _applications.length + 1;
    final submitted = AdoptionApplicationModel(
      id: newId,
      catId: catId,
      catName: catName ?? matchedCat?.name,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      applicantUserType: applicantUserType,
      housingType: housingType,
      financialReadiness: financialReadiness,
      familyPermission: familyPermission,
      longTermPlan: longTermPlan,
      homePhotoPath: homePhotoPath,
      commitmentVersion: kCommitmentVersion,
      commitmentAccepted: commitmentAccepted,
      commitmentAcceptedAt: now,
      precheckPassed: precheckPassed,
      status: ApplicationStatus.SUBMITTED,
      createdAt: now,
      submittedAt: now,
      cat: matchedCat,
    );
    _applications.insert(0, submitted);
    return submitted;
  }

  @override
  Future<AdoptionApplicationModel> resubmitApplication({
    required int applicationId,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    required String longTermPlan,
    required String homePhotoPath,
    required bool commitmentAccepted,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) {
      throw Exception('Pengajuan tidak ditemukan.');
    }

    final existing = _applications[index];
    if (existing.status != ApplicationStatus.REVISION_REQUESTED) {
      throw Exception(
        'Pengajuan ini tidak dalam status perbaikan (REVISION_REQUESTED).',
      );
    }

    final now = DateTime.now();
    final updated = existing.copyWith(
      housingType: housingType,
      financialReadiness: financialReadiness,
      familyPermission: familyPermission,
      longTermPlan: longTermPlan,
      homePhotoPath: homePhotoPath,
      commitmentAccepted: commitmentAccepted,
      status: ApplicationStatus.SUBMITTED,
      submittedAt: now,
      clearAdminNotes: true, // Reset catatan admin setelah revisi terkirim (PRD §5.2)
    );
    _applications[index] = updated;
    return updated;
  }

  @override
  Future<AdoptionPickupLockModel> getPickupLock(
    int applicationId,
    int catId,
  ) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 150));

    final key = '$applicationId-$catId';
    if (_pickupLocks.containsKey(key)) {
      return _pickupLocks[key]!;
    }

    final now = DateTime.now();
    final lock = AdoptionPickupLockModel(
      id: 'LCK-${now.millisecondsSinceEpoch}',
      applicationId: applicationId,
      catId: catId,
      adopterId: currentUserId,
      lockedAt: now,
      expiresAt: now.add(kPickupLockDuration), // 48 jam sesuai PRD ADP-07
      status: PickupLockStatus.HELD,
    );
    _pickupLocks[key] = lock;
    return lock;
  }

  @override
  Future<ActiveAdoptionModel> completePickup({
    required int applicationId,
    required int catId,
    required String scannedQrToken,
    required String collarPhotoPath,
    required bool confirmedResponsibility,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 500));

    // Validasi token QR kucing (ADP-06)
    CatModel? cat;
    try {
      cat = _readyCats.firstWhere((c) => c.id == catId);
    } catch (_) {
      throw Exception('Data kucing tidak ditemukan.');
    }

    if (scannedQrToken.trim() != cat.qrCodeToken.trim()) {
      throw Exception(
        'QR_WRONG_CAT: QR yang dipindai bukan milik ${cat.name}. Pindai kalung QR resmi kucing ini.',
      );
    }

    if (collarPhotoPath.trim().isEmpty) {
      throw Exception(
        'Foto kucing mengenakan kalung dari kamera wajib dilampirkan.',
      );
    }

    if (!confirmedResponsibility) {
      throw Exception('Anda wajib mencentang konfirmasi serah terima tanggung jawab.');
    }

    final now = DateTime.now();

    // Perbarui status lock
    final key = '$applicationId-$catId';
    if (_pickupLocks.containsKey(key)) {
      final existingLock = _pickupLocks[key]!;
      _pickupLocks[key] = AdoptionPickupLockModel(
        id: existingLock.id,
        applicationId: applicationId,
        catId: catId,
        adopterId: currentUserId,
        lockedAt: existingLock.lockedAt,
        expiresAt: existingLock.expiresAt,
        status: PickupLockStatus.USED,
        qrScanned: true,
        collarPhotoPath: collarPhotoPath,
        confirmedResponsibility: true,
      );
    }

    // Perbarui status aplikasi
    final appIndex = _applications.indexWhere((a) => a.id == applicationId);
    if (appIndex != -1) {
      _applications[appIndex] = _applications[appIndex].copyWith(
        status: ApplicationStatus.APPROVED,
      );
    }

    // Hapus kucing dari katalog READY
    _readyCats.removeWhere((c) => c.id == catId);

    // Buat adopsi aktif
    final newAdoptionId = 500 + _activeAdoptions.length + 1;
    final active = ActiveAdoptionModel(
      id: newAdoptionId,
      applicationId: applicationId,
      catId: catId,
      adopterName: currentUserName,
      adopterId: currentUserId,
      status: ActiveAdoptionStatus.ACTIVE,
      adoptedAt: now,
      nextFollowupDue: now.add(const Duration(days: kFollowupCycleDays)),
      completedFollowups: 0,
      totalFollowups: kTotalFollowupCycles,
      cat: cat,
    );
    _activeAdoptions.insert(0, active);

    // Buat 1 periode follow-up pertama
    _followups[newAdoptionId] = [
      AdoptionFollowupModel(
        id: 'FLW-$newAdoptionId-01',
        adoptionId: newAdoptionId,
        cycleNumber: 1,
        dueDate: now.add(const Duration(days: kFollowupCycleDays)),
        status: FollowupStatus.PENDING,
        condition: 'Belum Dilaporkan',
      ),
    ];

    return active;
  }

  @override
  Future<List<ActiveAdoptionModel>> getMyActiveAdoptions() async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 200));
    // PRD ADP-08: Halaman Kucing Saya hanya menampilkan adopsi ACTIVE
    return List.unmodifiable(_activeAdoptions);
  }

  @override
  Future<ActiveAdoptionModel?> getActiveAdoptionById(int adoptionId) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _activeAdoptions.firstWhere((a) => a.id == adoptionId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AdoptionFollowupModel>> getFollowups(int adoptionId) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_followups[adoptionId] ?? []);
  }

  @override
  Future<AdoptionFollowupModel> submitFollowup({
    required int adoptionId,
    required int cycleNumber,
    required String photoPath,
    required String condition,
    String? notes,
    String? issues,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 350));

    if (photoPath.trim().isEmpty) {
      throw Exception('Foto kucing dari kamera wajib diunggah untuk follow-up.');
    }

    final list = _followups[adoptionId] ?? [];
    final now = DateTime.now();

    // Cari item siklus yang sesuai
    final index = list.indexWhere((f) => f.cycleNumber == cycleNumber);
    final isLate = index != -1 && now.isAfter(list[index].dueDate);
    final status = isLate ? FollowupStatus.LATE : FollowupStatus.SUBMITTED;

    final updatedItem = AdoptionFollowupModel(
      id: index != -1 ? list[index].id : 'FLW-$adoptionId-$cycleNumber',
      adoptionId: adoptionId,
      cycleNumber: cycleNumber,
      dueDate: index != -1 ? list[index].dueDate : now,
      submittedAt: now,
      status: status,
      photoPath: photoPath,
      condition: condition,
      notes: notes,
      issues: issues,
      adminFeedback: null,
    );

    if (index != -1) {
      list[index] = updatedItem;
    } else {
      list.add(updatedItem);
    }
    _followups[adoptionId] = list;

    // Perbarui jumlah completed pada adopsi aktif
    final adIndex = _activeAdoptions.indexWhere((a) => a.id == adoptionId);
    if (adIndex != -1) {
      final existing = _activeAdoptions[adIndex];
      _activeAdoptions[adIndex] = existing.copyWith(
        completedFollowups: existing.completedFollowups + 1,
        nextFollowupDue: now.add(const Duration(days: kFollowupCycleDays)),
      );
    }

    return updatedItem;
  }

  @override
  Future<ActiveAdoptionModel> requestReturn({
    required int adoptionId,
    required ReturnReasonType reasonType,
    required String reason,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 300));

    // PRD OQ-08 & Keputusan Q4: Pengembalian fisik nonaktif
    if (!kAdoptionReturnEnabled) {
      throw Exception(
        'RETURN_DISABLED: Pengembalian fisik ke kampus saat ini belum tersedia sesuai kebijakan pengelola.',
      );
    }

    final index = _activeAdoptions.indexWhere((a) => a.id == adoptionId);
    if (index == -1) {
      throw Exception('Adopsi aktif tidak ditemukan.');
    }

    if (reason.trim().isEmpty) {
      throw Exception('Alasan pengembalian wajib diisi.');
    }

    final now = DateTime.now();
    final updated = _activeAdoptions[index].copyWith(
      status: ActiveAdoptionStatus.RETURN_REQUESTED,
      returnReason: reason,
      returnReasonType: reasonType,
      returnRequestedAt: now,
    );
    _activeAdoptions[index] = updated;
    return updated;
  }

  @override
  Future<ActiveAdoptionModel> submitReturnEvidence({
    required int adoptionId,
    required String returnEvidencePath,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 350));

    final index = _activeAdoptions.indexWhere((a) => a.id == adoptionId);
    if (index == -1) throw Exception('Adopsi tidak ditemukan.');

    if (returnEvidencePath.trim().isEmpty) {
      throw Exception('Foto bukti fisik pengembalian wajib dilampirkan.');
    }

    final now = DateTime.now();
    // PRD ADP-12: Status RETURN_EVIDENCE_PENDING ("Menunggu Verifikasi Admin", bukan langsung selesai)
    final updated = _activeAdoptions[index].copyWith(
      status: ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING,
      returnEvidencePath: returnEvidencePath,
      returnEvidenceSubmittedAt: now,
    );
    _activeAdoptions[index] = updated;
    return updated;
  }

  @override
  Future<AdoptionIssueReportModel> reportIssue({
    required int adoptionId,
    required int catId,
    required AdoptionIssueCategory category,
    required String description,
    String? photoPath,
  }) async {
    _checkNetwork();
    await Future.delayed(const Duration(milliseconds: 300));

    if (description.trim().isEmpty) {
      throw Exception('Deskripsi kendala wajib diisi.');
    }

    final now = DateTime.now();
    final report = AdoptionIssueReportModel(
      id: 'ISSUE-${now.millisecondsSinceEpoch}',
      adoptionId: adoptionId,
      catId: catId,
      category: category,
      description: description,
      photoPath: photoPath, // Opsional sesuai ADP-13
      reportedAt: now,
    );
    _issueReports.insert(0, report);
    return report;
  }
}
