import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/app_header_bar.dart';
import '../data/repositories/mock_cat_repository.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockCatRepository(),
      builder: (context, _) {
        final repo = MockCatRepository();
        final points = repo.userExpeditionPoints;
        final observations = repo.userTotalObservations;
        final collected = repo.collectedCats.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const AppHeaderBar(
            title: 'Profil Pengguna',
            subtitle: 'TelCat World • Civitas Akademika',
            statusText: 'Terverifikasi',
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
                  // User Profile Hero Card
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceLg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.borderCard),
                      boxShadow: AppDimensions.cardShadow,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryPeach,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mahasiswa Telkom University',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'S1 Sistem Informasi • 120220xxxx',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.verified_user_rounded, size: 14, color: AppColors.sweetSpotGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'Relawan Sahabat Kucing',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sweetSpotGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceMd),

                  // Three Stat Metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Poin Ekspedisi',
                          value: '$points',
                          emoji: '✨',
                          color: AppColors.primaryPeachDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Observasi',
                          value: '$observations',
                          emoji: '📋',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Terkoleksi',
                          value: '$collected',
                          emoji: '🐾',
                          color: AppColors.sweetSpotGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spaceLg),

                  // Lencana Penghargaan (Badges)
                  const Text(
                    'Lencana Partisipasi Kampus',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildBadgeCard(
                    title: '🏅 Sahabat Kucing Tel-U (Tier Emas)',
                    desc: 'Telah melakukan lebih dari 10 observasi kesehatan satwa dengan akurat.',
                  ),
                  const SizedBox(height: 8),
                  _buildBadgeCard(
                    title: '🔍 Penjelajah TULT & Asrama',
                    desc: 'Berhasil memindai seluruh kucing di zona Gedung Kuliah Terpadu.',
                  ),
                  const SizedBox(height: 8),
                  _buildBadgeCard(
                    title: '💖 Pelindung Satwa Kampus',
                    desc: 'Selalu mengutamakan etika pendekatan tanpa paksaan.',
                  ),

                  const SizedBox(height: AppDimensions.spaceLg),

                  // App Info Callout
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMd),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TelCat World — Super App Kucing Kampus',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capstone Project S1 Sistem Informasi Telkom University (Kelompok SUPER-SUB). Integrasi RESTful API Laravel 11 & Supabase.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String emoji,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
