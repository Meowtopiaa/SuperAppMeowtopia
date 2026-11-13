import '../../../core/constants/app_constants.dart';
import '../../cat/data/cat_model.dart';
import 'adoption_enums.dart';
import 'adoption_model.dart';
import 'adoption_repository.dart';
import 'mock_adoption_repository.dart';

/// Layanan integrasi data Adopsi Kucing Meowtopia
/// Mengadopsi pola repository dengan fallback Mock data tiruan pada mode demo.
class AdoptionService {
  final AdoptionRepository _repository;
  final bool isDemo;

  AdoptionService({
    AdoptionRepository? repository,
    this.isDemo = AppConstants.demoMode,
  }) : _repository = repository ?? MockAdoptionRepository();

  AdoptionRepository get repository => _repository;

  Future<List<CatModel>> getReadyCats() => _repository.getReadyCats();

  Future<CatModel?> getCatById(int catId) => _repository.getCatById(catId);

  Future<AdoptionExtraCat?> getCatExtra(int catId) =>
      _repository.getCatExtra(catId);

  Future<List<AdoptionApplicationModel>> getMyApplications() =>
      _repository.getMyApplications();

  Future<AdoptionApplicationModel?> getApplicationById(int id) =>
      _repository.getApplicationById(id);

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
  }) {
    return _repository.saveDraft(
      applicationId: applicationId,
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
      commitmentAccepted: commitmentAccepted,
    );
  }

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
  }) {
    return _repository.submitApplication(
      applicationId: applicationId,
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
      commitmentAccepted: commitmentAccepted,
    );
  }

  Future<AdoptionApplicationModel> resubmitApplication({
    required int applicationId,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    required String longTermPlan,
    required String homePhotoPath,
    required bool commitmentAccepted,
  }) {
    return _repository.resubmitApplication(
      applicationId: applicationId,
      housingType: housingType,
      financialReadiness: financialReadiness,
      familyPermission: familyPermission,
      longTermPlan: longTermPlan,
      homePhotoPath: homePhotoPath,
      commitmentAccepted: commitmentAccepted,
    );
  }

  Future<AdoptionPickupLockModel> getPickupLock(int applicationId, int catId) =>
      _repository.getPickupLock(applicationId, catId);

  Future<ActiveAdoptionModel> completePickup({
    required int applicationId,
    required int catId,
    required String scannedQrToken,
    required String collarPhotoPath,
    required bool confirmedResponsibility,
  }) {
    return _repository.completePickup(
      applicationId: applicationId,
      catId: catId,
      scannedQrToken: scannedQrToken,
      collarPhotoPath: collarPhotoPath,
      confirmedResponsibility: confirmedResponsibility,
    );
  }

  Future<List<ActiveAdoptionModel>> getMyActiveAdoptions() =>
      _repository.getMyActiveAdoptions();

  Future<ActiveAdoptionModel?> getActiveAdoptionById(int id) =>
      _repository.getActiveAdoptionById(id);

  Future<List<AdoptionFollowupModel>> getFollowups(int adoptionId) =>
      _repository.getFollowups(adoptionId);

  Future<AdoptionFollowupModel> submitFollowup({
    required int adoptionId,
    required int cycleNumber,
    required String photoPath,
    required String condition,
    String? notes,
    String? issues,
  }) {
    return _repository.submitFollowup(
      adoptionId: adoptionId,
      cycleNumber: cycleNumber,
      photoPath: photoPath,
      condition: condition,
      notes: notes,
      issues: issues,
    );
  }

  Future<ActiveAdoptionModel> requestReturn({
    required int adoptionId,
    required ReturnReasonType reasonType,
    required String reason,
  }) {
    return _repository.requestReturn(
      adoptionId: adoptionId,
      reasonType: reasonType,
      reason: reason,
    );
  }

  Future<ActiveAdoptionModel> submitReturnEvidence({
    required int adoptionId,
    required String returnEvidencePath,
  }) {
    return _repository.submitReturnEvidence(
      adoptionId: adoptionId,
      returnEvidencePath: returnEvidencePath,
    );
  }

  Future<AdoptionIssueReportModel> reportIssue({
    required int adoptionId,
    required int catId,
    required AdoptionIssueCategory category,
    required String description,
    String? photoPath,
  }) {
    return _repository.reportIssue(
      adoptionId: adoptionId,
      catId: catId,
      category: category,
      description: description,
      photoPath: photoPath,
    );
  }
}
