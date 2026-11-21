class TelkomCampusLocation {
  final int number;
  final String name;
  final String codePrefix;
  final double latitude;
  final double longitude;

  const TelkomCampusLocation({
    required this.number,
    required this.name,
    required this.codePrefix,
    required this.latitude,
    required this.longitude,
  });

  /// Referensi Resmi 38 Lokasi Kampus Telkom University Berdasarkan Denah Resmi Kampus.
  static const List<TelkomCampusLocation> all = [
    TelkomCampusLocation(number: 1, name: 'Telkom University Landmark Tower (TULT)', codePrefix: 'SPOT-TULT', latitude: -6.9693000, longitude: 107.6281500),
    TelkomCampusLocation(number: 2, name: 'Kantin TULT', codePrefix: 'SPOT-KTULT', latitude: -6.9698500, longitude: 107.6281000),
    TelkomCampusLocation(number: 3, name: 'Asrama Putra', codePrefix: 'SPOT-ASPA', latitude: -6.9704500, longitude: 107.6279500),
    TelkomCampusLocation(number: 4, name: 'Gedung Batek - BTP (Bandung Techno Park)', codePrefix: 'SPOT-BTP', latitude: -6.9703500, longitude: 107.6299500),
    TelkomCampusLocation(number: 5, name: 'Sport Center', codePrefix: 'SPOT-SPORT', latitude: -6.9712500, longitude: 107.6283500),
    TelkomCampusLocation(number: 6, name: 'Asrama Putri', codePrefix: 'SPOT-ASRP', latitude: -6.9722000, longitude: 107.6286500),
    TelkomCampusLocation(number: 7, name: 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)', codePrefix: 'SPOT-GKU', latitude: -6.9719500, longitude: 107.6295500),
    TelkomCampusLocation(number: 8, name: 'Tel-U Coffee', codePrefix: 'SPOT-COFFEE', latitude: -6.9717500, longitude: 107.6290500),
    TelkomCampusLocation(number: 9, name: 'Gedung Lingian - Gd.L (Lab. Perhotelan)', codePrefix: 'SPOT-LING', latitude: -6.9727500, longitude: 107.6294500),
    TelkomCampusLocation(number: 10, name: 'Research & Recreation Area', codePrefix: 'SPOT-RRA', latitude: -6.9711000, longitude: 107.6297500),
    TelkomCampusLocation(number: 11, name: 'Gedung Benggala - TUCH (Tel-U Convention Center)', codePrefix: 'SPOT-TUCH', latitude: -6.9716500, longitude: 107.6307500),
    TelkomCampusLocation(number: 12, name: 'Gedung Sebatik (FIK)', codePrefix: 'SPOT-FIK', latitude: -6.9720500, longitude: 107.6311500),
    TelkomCampusLocation(number: 13, name: 'Gd. Miossu & Maratua (Gd. C & D - FEB)', codePrefix: 'SPOT-FEB', latitude: -6.9715500, longitude: 107.6319500),
    TelkomCampusLocation(number: 14, name: 'Open Library', codePrefix: 'SPOT-LIB', latitude: -6.9719500, longitude: 107.6322500),
    TelkomCampusLocation(number: 15, name: 'Kantin Dekanat', codePrefix: 'SPOT-KDEK', latitude: -6.9722000, longitude: 107.6326500),
    TelkomCampusLocation(number: 16, name: 'Gd. Kawalusu & Intata (Gd. A & B - FKS)', codePrefix: 'SPOT-FKS', latitude: -6.9725500, longitude: 107.6329000),
    TelkomCampusLocation(number: 17, name: 'Gedung Selaru (FIT)', codePrefix: 'SPOT-FIT', latitude: -6.9731500, longitude: 107.6324500),
    TelkomCampusLocation(number: 18, name: 'Danau (Situ Techno)', codePrefix: 'SPOT-DANAU', latitude: -6.9729500, longitude: 107.6311500),
    TelkomCampusLocation(number: 19, name: 'Gedung Bangkit (Gd. Rektorat)', codePrefix: 'SPOT-REKT', latitude: -6.9734500, longitude: 107.6301500),
    TelkomCampusLocation(number: 20, name: 'Gedung Damar - Gd. K (Gedung Auditorium)', codePrefix: 'SPOT-DAMAR', latitude: -6.9738500, longitude: 107.6295500),
    TelkomCampusLocation(number: 21, name: 'Grha Wiyata Cacuk Sudarijanto', codePrefix: 'SPOT-CACUK', latitude: -6.9740500, longitude: 107.6306500),
    TelkomCampusLocation(number: 22, name: 'Gedung Deli (Gd. P)', codePrefix: 'SPOT-DELI', latitude: -6.9742500, longitude: 107.6290500),
    TelkomCampusLocation(number: 23, name: 'Gedung Arakula (Gd. O)', codePrefix: 'SPOT-ARAK', latitude: -6.9747500, longitude: 107.6288500),
    TelkomCampusLocation(number: 24, name: 'Gedung Barung (Gd. N)', codePrefix: 'SPOT-BARUNG', latitude: -6.9752500, longitude: 107.6291800),
    TelkomCampusLocation(number: 25, name: 'Gedung Penambulai (Gd. D)', codePrefix: 'SPOT-PENAM', latitude: -6.9747000, longitude: 107.6298500),
    TelkomCampusLocation(number: 26, name: 'Gedung Panehan (Gd. G - Pascasarjana)', codePrefix: 'SPOT-PANEH', latitude: -6.9749500, longitude: 107.6303500),
    TelkomCampusLocation(number: 27, name: 'Gedung Karang (Gd. C - Pascasarjana)', codePrefix: 'SPOT-KARANG', latitude: -6.9748000, longitude: 107.6308500),
    TelkomCampusLocation(number: 28, name: 'Gedung Pelampong - GSG (Gd. H - GD. Serba Guna)', codePrefix: 'SPOT-GSG', latitude: -6.9755500, longitude: 107.6295500),
    TelkomCampusLocation(number: 29, name: 'Gd. Kultubai Utara (Gd. E)', codePrefix: 'SPOT-KULTU', latitude: -6.9755000, longitude: 107.6301500),
    TelkomCampusLocation(number: 30, name: 'Gd. Kultubai Selatan (Gd. F)', codePrefix: 'SPOT-KULTS', latitude: -6.9759500, longitude: 107.6304500),
    TelkomCampusLocation(number: 31, name: 'Gedung Karaweira (Gd. Student Center)', codePrefix: 'SPOT-SC', latitude: -6.9761500, longitude: 107.6291500),
    TelkomCampusLocation(number: 32, name: 'Lapangan Tenis', codePrefix: 'SPOT-TENIS', latitude: -6.9763500, longitude: 107.6294500),
    TelkomCampusLocation(number: 33, name: 'Gedung Alor (Gd. Business Center)', codePrefix: 'SPOT-ALOR', latitude: -6.9762500, longitude: 107.6299000),
    TelkomCampusLocation(number: 34, name: 'Kantin Teknik', codePrefix: 'SPOT-KTEK', latitude: -6.9765500, longitude: 107.6303500),
    TelkomCampusLocation(number: 35, name: 'Greenhouse', codePrefix: 'SPOT-GH', latitude: -6.9764500, longitude: 107.6309500),
    TelkomCampusLocation(number: 36, name: 'Pool KBM', codePrefix: 'SPOT-KBM', latitude: -6.9759500, longitude: 107.6317500),
    TelkomCampusLocation(number: 37, name: 'Masjid Syamsul Ulum', codePrefix: 'SPOT-MSU', latitude: -6.9752500, longitude: 107.6316500),
    TelkomCampusLocation(number: 38, name: 'Jogging Track', codePrefix: 'SPOT-JOG', latitude: -6.9743500, longitude: 107.6318500),
  ];

  static TelkomCampusLocation resolve(
    double latitude,
    double longitude, {
    String? code,
  }) {
    if (code != null && code.trim().isNotEmpty) {
      final upper = code.trim().toUpperCase();
      for (final loc in all) {
        final prefix = loc.codePrefix.toUpperCase();
        final fsPrefix = prefix.replaceFirst('SPOT-', 'FS-');
        if (upper.startsWith('$prefix-') || upper.startsWith('$fsPrefix-')) {
          return loc;
        }
      }
    }

    var best = all.first;
    var minDistSq = double.infinity;
    for (final loc in all) {
      final dLat = latitude - loc.latitude;
      final dLng = longitude - loc.longitude;
      final distSq = (dLat * dLat) + (dLng * dLng);
      if (distSq < minDistSq) {
        minDistSq = distSq;
        best = loc;
      }
    }
    return best;
  }
}

