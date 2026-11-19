import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../cat_dex/data/models/cat_model.dart';
import '../../quiz_observation/models/observation_answer.dart';

class ResultModalDialog extends StatelessWidget {
  final CatModel cat;
  final ObservationSubmission observation;
  final int earnedPoints;
  final VoidCallback onOpenCatDex;
  final VoidCallback onBackToHome;

  const ResultModalDialog({
    super.key,
    required this.cat,
    required this.observation,
    required this.earnedPoints,
    required this.onOpenCatDex,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceXl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusModal),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.2),
              blurRadius: 30,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Joyful Cat Avatar / Illustration
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPeach,
                    shape: BoxShape.circle,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  child: Image.asset(
                    cat.avatarAsset,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.sweetSpotGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Heading & Subheading
            Text(
              '${cat.name} Berhasil Diluluhkan!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Terima kasih atas partisipasi sains warga Anda! Data observasi fisik telah tersimpan rapi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Expedition Point Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryPeach,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '+$earnedPoints Poin Ekspedisi Diklaim',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPeachDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCallout),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Lokasi: ${cat.zone} (${cat.locationDetail})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, size: 14, color: AppColors.sweetSpotGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Suvenir Terbuka: ${cat.mementoName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            PrimaryButton(
              label: 'Buka Cat-Dex',
              icon: Icons.pets_rounded,
              onPressed: onOpenCatDex,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Kembali ke Beranda',
              onPressed: onBackToHome,
            ),
          ],
        ),
      ),
    );
  }
}
