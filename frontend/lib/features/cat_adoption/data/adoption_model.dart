import '../../cat/data/cat_model.dart';

class AdoptionApplicationModel {
  final int id;
  final int catId;
  final String status;
  final String housingType;
  final bool financialReadiness;
  final bool familyPermission;
  final String? adminNotes;
  final CatModel? cat;

  AdoptionApplicationModel({
    required this.id,
    required this.catId,
    required this.status,
    required this.housingType,
    required this.financialReadiness,
    required this.familyPermission,
    this.adminNotes,
    this.cat,
  });

  factory AdoptionApplicationModel.fromJson(Map<String, dynamic> json) {
    return AdoptionApplicationModel(
      id: json['id'] ?? 0,
      catId: json['cat_id'] ?? 0,
      status: json['status'] ?? 'submitted',
      housingType: json['housing_type'] ?? '',
      financialReadiness: json['financial_readiness'] ?? false,
      familyPermission: json['family_permission'] ?? false,
      adminNotes: json['admin_notes'],
      cat: json['cat'] != null ? CatModel.fromJson(json['cat']) : null,
    );
  }
}