class FeedingSpotModel {
  final String id;
  final String name;
  final String code;
  final String qrToken;
  final String locationName;
  final int? locationNumber;
  final String? description;
  final String? territoryId;
  final double latitude;
  final double longitude;
  final String status;
  final String? statusReason;
  final String bowlCondition;
  final DateTime? lastFedAt;
  final int activitiesCount;
  final int? verifiedCount14Days;
  final double? needScore;
  final String? imageUrl;
  final String imageAsset;
  final DateTime? aggregateUpdatedAt;
  final bool isStale;
  final bool hasPendingReview;

  /// Client-side only distance in meters (computed locally on device via Geolocator, never sent to server).
  final double? distanceMeters;

  const FeedingSpotModel({
    required this.id,
    required this.name,
    required this.code,
    required this.qrToken,
    required this.locationName,
    this.locationNumber,
    this.description,
    this.territoryId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.statusReason,
    required this.bowlCondition,
    this.lastFedAt,
    this.activitiesCount = 0,
    this.verifiedCount14Days,
    this.needScore,
    this.imageUrl,
    this.imageAsset = 'assets/images/figma/feeding-shelter.png',
    this.aggregateUpdatedAt,
    this.isStale = false,
    this.hasPendingReview = false,
    this.distanceMeters,
  });

