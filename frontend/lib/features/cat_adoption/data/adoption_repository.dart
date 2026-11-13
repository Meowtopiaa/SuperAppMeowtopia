import '../../cat/data/cat_model.dart';
import 'adoption_enums.dart';
import 'adoption_model.dart';

/// Kontrak Repository Modul Adopsi (PRD §8.5, ADP-01..15)
abstract class AdoptionRepository {
  /// Mendapatkan daftar kucing siap adopsi (status READY) (ADP-05)
  Future<List<CatModel>> getReadyCats();

  /// Mendapatkan detail kucing spesifik
  Future<CatModel?> getCatById(int catId);

  /// Mendapatkan data pelengkap ekstra kucing khusus adopsi
  Future<AdoptionExtraCat?> getCatExtra(int catId);

  /// Mendapatkan daftar semua pengajuan kelayakan milik user saat ini (ADP-03/04)
  Future<List<AdoptionApplicationModel>> getMyApplications();

  /// Mendapatkan detail satu pengajuan kelayakan
  Future<AdoptionApplicationModel?> getApplicationById(int applicationId);

  /// Menyimpan formulir sebagai DRAFT (bisa tanpa memilih kucing) (ADP-02)
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
  });

  /// Mengirimkan formulir kelayakan untuk diperiksa admin (SUBMITTED) (ADP-02..03)
  /// Melempar exception jika:
  /// - `NOT_STUDENT`: applicantUserType bukan mahasiswa (ADP-01)
  /// - `ALREADY_ADOPTING`: user sudah memiliki 1 adopsi aktif (ADP-03, §4.6)
  /// - `VALIDATION_ERROR`: jawaban wajib belum lengkap / foto / komitmen
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
  });

  /// Mengirim ulang pengajuan setelah diminta revisi oleh admin (REVISION_REQUESTED -> SUBMITTED) (ADP-04)
  Future<AdoptionApplicationModel> resubmitApplication({
    required int applicationId,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    required String longTermPlan,
    required String homePhotoPath,
    required bool commitmentAccepted,
  });

  /// Mengambil data penguncian pengambilan kucing (48 jam) (ADP-06..07)
  Future<AdoptionPickupLockModel> getPickupLock(int applicationId, int catId);

  /// Menyelesaikan proses pengambilan kucing (ADP-06..07)
  /// Verifikasi scan QR kalung + foto kucing berkalung + konfirmasi tanggung jawab
  /// Menghasilkan [ActiveAdoptionModel] dengan status ACTIVE
  Future<ActiveAdoptionModel> completePickup({
    required int applicationId,
    required int catId,
    required String scannedQrToken,
    required String collarPhotoPath,
    required bool confirmedResponsibility,
  });

  /// Mendapatkan daftar kucing adopsi aktif milik user (HANYA status ACTIVE) (ADP-08)
  Future<List<ActiveAdoptionModel>> getMyActiveAdoptions();

  /// Mendapatkan detail satu adopsi aktif
  Future<ActiveAdoptionModel?> getActiveAdoptionById(int adoptionId);

  /// Mendapatkan riwayat & jadwal follow-up berkala (ADP-09)
  Future<List<AdoptionFollowupModel>> getFollowups(int adoptionId);

  /// Mengirim laporan follow-up 2-mingguan (ADP-09..10)
  /// Terlambat tetap diterima dengan status LATE
  Future<AdoptionFollowupModel> submitFollowup({
    required int adoptionId,
    required int cycleNumber,
    required String photoPath,
    required String condition,
    String? notes,
    String? issues,
  });

  /// Mengajukan pengembalian kucing (ADP-11)
  /// Jika return_enabled = false, akan melempar exception 'RETURN_NOT_ENABLED'
  Future<ActiveAdoptionModel> requestReturn({
    required int adoptionId,
    required ReturnReasonType reasonType,
    required String reason,
  });

  /// Mengunggah bukti fisik pengembalian setelah disetujui admin (ADP-12)
  /// Status berubah menjadi RETURN_EVIDENCE_PENDING ("Menunggu Verifikasi Admin", bukan langsung selesai)
  Future<ActiveAdoptionModel> submitReturnEvidence({
    required int adoptionId,
    required String returnEvidencePath,
  });

  /// Melaporkan kendala darurat / medis kucing (ADP-13)
  /// Foto TIDAK wajib; tidak menutup adopsi otomatis
  Future<AdoptionIssueReportModel> reportIssue({
    required int adoptionId,
    required int catId,
    required AdoptionIssueCategory category,
    required String description,
    String? photoPath,
  });
}

