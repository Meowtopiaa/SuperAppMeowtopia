import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_dimensions.dart';
import '../../models/observation_answer.dart';

class QuizOptionCard extends StatelessWidget {
  final QuizOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const QuizOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPeach : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderCard,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppDimensions.elevatedShadow : AppDimensions.cardShadow,
        ),
        child: Row(
          children: [
            // Emoji / Icon Box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary.withOpacity(0.3) : AppColors.borderSubtle,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                option.iconEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            // Text labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primaryPeachDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isSelected ? AppColors.primaryPeachDark.withOpacity(0.8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Radio circle indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderInteractive,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
