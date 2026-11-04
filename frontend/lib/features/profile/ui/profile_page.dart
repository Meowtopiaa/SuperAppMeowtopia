import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../../auth/logic/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return MeowPage(
      back: false,
      child: ListView(
        padding: MeowPage.scrollPadding(context),
        children: [
          const Text(
            'Profil',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tempat kecil untuk mengenalmu lebih dekat.',
            style: TextStyle(color: MeowStyle.brown, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              children: [
                const IconBubble(Icons.person_rounded, size: 76),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Teman Kucing',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Masuk untuk menyimpan kepedulianmu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MeowStyle.brown, fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (user == null)
                  MeowButton(
                    label: 'Masuk ke akun',
                    icon: Icons.login_rounded,
                    onPressed: () => context.push('/login'),
                  )
                else
                  MeowPill(
                    '${user.pointsBalance} poin',
                    icon: Icons.stars_outlined,
                    color: MeowStyle.lilac,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (user != null) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Informasi akun'),
                  const SizedBox(height: 16),
                  _AccountLine('Email', user.email),
                  if (user.studentId != null)
                    _AccountLine('NIM', user.studentId!),
                  if (user.phone != null) _AccountLine('Telepon', user.phone!),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.history_rounded,
                    color: MeowStyle.orangeDark,
                  ),
                  title: const Text(
                    'Semua aktivitas saya',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/activity'),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                ListTile(
                  leading: const Icon(
                    Icons.apps_rounded,
                    color: MeowStyle.orangeDark,
                  ),
                  title: const Text(
                    'Jelajahi fitur',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/explore'),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: MeowStyle.orangeDark,
                  ),
                  title: const Text(
                    'Tentang Meowtopia',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: '1.0.0',
                    applicationIcon: Image.asset(
                      'assets/images/figma/meowtopia-logo.png',
                      width: 48,
                      height: 48,
                    ),
                    children: const [
                      Text(
                        'Ekosistem kepedulian dan kesejahteraan kucing kampus. Capstone Design Project, Universitas Telkom.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user != null)
            MeowButton(
              label: 'Keluar dari akun',
              icon: Icons.logout_rounded,
              secondary: true,
              onPressed: () async {
                try {
                  await auth.logout();
                  if (context.mounted) context.go('/home');
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belum dapat keluar. Silakan coba lagi.'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

class _AccountLine extends StatelessWidget {
  const _AccountLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: MeowStyle.brown),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
