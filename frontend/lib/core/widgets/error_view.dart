import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'custom_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppConstants.dangerColor,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Terjadi Masalah',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 140,
                child: CustomButton(
                  text: 'Coba Lagi',
                  onPressed: onRetry,
                  icon: Icons.refresh,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
