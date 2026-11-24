import '../../cat/data/cat_model.dart';
import 'adoption_enums.dart';

/// Data pelengkap kucing khusus adopsi tanpa memodifikasi [CatModel] milik Rekans Caps
class AdoptionExtraCat {
  final int catId;
  final String readyReason;
  final String personalityNote;
  final String locationArea;
  final List<String> tags;

  const AdoptionExtraCat({
    required this.catId,
    required this.readyReason,
    required this.personalityNote,
    required this.locationArea,
    this.tags = const [],
  });
}

/// Model Formulir & Kelayakan Adopter (PRD §7.4, ADP-01..04)
class AdoptionApplicationModel {
  final int id;
  final int? catId;
  final String? catName;
  final String applicantName;
  final String applicantEmail;
  final String applicantUserType; // 'mahasiswa', 'dosen', 'staf'
  final String housingType; // 'kos', 'rumah_kontrakan', 'rumah_pribadi'
  final bool financialReadiness;
  final bool familyPermission;
  final String? longTermPlan;
  final String? homePhotoPath;
  final String commitmentVersion;
  final bool commitmentAccepted;
  final DateTime? commitmentAcceptedAt;
  final bool precheckPassed; // Terpisah dari keputusan admin
  final ApplicationStatus status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final CatModel? cat;

  AdoptionApplicationModel({
    required this.id,
    this.catId,
    this.catName,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantUserType,
    required this.housingType,
    required this.financialReadiness,
    required this.familyPermission,
    this.longTermPlan,
    this.homePhotoPath,
    this.commitmentVersion = 'v1.0',
    this.commitmentAccepted = false,
    this.commitmentAcceptedAt,
    this.precheckPassed = false,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.submittedAt,
    this.cat,
  });

  bool get isDraft => status == ApplicationStatus.DRAFT;
  bool get isSubmitted => status == ApplicationStatus.SUBMITTED;
  bool get isRevisionRequested => status == ApplicationStatus.REVISION_REQUESTED;
  bool get isApproved => status == ApplicationStatus.APPROVED;
  bool get isRejected => status == ApplicationStatus.REJECTED;

  AdoptionApplicationModel copyWith({
    int? id,
    int? catId,
    String? catName,
    String? applicantName,
    String? applicantEmail,
    String? applicantUserType,
    String? housingType,
    bool? financialReadiness,
    bool? familyPermission,
    String? longTermPlan,
    String? homePhotoPath,
    String? commitmentVersion,
    bool? commitmentAccepted,
    DateTime? commitmentAcceptedAt,
    bool? precheckPassed,
    ApplicationStatus? status,
    String? adminNotes,
    bool clearAdminNotes = false,
    DateTime? createdAt,
    DateTime? submittedAt,
    CatModel? cat,
  }) {
    return AdoptionApplicationModel(
      id: id ?? this.id,
      catId: catId ?? this.catId,
      catName: catName ?? this.catName,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantUserType: applicantUserType ?? this.applicantUserType,
      housingType: housingType ?? this.housingType,
      financialReadiness: financialReadiness ?? this.financialReadiness,
      familyPermission: familyPermission ?? this.familyPermission,
      longTermPlan: longTermPlan ?? this.longTermPlan,
      homePhotoPath: homePhotoPath ?? this.homePhotoPath,
      commitmentVersion: commitmentVersion ?? this.commitmentVersion,
      commitmentAccepted: commitmentAccepted ?? this.commitmentAccepted,
      commitmentAcceptedAt: commitmentAcceptedAt ?? this.commitmentAcceptedAt,
      precheckPassed: precheckPassed ?? this.precheckPassed,
      status: status ?? this.status,
      adminNotes: clearAdminNotes ? null : (adminNotes ?? this.adminNotes),
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      cat: cat ?? this.cat,
    );
  }

  factory AdoptionApplicationModel.fromJson(Map<String, dynamic> json) {
    return AdoptionApplicationModel(
      id: json['id'] ?? 0,
      catId: json['cat_id'],
      catName: json['cat_name'],
      applicantName: json['applicant_name'] ?? 'Mahasiswa Meowtopia',
      applicantEmail: json['applicant_email'] ?? 'adopter@student.ac.id',
      applicantUserType: json['applicant_user_type'] ?? 'mahasiswa',
      housingType: json['housing_type'] ?? 'kos',
      financialReadiness: json['financial_readiness'] ?? false,
      familyPermission: json['family_permission'] ?? false,
      longTermPlan: json['long_term_plan'],
      homePhotoPath: json['home_photo_path'],
      commitmentVersion: json['commitment_version'] ?? 'v1.0',
      commitmentAccepted: json['commitment_accepted'] ?? false,
      commitmentAcceptedAt: json['commitment_accepted_at'] != null
          ? DateTime.tryParse(json['commitment_accepted_at'])
          : null,
      precheckPassed: json['precheck_passed'] ?? false,
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApplicationStatus.SUBMITTED,
      ),
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      cat: json['cat'] != null ? CatModel.fromJson(json['cat']) : null,
    );
  }
}

