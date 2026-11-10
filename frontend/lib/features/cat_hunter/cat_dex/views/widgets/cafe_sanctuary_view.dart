import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../../constants/app_assets.dart';
import '../../data/models/cat_model.dart';
import '../../data/repositories/mock_cat_repository.dart';

class CafeSanctuaryView extends StatefulWidget {
  final VoidCallback onSwitchToCatalog;

  const CafeSanctuaryView({
    super.key,
    required this.onSwitchToCatalog,
  });

  @override
  State<CafeSanctuaryView> createState() => _CafeSanctuaryViewState();
}

class _CafeSanctuaryViewState extends State<CafeSanctuaryView> {
  CatModel? _activeTappedCat;
  bool _showHeartAnimation = false;
  Offset _heartPosition = Offset.zero;

  // Preset isometric spots on cafe scene canvas (percentages from left & top)
  final List<Offset> _catSpots = const [
    Offset(0.20, 0.65), // Pillow Spot 1 (Bottom Left)
    Offset(0.55, 0.72), // Box Spot 2 (Bottom Center)
    Offset(0.78, 0.45), // Cat Tree Spot 3 (Mid Right)
    Offset(0.35, 0.42), // Rug Spot 4 (Center)
    Offset(0.72, 0.22), // High Stool Spot 5 (Top Right)
    Offset(0.18, 0.28), // Window Spot 6 (Top Left)
  ];

  void _onTapCat(CatModel cat, TapDownDetails details) {
    setState(() {
      _activeTappedCat = cat;
      _showHeartAnimation = true;
      _heartPosition = details.localPosition;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockCatRepository();
    final activeCats = repo.cafeActiveCats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.marginHorizontal,
        vertical: AppDimensions.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sanctuary Room Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
              border: Border.all(color: AppColors.borderCard),
              boxShadow: AppDimensions.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.sweetSpotGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${activeCats.length} Kucing Bersantai di Kafe',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPeach,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: const Text(
                    'Suasana: Damai ☕',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPeachDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceMd),

          // Isometric Cafe Showcase Canvas
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
              color: const Color(0xFFE5DDD5),
              boxShadow: AppDimensions.cardShadow,
              border: Border.all(color: AppColors.borderCard),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasWidth = constraints.maxWidth;
                final canvasHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    // Cafe Isometric Background
                    Positioned.fill(
                      child: Image.asset(
                        AppAssets.cafeBackground,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF3ECE4),
                          child: const Center(
                            child: Icon(Icons.coffee_rounded, size: 48, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),

                    // Ambient Warm Lighting Tint
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Active Cats Scattered in Cafe Spots
                    ...List.generate(activeCats.length, (index) {
                      final cat = activeCats[index];
                      final spot = _catSpots[index % _catSpots.length];
                      final left = spot.dx * canvasWidth;
                      final top = spot.dy * canvasHeight;

                      return Positioned(
                        left: left - 32,
                        top: top - 32,
                        child: GestureDetector(
                          onTapDown: (details) => _onTapCat(cat, details),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing Heart Indicator or Cat Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.15),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('❤️', style: TextStyle(fontSize: 10)),
                                    const SizedBox(width: 4),
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryPeachDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Cat Avatar in Cafe
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  cat.avatarAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.pets,
                                    size: 26,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Tap Heart Animation
                    if (_showHeartAnimation)
                      Positioned(
                        left: _heartPosition.dx - 20,
                        top: _heartPosition.dy - 30,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.4),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: const Text('💖', style: TextStyle(fontSize: 32)),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: AppDimensions.spaceMd),

          // Speech Bubble when a cat is tapped
          if (_activeTappedCat != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                boxShadow: AppDimensions.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      _activeTappedCat!.avatarAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _activeTappedCat!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Suvenir: ${_activeTappedCat!.mementoName}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPeachDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${_activeTappedCat!.cafeQuote}"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sentuh salah satu kucing di kafe untuk berinteraksi dan melihat suvenirnya!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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
