import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';

class AnimalWelfareCard extends StatelessWidget {
  const AnimalWelfareCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCallout),
        border: Border.all(color: AppColors.borderInteractive, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primaryPeach,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 18,
              color: AppColors.primaryPeachDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sebelum Mulai: Etika Kesejahteraan Satwa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amati dari jarak aman. Jangan mengejar, memegang paksa, atau menyalakan lampu kilat (flash) langsung ke mata kucing.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
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
