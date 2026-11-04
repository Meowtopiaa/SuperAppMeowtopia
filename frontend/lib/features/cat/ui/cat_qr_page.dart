import 'package:flutter/material.dart';

class CatQrPage extends StatelessWidget {
  final String qrToken;

  const CatQrPage({super.key, required this.qrToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Kalung Kucing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_2, size: 160, color: Colors.black87),
              const SizedBox(height: 16),
              Text(
                qrToken,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tunjukkan atau pindai kode ini untuk encounter Telcat atau verifikasi adopsi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
