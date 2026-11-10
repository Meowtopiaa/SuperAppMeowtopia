import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/primary_button.dart';
import '../../cat_dex/data/repositories/mock_cat_repository.dart';
import '../../cat_dex/data/models/cat_model.dart';
import '../../qr_scan/views/qr_scan_screen.dart';
import '../models/territory_model.dart';

class TerritoryDetailScreen extends StatelessWidget {
  final TerritoryModel territory;

  const TerritoryDetailScreen({
    super.key,
    required this.territory,
  });

  @override
  Widget build(BuildContext context) {
    final repo = MockCatRepository();
    final residentCats = territory.residentCatIds
        .map((id) => repo.getCatById(id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(
        title: territory.name,
        subtitle: 'Zona Kampus Tel-U',
        statusText: '${residentCats.length} Kucing',
        showBackButton: true,
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
              // Zone Banner Card
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  boxShadow: AppDimensions.cardShadow,
                  border: Border.all(color: AppColors.borderCard),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        territory.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryPeach,
                          child: const Icon(Icons.location_city_rounded, size: 48, color: AppColors.primary),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          territory.landmark,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMd),

              // Description Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.borderCard),
                  boxShadow: AppDimensions.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tentang Teritorial Ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      territory.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLg),

              // Resident Cats Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kucing Penghuni Wilayah (${residentCats.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Sering Terpantau',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceSm),

              ...residentCats.map((cat) => _buildResidentCatTile(context, cat)),

              const SizedBox(height: AppDimensions.spaceLg),

              // Shortcut CTA: Pindai QR di Zona Ini
              PrimaryButton(
                label: 'Pindai QR di Zona ${territory.name}',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () {
                  final initialTarget = residentCats.isNotEmpty ? residentCats.first.id : null;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QrScanScreen(initialCatId: initialTarget),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentCatTile(BuildContext context, CatModel cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPeach,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              cat.avatarAsset,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (cat.isCollected)
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.sweetSpotGreen)
                    else
                      const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.textTertiary),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  cat.locationDetail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  cat.personality,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primaryPeachDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            color: AppColors.textSecondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QrScanScreen(initialCatId: cat.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
