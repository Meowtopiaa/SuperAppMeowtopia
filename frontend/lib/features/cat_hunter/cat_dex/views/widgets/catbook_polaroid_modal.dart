import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../../widgets/primary_button.dart';
import '../../data/models/cat_model.dart';

class CatbookPolaroidModal extends StatelessWidget {
  final CatModel cat;
  final VoidCallback onVisitInCafe;

  const CatbookPolaroidModal({
    super.key,
    required this.cat,
    required this.onVisitInCafe,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.polaroidCard, // Warm Cream
          borderRadius: BorderRadius.circular(AppDimensions.radiusModal),
          border: Border.all(color: const Color(0xFFEADBCE), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              blurRadius: 28,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title with close icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.primaryPeachDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Catbook Tel-U: ${cat.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Polaroid Section: Photo on Left, Stats on Right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Polaroid Photo Frame
                  Container(
                    width: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.12),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              cat.photoAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
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
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          cat.zone,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Stats on Right
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow('Kepribadian', cat.personality, Icons.psychology_rounded),
                        const SizedBox(height: 8),
                        _buildStatRow('Tingkat Luluh', 'Level ${cat.friendshipLevel} (${cat.trustPercentage}%)', Icons.favorite_rounded),
                        const SizedBox(height: 8),
                        _buildStatRow('Jumlah Observasi', '${cat.observationCount} kali tercatat', Icons.fact_check_rounded),
                        const SizedBox(height: 8),
                        _buildStatRow('Kesehatan', cat.healthStatus, Icons.verified_rounded),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Campus Memento Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: const Color(0xFFEADBCE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Suvenir Kampus: ${cat.mementoName}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPeachDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.mementoDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Button: Kunjungi di Kafe Kucing
              PrimaryButton(
                label: 'Kunjungi di Kafe Kucing ☕',
                icon: Icons.coffee_rounded,
                onPressed: () {
                  Navigator.of(context).pop();
                  onVisitInCafe();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryPeachDark),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
