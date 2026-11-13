import 'package:flutter/material.dart';
import '../../cat/data/cat_model.dart';
import '../data/adoption_constants.dart';
import '../data/adoption_enums.dart';
import '../data/adoption_model.dart';
import '../data/adoption_repository.dart';
import '../data/adoption_service.dart';
import '../data/mock_adoption_repository.dart';

/// State Management Modul Adopsi Kucing (E-Nigma)
/// Mengikuti pola ChangeNotifier yang digunakan pada feeding_spot & modul lainnya.
class AdoptionProvider extends ChangeNotifier {
  final AdoptionService _service;

  // Data states
  List<CatModel> _readyCats = [];
  List<AdoptionApplicationModel> _myApplications = [];
  List<ActiveAdoptionModel> _myActiveAdoptions = [];
  List<AdoptionFollowupModel> _currentFollowups = [];
  AdoptionPickupLockModel? _currentPickupLock;

  // Loading & error states
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _actionSuccessMessage;

  // User type simulasi (default: 'mahasiswa')
  String _userType = 'mahasiswa';
  String _userName = 'M. Helmi Afriza';
  String _userEmail = 'helmi.afriza@student.telkomuniversity.ac.id';

  AdoptionProvider({
    AdoptionService? service,
    AdoptionRepository? repository,
  }) : _service = service ??
            AdoptionService(
              repository: repository ?? MockAdoptionRepository(),
            ) {
    // Muat data awal secara otomatis
    fetchInitialData();
  }

  // Getters
  List<CatModel> get readyCats => List.unmodifiable(_readyCats);
  List<AdoptionApplicationModel> get myApplications =>
      List.unmodifiable(_myApplications);
  List<ActiveAdoptionModel> get myActiveAdoptions =>
      List.unmodifiable(_myActiveAdoptions);
  List<AdoptionFollowupModel> get currentFollowups =>
      List.unmodifiable(_currentFollowups);
  AdoptionPickupLockModel? get currentPickupLock => _currentPickupLock;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  String get userType => _userType;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isStudent => _userType.toLowerCase() == 'mahasiswa';
  bool get isReturnEnabled => kAdoptionReturnEnabled;

  /// Ubah tipe user untuk demonstrasi/testing (mis. menguji pesan NOT_STUDENT pada dosen/staf)
  void setUserType(String type, {String? name, String? email}) {
    _userType = type;
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (_service.repository is MockAdoptionRepository) {
      final mock = _service.repository as MockAdoptionRepository;
      mock.currentUserType = type;
      if (name != null) mock.currentUserName = name;
      if (email != null) mock.currentUserEmail = email;
    }
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();
  }

