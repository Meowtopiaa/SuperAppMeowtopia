import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/primary_button.dart';
import '../../cat_dex/data/repositories/mock_cat_repository.dart';
import '../../cat_dex/data/models/cat_model.dart';
import '../../quiz_observation/views/quiz_observation_screen.dart';
import 'widgets/animal_welfare_card.dart';

class QrScanScreen extends StatefulWidget {
  final String? initialCatId;

  const QrScanScreen({super.key, this.initialCatId});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerAnimController;
  late Animation<double> _scanLineAnimation;
  bool _isFlashOn = false;
  late CatModel _selectedCat;

  @override
  void initState() {
    super.initState();
    final repo = MockCatRepository();
    _selectedCat = widget.initialCatId != null
        ? repo.getCatById(widget.initialCatId!)
        : repo.allCats.first;

    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(
        parent: _scannerAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scannerAnimController.dispose();
    super.dispose();
  }

  void _proceedToQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizObservationScreen(scannedCat: _selectedCat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockCatRepository();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(
        title: 'Kucing Kampus',
        subtitle: 'TelCat World • Pemindai QR',
        statusText: 'GPS Tel-U',
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
              // Geolocation Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sweetSpotGreenBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.sweetSpotGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.sweetSpotGreen,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Geolokasi Valid: Di Dalam Area Kampus Telkom University',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sweetSpotGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMd),

              // Camera Viewfinder Mock Card
              Container(
                height: 290,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  boxShadow: AppDimensions.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Grid Mock lines
                      const Opacity(opacity: 0.15, child: GridPaper(
                          color: Colors.white,
                          divisions: 2,
                          subdivisions: 1,
                        ),
                      ),

                      // Viewfinder Frame Corners
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          children: [
                            // Top-Left Corner
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.primary, width: 4),
                                    left: BorderSide(color: AppColors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                            // Top-Right Corner
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.primary, width: 4),
                                    right: BorderSide(color: AppColors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom-Left Corner
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.primary, width: 4),
                                    left: BorderSide(color: AppColors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom-Right Corner
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.primary, width: 4),
                                    right: BorderSide(color: AppColors.primary, width: 4),
                                  ),
                                ),
                              ),
                            ),

                            // Scanning Beam Animation
                            AnimatedBuilder(
                              animation: _scanLineAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanLineAnimation.value * 200,
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // QR Collar Center Icon
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flash Toggle Button
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFlashOn = !_isFlashOn;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isFlashOn
                                  ? AppColors.primary
                                  : Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFlashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Hint Text in camera
                      Positioned(
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: const Text(
                            'Arahkan kamera ke kalung QR kucing kampus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMd),

              // Mock Target Selector for Testing/Simulation
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.borderCard, width: 1),
                  boxShadow: AppDimensions.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kucing yang Terdeteksi:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPeach,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedCat.qrHash,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPeachDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CatModel>(
                      value: _selectedCat,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          borderSide: const BorderSide(color: AppColors.borderInteractive),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          borderSide: const BorderSide(color: AppColors.borderInteractive),
                        ),
                      ),
                      items: repo.allCats.map((cat) {
                        return DropdownMenuItem<CatModel>(
                          value: cat,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.pets_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${cat.name} (${cat.zone})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (cat) {
                        if (cat != null) {
                          setState(() {
                            _selectedCat = cat;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMd),

              // Animal Welfare Callout Card
              const AnimalWelfareCard(),

              const SizedBox(height: AppDimensions.spaceLg),

              // Scan Action Button
              PrimaryButton(
                label: 'Mulai Observasi: ${_selectedCat.name}',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: _proceedToQuiz,
              ),

              const SizedBox(height: AppDimensions.spaceMd),
            ],
          ),
        ),
      ),
    );
  }
}
