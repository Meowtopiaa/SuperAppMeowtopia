import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../constants/app_assets.dart';
import '../../widgets/app_header_bar.dart';
import '../../cat_dex/data/repositories/mock_cat_repository.dart';
import '../models/territory_model.dart';
import 'territory_detail_screen.dart';

class TerritoryMapScreen extends StatefulWidget {
  const TerritoryMapScreen({super.key});

  @override
  State<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends State<TerritoryMapScreen> {
  TerritoryModel? _selectedTerritory;

  @override
  Widget build(BuildContext context) {
    final repo = MockCatRepository();
    final territories = repo.territories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(
        title: 'Peta Teritorial Kucing',
        subtitle: 'TelCat World • Kampus Tel-U',
        statusText: '4 Zona',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginHorizontal,
            vertical: AppDimensions.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campus Map Card Container
              Container(
                height: 290,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  color: Colors.white,
                  border: Border.all(color: AppColors.borderCard),
                  boxShadow: AppDimensions.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Isometric Map Image
                    Positioned.fill(
                      child: Image.asset(
                        AppAssets.campusMap,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceSubtle,
                          child: const Center(
                            child: Icon(Icons.map_rounded, size: 54, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),

                    // Map Pins Overlay
                    // 1. TULT Pin (Center-Left)
                    Positioned(
                      top: 60,
                      left: 45,
                      child: _buildMapPin(
                        territories[0],
                        '🏢 TULT & Asrama',
                        isSelected: _selectedTerritory?.id == territories[0].id,
                      ),
                    ),

                    // 2. GKU Pin (Bottom-Left)
                    Positioned(
                      bottom: 50,
                      left: 70,
                      child: _buildMapPin(
                        territories[1],
                        '🏫 GKU Kuliah',
                        isSelected: _selectedTerritory?.id == territories[1].id,
                      ),
                    ),

                    // 3. Situ Techno & Open Lib Pin (Center-Right)
                    Positioned(
                      top: 100,
                      right: 40,
                      child: _buildMapPin(
                        territories[2],
                        '🌊 Danau & Oplib',
                        isSelected: _selectedTerritory?.id == territories[2].id,
                      ),
                    ),

                    // 4. Student Center Pin (Bottom-Right)
                    Positioned(
                      bottom: 45,
                      right: 65,
                      child: _buildMapPin(
                        territories[3],
                        '☕ SC & Deli',
                        isSelected: _selectedTerritory?.id == territories[3].id,
                      ),
                    ),

                    // Top Left Campus Tag
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Denah Telkom University',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLg),

              // Territory List Heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Zona Teritorial Kampus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${territories.length} Wilayah',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceSm),

              // List of Territory Cards
              ...territories.map((t) => _buildTerritoryCard(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPin(TerritoryModel territory, String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTerritory = territory;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TerritoryDetailScreen(territory: territory),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            Icons.location_on_rounded,
            size: 24,
            color: isSelected ? AppColors.primaryLight : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTerritoryCard(BuildContext context, TerritoryModel territory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TerritoryDetailScreen(territory: territory),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Row(
              children: [
                // Landmark thumbnail
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    color: AppColors.primaryPeach,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    territory.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        territory.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        territory.landmark,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.pets, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${territory.residentCatIds.length} Kucing Penghuni',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
