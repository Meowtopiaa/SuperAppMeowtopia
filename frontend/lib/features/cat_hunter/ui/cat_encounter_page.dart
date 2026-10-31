import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/cat_hunter_provider.dart';

class CatEncounterPage extends StatefulWidget {
  const CatEncounterPage({super.key});

  @override
  State<CatEncounterPage> createState() => _CatEncounterPageState();
}

class _CatEncounterPageState extends State<CatEncounterPage> {
  final _qrController = TextEditingController(text: 'MEOW-CAT-DEMO123');
  String _condition = 'sehat';

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  void _onEncounter() async {
    final hunter = context.read<CatHunterProvider>();

    final success = await hunter.startEncounter(
      qrToken: _qrController.text.trim(),
      latitude: -6.9740,
      longitude: 107.6303,
      condition: _condition,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kucing berhasil dijinakkan! +20 Poin & masuk Cat Dex 🎉',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
      context.pop();
    } else if (mounted && hunter.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hunter.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hunter = context.watch<CatHunterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Telcat - Turn-Based Encounter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppConstants.primaryLight,
              child: Icon(
                Icons.pets,
                size: 50,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pindai QR Kalung Kucing Nyata',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Telcat tidak menggunakan AR virtual. Setiap kucing kampus memiliki kalung QR unik untuk memulai mini-game encounter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _qrController,
              decoration: const InputDecoration(
                labelText: 'Token QR Kalung Kucing',
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'Kondisi Kucing Saat Ini',
                prefixIcon: Icon(Icons.favorite_border),
              ),
              items: const [
                DropdownMenuItem(value: 'sehat', child: Text('Sehat & Ceria')),
                DropdownMenuItem(value: 'tidur', child: Text('Sedang Tidur')),
                DropdownMenuItem(value: 'lapar', child: Text('Tampak Lapar')),
                DropdownMenuItem(
                  value: 'luka_ringan',
                  child: Text('Luka Ringan / Lemas'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _condition = val);
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Mulai Encounter (Elus & Jinakkan)',
              isLoading: hunter.isLoading,
              onPressed: _onEncounter,
              icon: Icons.play_arrow_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