  /// Memuat seluruh data awal
  Future<void> fetchInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _readyCats = await _service.getReadyCats();
      _myApplications = await _service.getMyApplications();
      _myActiveAdoptions = await _service.getMyActiveAdoptions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Memuat daftar kucing siap adopsi (ADP-05)
  Future<void> fetchReadyCats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _readyCats = await _service.getReadyCats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Memuat daftar pengajuan kelayakan milik user (ADP-03..04)
  Future<void> fetchMyApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myApplications = await _service.getMyApplications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Memuat daftar adopsi aktif (HANYA status ACTIVE) (ADP-08)
  Future<void> fetchMyActiveAdoptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myActiveAdoptions = await _service.getMyActiveAdoptions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Simpan formulir sebagai DRAFT (ADP-02: bisa tanpa memilih kucing)
  Future<AdoptionApplicationModel?> saveDraft({
    int? applicationId,
    int? catId,
    String? catName,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    String? longTermPlan,
    String? homePhotoPath,
    bool commitmentAccepted = false,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final draft = await _service.saveDraft(
        applicationId: applicationId,
        catId: catId,
        catName: catName,
        applicantName: _userName,
        applicantEmail: _userEmail,
        applicantUserType: _userType,
        housingType: housingType,
        financialReadiness: financialReadiness,
        familyPermission: familyPermission,
        longTermPlan: longTermPlan,
        homePhotoPath: homePhotoPath,
        commitmentAccepted: commitmentAccepted,
      );

      _myApplications = await _service.getMyApplications();
      _isActionLoading = false;
      _actionSuccessMessage = 'Draf formulir berhasil disimpan.';
      notifyListeners();
      return draft;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Mengirimkan formulir kelayakan adopsi untuk review admin (ADP-02..03)
  Future<AdoptionApplicationModel?> submitApplication({
    int? applicationId,
    int? catId,
    String? catName,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    required String longTermPlan,
    required String homePhotoPath,
    required bool commitmentAccepted,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final submitted = await _service.submitApplication(
        applicationId: applicationId,
        catId: catId,
        catName: catName,
        applicantName: _userName,
        applicantEmail: _userEmail,
        applicantUserType: _userType,
        housingType: housingType,
        financialReadiness: financialReadiness,
        familyPermission: familyPermission,
        longTermPlan: longTermPlan,
        homePhotoPath: homePhotoPath,
        commitmentAccepted: commitmentAccepted,
      );

      _myApplications = await _service.getMyApplications();
      _isActionLoading = false;
      _actionSuccessMessage =
          'Formulir berhasil dikirim! Menunggu pemeriksaan awal dan persetujuan admin.';
      notifyListeners();
      return submitted;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Mengirim ulang pengajuan yang diminta revisi oleh admin (ADP-04)
  Future<AdoptionApplicationModel?> resubmitApplication({
    required int applicationId,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    required String longTermPlan,
    required String homePhotoPath,
    required bool commitmentAccepted,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final updated = await _service.resubmitApplication(
        applicationId: applicationId,
        housingType: housingType,
        financialReadiness: financialReadiness,
        familyPermission: familyPermission,
        longTermPlan: longTermPlan,
        homePhotoPath: homePhotoPath,
        commitmentAccepted: commitmentAccepted,
      );

      _myApplications = await _service.getMyApplications();
      _isActionLoading = false;
      _actionSuccessMessage = 'Perbaikan formulir berhasil dikirim ulang ke admin.';
      notifyListeners();
      return updated;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Memuat data penahanan kucing untuk pengambilan (48 jam) (ADP-06..07)
  Future<void> fetchPickupLock(int applicationId, int catId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPickupLock = await _service.getPickupLock(applicationId, catId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Menyelesaikan proses pengambilan kucing (ADP-06..07)
  Future<ActiveAdoptionModel?> completePickup({
    required int applicationId,
    required int catId,
    required String scannedQrToken,
    required String collarPhotoPath,
    required bool confirmedResponsibility,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final active = await _service.completePickup(
        applicationId: applicationId,
        catId: catId,
        scannedQrToken: scannedQrToken,
        collarPhotoPath: collarPhotoPath,
        confirmedResponsibility: confirmedResponsibility,
      );

      _readyCats = await _service.getReadyCats();
      _myApplications = await _service.getMyApplications();
      _myActiveAdoptions = await _service.getMyActiveAdoptions();
      _isActionLoading = false;
      _actionSuccessMessage =
          'Pengambilan berhasil diverifikasi! Kucing kini berstatus Adopsi Aktif.';
      notifyListeners();
      return active;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Memuat riwayat dan jadwal follow-up (ADP-09)
  Future<void> fetchFollowups(int adoptionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentFollowups = await _service.getFollowups(adoptionId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Mengirim laporan follow-up 2-mingguan (ADP-09..10)
  Future<AdoptionFollowupModel?> submitFollowup({
    required int adoptionId,
    required int cycleNumber,
    required String photoPath,
    required String condition,
    String? notes,
    String? issues,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final followup = await _service.submitFollowup(
        adoptionId: adoptionId,
        cycleNumber: cycleNumber,
        photoPath: photoPath,
        condition: condition,
        notes: notes,
        issues: issues,
      );

      _currentFollowups = await _service.getFollowups(adoptionId);
      _myActiveAdoptions = await _service.getMyActiveAdoptions();
      _isActionLoading = false;
      _actionSuccessMessage =
          'Laporan kondisi follow-up berhasil dikirim ke pengelola.';
      notifyListeners();
      return followup;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Mengajukan pengembalian kucing (ADP-11)
  Future<ActiveAdoptionModel?> requestReturn({
    required int adoptionId,
    required ReturnReasonType reasonType,
    required String reason,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final updated = await _service.requestReturn(
        adoptionId: adoptionId,
        reasonType: reasonType,
        reason: reason,
      );

      _myActiveAdoptions = await _service.getMyActiveAdoptions();
      _isActionLoading = false;
      _actionSuccessMessage =
          'Pengajuan pengembalian berhasil dikirim. Menunggu arahan admin.';
      notifyListeners();
      return updated;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Mengunggah bukti fisik pengembalian setelah disetujui admin (ADP-12)
  Future<ActiveAdoptionModel?> submitReturnEvidence({
    required int adoptionId,
    required String returnEvidencePath,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final updated = await _service.submitReturnEvidence(
        adoptionId: adoptionId,
        returnEvidencePath: returnEvidencePath,
      );

      _myActiveAdoptions = await _service.getMyActiveAdoptions();
      _isActionLoading = false;
      _actionSuccessMessage =
          'Bukti fisik pengembalian berhasil diunggah. Menunggu verifikasi admin penutup.';
      notifyListeners();
      return updated;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Melaporkan kendala darurat / medis kucing (ADP-13)
  Future<AdoptionIssueReportModel?> reportIssue({
    required int adoptionId,
    required int catId,
    required AdoptionIssueCategory category,
    required String description,
    String? photoPath,
  }) async {
    _isActionLoading = true;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final report = await _service.reportIssue(
        adoptionId: adoptionId,
        catId: catId,
        category: category,
        description: description,
        photoPath: photoPath,
      );

      _isActionLoading = false;
      _actionSuccessMessage =
          'Laporan kendala berhasil tercatat. Tim caretaker kampus akan segera menindaklanjuti.';
      notifyListeners();
      return report;
    } catch (e) {
      _isActionLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
