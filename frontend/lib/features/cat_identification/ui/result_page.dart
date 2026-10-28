import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/identification_provider.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IdentificationProvider>();
    final cat = provider.matchedCat;
    final confidence = provider.confidence;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Identifikasi Kucing')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: cat != null ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              child: Icon(
                cat != null ? Icons.verified : Icons.help_outline,
                size: 54,
                color: cat != null ? AppConstants.successColor : AppConstants.dangerColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              cat != null ? 'Kucing Dikenali: ${cat.name}' : 'Belum Ada Kecocokan Pasti',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tingkat Keyakinan: ${confidence.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppConstants.primaryColor),
            ),
            const SizedBox(height: 24),
            if (cat != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.pets),
                        title: Text(cat.name),
                        subtitle: Text('${cat.breed} • ${cat.gender == 'male' ? 'Jantan' : 'Betina'}'),
                      ),
                      Text('Warna: ${cat.primaryColor ?? "-"} • Pola: ${cat.pattern ?? "-"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Buka Profil Lengkap Kucing',
                onPressed: () => context.push('/cats/${cat.id}'),
              ),
            ] else ...[
              const Text(
                'Kucing ini mungkin belum terdaftar di database Meowtopia. Anda dapat melapor ke tim relawan atau mendaftarkannya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConstants.textSecondary),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Kembali ke Beranda',
                onPressed: () => context.go('/feeding'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
