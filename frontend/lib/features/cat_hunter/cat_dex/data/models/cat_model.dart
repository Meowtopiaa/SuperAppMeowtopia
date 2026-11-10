class CatModel {
  final String id;
  final String name;
  final String qrHash;
  final String zone;
  final String locationDetail;
  final String avatarAsset;
  final String photoAsset;
  final String healthStatus;
  final String personality;
  final int friendshipLevel;
  final int trustPercentage;
  final int observationCount;
  final String lastObservedDate;
  final String mementoName;
  final String mementoDescription;
  final bool isCollected;
  final bool isCurrentlyInCafe;
  final String cafePose; // 'pillow', 'box', 'tree', 'carpet', 'stool'
  final String cafeQuote;

  const CatModel({
    required this.id,
    required this.name,
    required this.qrHash,
    required this.zone,
    required this.locationDetail,
    required this.avatarAsset,
    required this.photoAsset,
    required this.healthStatus,
    required this.personality,
    this.friendshipLevel = 1,
    this.trustPercentage = 20,
    this.observationCount = 1,
    required this.lastObservedDate,
    required this.mementoName,
    required this.mementoDescription,
    this.isCollected = false,
    this.isCurrentlyInCafe = false,
    this.cafePose = 'pillow',
    this.cafeQuote = 'Meoong... senangnya dikunjungi!',
  });

  CatModel copyWith({
    String? id,
    String? name,
    String? qrHash,
    String? zone,
    String? locationDetail,
    String? avatarAsset,
    String? photoAsset,
    String? healthStatus,
    String? personality,
    int? friendshipLevel,
    int? trustPercentage,
    int? observationCount,
    String? lastObservedDate,
    String? mementoName,
    String? mementoDescription,
    bool? isCollected,
    bool? isCurrentlyInCafe,
    String? cafePose,
    String? cafeQuote,
  }) {
    return CatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      qrHash: qrHash ?? this.qrHash,
      zone: zone ?? this.zone,
      locationDetail: locationDetail ?? this.locationDetail,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      photoAsset: photoAsset ?? this.photoAsset,
      healthStatus: healthStatus ?? this.healthStatus,
      personality: personality ?? this.personality,
      friendshipLevel: friendshipLevel ?? this.friendshipLevel,
      trustPercentage: trustPercentage ?? this.trustPercentage,
      observationCount: observationCount ?? this.observationCount,
      lastObservedDate: lastObservedDate ?? this.lastObservedDate,
      mementoName: mementoName ?? this.mementoName,
      mementoDescription: mementoDescription ?? this.mementoDescription,
      isCollected: isCollected ?? this.isCollected,
      isCurrentlyInCafe: isCurrentlyInCafe ?? this.isCurrentlyInCafe,
      cafePose: cafePose ?? this.cafePose,
      cafeQuote: cafeQuote ?? this.cafeQuote,
    );
  }
}
