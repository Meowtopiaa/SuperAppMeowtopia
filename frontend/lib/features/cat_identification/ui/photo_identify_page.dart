import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';

class PhotoIdentifyPage extends StatelessWidget {
  const PhotoIdentifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identifikasi via Foto')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 54, color: AppConstants.primaryColor),
                  SizedBox(height: 12),
                  Text('Ambil atau Unggah Foto Kucing', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Pastikan wajah atau corak tubuh terlihat jelas', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Lanjutkan ke Pertanyaan Ciri Fisik',
              onPressed: () => context.push('/identify/question'),
              icon: Icons.navigate_next,
            ),
          ],
        ),
      ),
    );
  }
}
