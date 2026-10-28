import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/identification_provider.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final _qrController = TextEditingController(text: 'MEOW-CAT-DEMO123');

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  void _onScan() async {
    final provider = context.read<IdentificationProvider>();
    final success = await provider.identifyByQr(_qrController.text.trim());

    if (mounted && success) {
      context.push('/identify/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IdentificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Identifikasi via QR Kalung')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: AppConstants.primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Pindai QR Code Kalung Kucing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Metode paling cepat dan akurat 100% jika kucing masih mengenakan kalung resmi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _qrController,
              decoration: const InputDecoration(
                labelText: 'Hasil Scan Token QR',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Cek Database Kucing',
              isLoading: provider.isLoading,
              onPressed: _onScan,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.push('/identify/question'),
              child: const Text('Kalung kucing hilang? Gunakan Kuesioner Ciri Fisik'),
            ),
          ],
        ),
      ),
    );
  }
}
