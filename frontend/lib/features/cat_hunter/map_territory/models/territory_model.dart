class TerritoryModel {
  final String id;
  final String name;
  final String description;
  final String landmark;
  final int activeCatsCount;
  final String imageAsset;
  final List<String> residentCatIds;
  final double latitude;
  final double longitude;

  const TerritoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.landmark,
    required this.activeCatsCount,
    required this.imageAsset,
    required this.residentCatIds,
    required this.latitude,
    required this.longitude,
  });
}