/// Model Kucing Teradopsi Aktif (PRD §4.2, §7.4, ADP-08)
class ActiveAdoptionModel {
  final int id;
  final int applicationId;
  final int catId;
  final String adopterName;
  final String adopterId;
  final ActiveAdoptionStatus status;
  final DateTime adoptedAt;
  final DateTime nextFollowupDue;
  final int completedFollowups;
  final int totalFollowups;
  final String? returnReason;
  final ReturnReasonType? returnReasonType;
  final String? returnEvidencePath;
  final DateTime? returnRequestedAt;
  final DateTime? returnApprovedAt;
  final DateTime? returnEvidenceSubmittedAt;
  final CatModel? cat;

  ActiveAdoptionModel({
    required this.id,
    required this.applicationId,
    required this.catId,
    required this.adopterName,
    required this.adopterId,
    required this.status,
    required this.adoptedAt,
    required this.nextFollowupDue,
    this.completedFollowups = 0,
    this.totalFollowups = 6,
    this.returnReason,
    this.returnReasonType,
    this.returnEvidencePath,
    this.returnRequestedAt,
    this.returnApprovedAt,
    this.returnEvidenceSubmittedAt,
    this.cat,
  });

  bool get isActive => status == ActiveAdoptionStatus.ACTIVE;
  bool get isReturnRequested => status == ActiveAdoptionStatus.RETURN_REQUESTED;
  bool get isReturnApproved => status == ActiveAdoptionStatus.RETURN_APPROVED;
  bool get isReturnEvidencePending =>
      status == ActiveAdoptionStatus.RETURN_EVIDENCE_PENDING;
  bool get isClosedReturned => status == ActiveAdoptionStatus.CLOSED_RETURNED;

  ActiveAdoptionModel copyWith({
    int? id,
    int? applicationId,
    int? catId,
    String? adopterName,
    String? adopterId,
    ActiveAdoptionStatus? status,
    DateTime? adoptedAt,
    DateTime? nextFollowupDue,
    int? completedFollowups,
    int? totalFollowups,
    String? returnReason,
    ReturnReasonType? returnReasonType,
    String? returnEvidencePath,
    DateTime? returnRequestedAt,
    DateTime? returnApprovedAt,
    DateTime? returnEvidenceSubmittedAt,
    CatModel? cat,
  }) {
    return ActiveAdoptionModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      catId: catId ?? this.catId,
      adopterName: adopterName ?? this.adopterName,
      adopterId: adopterId ?? this.adopterId,
      status: status ?? this.status,
      adoptedAt: adoptedAt ?? this.adoptedAt,
      nextFollowupDue: nextFollowupDue ?? this.nextFollowupDue,
      completedFollowups: completedFollowups ?? this.completedFollowups,
      totalFollowups: totalFollowups ?? this.totalFollowups,
      returnReason: returnReason ?? this.returnReason,
      returnReasonType: returnReasonType ?? this.returnReasonType,
      returnEvidencePath: returnEvidencePath ?? this.returnEvidencePath,
      returnRequestedAt: returnRequestedAt ?? this.returnRequestedAt,
      returnApprovedAt: returnApprovedAt ?? this.returnApprovedAt,
      returnEvidenceSubmittedAt:
          returnEvidenceSubmittedAt ?? this.returnEvidenceSubmittedAt,
      cat: cat ?? this.cat,
    );
  }
}

/// Model Penguncian Pickup Kucing 48 Jam (ADP-06..07)
class AdoptionPickupLockModel {
  final String id;
  final int applicationId;
  final int catId;
  final String adopterId;
  final DateTime lockedAt;
  final DateTime expiresAt;
  final PickupLockStatus status;
  final bool qrScanned;
  final String? collarPhotoPath;
  final bool confirmedResponsibility;

  AdoptionPickupLockModel({
    required this.id,
    required this.applicationId,
    required this.catId,
    required this.adopterId,
    required this.lockedAt,
    required this.expiresAt,
    required this.status,
    this.qrScanned = false,
    this.collarPhotoPath,
    this.confirmedResponsibility = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
}

/// Model Follow-up 2-Mingguan (ADP-09..10)
class AdoptionFollowupModel {
  final String id;
  final int adoptionId;
  final int cycleNumber;
  final DateTime dueDate;
  final DateTime? submittedAt;
  final FollowupStatus status;
  final String? photoPath;
  final String condition;
  final String? notes;
  final String? issues;
  final String? adminFeedback;

  AdoptionFollowupModel({
    required this.id,
    required this.adoptionId,
    required this.cycleNumber,
    required this.dueDate,
    this.submittedAt,
    required this.status,
    this.photoPath,
    required this.condition,
    this.notes,
    this.issues,
    this.adminFeedback,
  });

  bool get isLate =>
      status == FollowupStatus.LATE ||
      (status == FollowupStatus.PENDING && DateTime.now().isAfter(dueDate));
}

/// Model Laporan Kendala Adopsi (ADP-13)
class AdoptionIssueReportModel {
  final String id;
  final int adoptionId;
  final int catId;
  final AdoptionIssueCategory category;
  final String description;
  final String? photoPath; // Foto TIDAK wajib sesuai PRD ADP-13
  final DateTime reportedAt;
  final bool handled;
  final String? adminResponse;

  AdoptionIssueReportModel({
    required this.id,
    required this.adoptionId,
    required this.catId,
    required this.category,
    required this.description,
    this.photoPath,
    required this.reportedAt,
    this.handled = false,
    this.adminResponse,
  });
}
