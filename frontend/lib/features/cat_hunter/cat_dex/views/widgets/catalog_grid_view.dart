import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../data/models/cat_model.dart';
import '../../data/repositories/mock_cat_repository.dart';
import 'catbook_polaroid_modal.dart';

enum CatalogFilter {
  all,
  collected,
  uncollected,
}

class CatalogGridView extends StatefulWidget {
  final VoidCallback onVisitInCafe;

  const CatalogGridView({
    super.key,
    required this.onVisitInCafe,
  });

  @override
  State<CatalogGridView> createState() => _CatalogGridViewState();
}

class _CatalogGridViewState extends State<CatalogGridView> {
  CatalogFilter _selectedFilter = CatalogFilter.all;

  @override
  Widget build(BuildContext context) {
    final repo = MockCatRepository();
    final allCats = repo.allCats;
    final collectedCount = repo.collectedCats.length;
    final totalCount = allCats.length;

    List<CatModel> displayedCats;
    switch (_selectedFilter) {
      case CatalogFilter.all:
        displayedCats = allCats;
        break;
      case CatalogFilter.collected:
        displayedCats = repo.collectedCats;
        break;
      case CatalogFilter.uncollected:
        displayedCats = repo.uncollectedCats;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginHorizontal,
        vertical: AppDimensions.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collection Progress Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$collectedCount dari $totalCount Kucing Kampus',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${((collectedCount / totalCount) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: collectedCount / totalCount,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceMd),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua ($totalCount)', CatalogFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Terkoleksi ($collectedCount)', CatalogFilter.collected),
                const SizedBox(width: 8),
                _buildFilterChip('Belum Ditemukan (${totalCount - collectedCount})', CatalogFilter.uncollected),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceMd),

          // 2-Column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedCats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final cat = displayedCats[index];
              return _buildCatCard(context, cat);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CatalogFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderInteractive,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCatCard(BuildContext context, CatModel cat) {
    if (cat.isCollected) {
      // Collected Card (Full Color)
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => CatbookPolaroidModal(
              cat: cat,
              onVisitInCafe: widget.onVisitInCafe,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.borderCard),
            boxShadow: AppDimensions.cardShadow,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryPeach,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      cat.avatarAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                cat.zone,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sweetSpotGreenBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.sweetSpotGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Lv. ${cat.friendshipLevel}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sweetSpotGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Uncollected Card (Dark Silhouette & Question mark)
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F3),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Silhouette Avatar with ???
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF2C2C34),
                        BlendMode.srcIn,
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 56,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: const Text(
                        '???',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Belum Ditemukan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Petunjuk: ${cat.zone}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.borderInteractive),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_rounded, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Pindai QR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