  factory FeedingSpotModel.fromJson(Map<String, dynamic> json) {
    final aggregate = json['aggregate'] is Map<String, dynamic>
        ? json['aggregate'] as Map<String, dynamic>
        : null;

    final rawLastFed = json['last_fed_at']?.toString() ??
        aggregate?['last_fed_at']?.toString();

    final rawVerified14d = json['verified_count_14_days'] ??
        aggregate?['total_feedings'] ??
        aggregate?['verified_count'];

    final pendingCount = (aggregate?['pending_count'] as num?)?.toInt() ?? 0;
    final hasPending = json['has_pending_review'] == true || pendingCount > 0;

    final parsedLat = (json['latitude'] != null)
        ? double.tryParse(json['latitude'].toString()) ?? 0.0
        : 0.0;
    final parsedLng = (json['longitude'] != null)
        ? double.tryParse(json['longitude'].toString()) ?? 0.0
        : 0.0;
    final parsedCode = (json['code'] ?? '').toString();

    final resolvedCampusLoc = TelkomCampusLocation.resolve(
      parsedLat,
      parsedLng,
      code: parsedCode,
    );

    final rawLocationName = json['location_name']?.toString().trim();
    final locationName = (rawLocationName != null && rawLocationName.isNotEmpty)
        ? rawLocationName
        : resolvedCampusLoc.name;

    final rawComputedAt = json['aggregate_updated_at']?.toString() ??
        aggregate?['computed_at']?.toString() ??
        '';

    return FeedingSpotModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: parsedCode,
      qrToken: (json['qr_token'] ?? 'MTP1.S.$parsedCode').toString(),
      locationName: locationName,
      locationNumber: (json['location_number'] as num?)?.toInt() ??
          resolvedCampusLoc.number,
      description: json['description']?.toString(),
      territoryId: json['territory_id']?.toString(),
      latitude: parsedLat,
      longitude: parsedLng,
      status: (json['status'] ?? 'ACTIVE').toString().toLowerCase(),
      statusReason: json['status_reason']?.toString(),
      bowlCondition: (json['bowl_condition'] ?? 'unknown').toString(),
      lastFedAt: rawLastFed != null ? DateTime.tryParse(rawLastFed) : null,
      activitiesCount: (json['activities_count'] as num?)?.toInt() ??
          (rawVerified14d as num?)?.toInt() ??
          0,
      verifiedCount14Days: (rawVerified14d as num?)?.toInt(),
      needScore: (aggregate?['need_score'] as num?)?.toDouble(),
      imageUrl: json['image_url']?.toString() ?? json['photo_url']?.toString(),
      aggregateUpdatedAt: DateTime.tryParse(rawComputedAt),
      isStale: json['is_stale'] == true || aggregate?['is_stale'] == true,
      hasPendingReview: hasPending,
    );
  }

  FeedingSpotModel copyWith({
    double? distanceMeters,
    DateTime? lastFedAt,
    int? verifiedCount14Days,
    String? status,
    String? statusReason,
    bool? isStale,
    bool? hasPendingReview,
  }) {
    return FeedingSpotModel(
      id: id,
      name: name,
      code: code,
      qrToken: qrToken,
      locationName: locationName,
      locationNumber: locationNumber,
      description: description,
      territoryId: territoryId,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      bowlCondition: bowlCondition,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      activitiesCount: activitiesCount,
      verifiedCount14Days: verifiedCount14Days ?? this.verifiedCount14Days,
      needScore: needScore,
      imageUrl: imageUrl,
      imageAsset: imageAsset,
      aggregateUpdatedAt: aggregateUpdatedAt,
      isStale: isStale ?? this.isStale,
      hasPendingReview: hasPendingReview ?? this.hasPendingReview,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasLowActivity =>
      verifiedCount14Days != null && verifiedCount14Days! < 7;
  String get activityLabel => verifiedCount14Days == null
      ? 'Data belum tersedia'
      : hasLowActivity
      ? 'Jarang tercatat'
      : 'Rutin tercatat';

  /// AFS-02 & MEOW-25 requirement: Fallback "Belum ada catatan"
  String get lastFedSentence {
    if (lastFedAt == null) {
      return 'Belum ada catatan';
    }
    final diff = DateTime.now().difference(lastFedAt!);
    if (diff.inMinutes < 1) {
      return 'Terakhir tercatat diberi makan baru saja';
    }
    if (diff.inMinutes < 60) {
      return 'Terakhir tercatat diberi makan ${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return 'Terakhir tercatat diberi makan ${diff.inHours} jam lalu';
    }
    return 'Terakhir tercatat diberi makan ${diff.inDays} hari lalu';
  }

  String? get distanceLabel {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m dari lokasimu';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km dari lokasimu';
  }
}
