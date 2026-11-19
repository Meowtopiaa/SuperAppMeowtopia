/// Kucing di katalog adopsi (EN-12). Hanya field publik dari GET /adoption/cats.
///
/// Sengaja terpisah dari CatModel milik modul cat: katalog memakai ULID string
/// dan tidak pernah membawa koordinat, unique_code, atau token QR (CAT-09).
class AdoptionCatalogCat {
  final String id;
  final String name;
  final String gender; // MALE, FEMALE, UNKNOWN
  final String ageGroup; // KITTEN, ADULT, SENIOR, UNKNOWN
  final String? colorPattern;
  final bool? isSterilized;
  final String? description;
  final String? primaryPhotoMediaId;

  /// URL foto untuk data tiruan. Data API hanya membawa media_id.
  final String? photoUrl;

  const AdoptionCatalogCat({
    required this.id,
    required this.name,
    this.gender = 'UNKNOWN',
    this.ageGroup = 'UNKNOWN',
    this.colorPattern,
    this.isSterilized,
    this.description,
    this.primaryPhotoMediaId,
    this.photoUrl,
  });

  /// Membaca satu item katalog. Field lain yang mungkin ikut terkirim diabaikan.
  factory AdoptionCatalogCat.fromJson(Map<String, dynamic> json) {
    return AdoptionCatalogCat(
      id: json['id'].toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Tanpa nama',
      gender: _upperOr(json['gender'], 'UNKNOWN'),
      ageGroup: _upperOr(json['age_group'], 'UNKNOWN'),
      colorPattern: _nonEmpty(json['color_pattern']),
      isSterilized:
          json['is_sterilized'] is bool ? json['is_sterilized'] as bool : null,
      description: _nonEmpty(json['description']),
      primaryPhotoMediaId: _nonEmpty(json['primary_photo_media_id']),
    );
  }

  String get genderLabel => switch (gender) {
        'MALE' => 'Jantan',
        'FEMALE' => 'Betina',
        _ => 'Jenis kelamin belum diketahui',
      };

  String? get ageLabel => switch (ageGroup) {
        'KITTEN' => 'Anak kucing',
        'ADULT' => 'Dewasa',
        'SENIOR' => 'Lansia',
        _ => null,
      };

  static String _upperOr(Object? value, String fallback) {
    final text = value?.toString().trim().toUpperCase();
    return (text == null || text.isEmpty) ? fallback : text;
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}

/// Filter katalog di aplikasi. Nilai null berarti tidak difilter.
class AdoptionCatalogFilter {
  final String? gender; // MALE, FEMALE
  final String? ageGroup; // KITTEN, ADULT, SENIOR

  const AdoptionCatalogFilter({this.gender, this.ageGroup});

  bool get isEmpty => gender == null && ageGroup == null;

  bool matches(AdoptionCatalogCat cat) =>
      (gender == null || cat.gender == gender) &&
      (ageGroup == null || cat.ageGroup == ageGroup);
}
