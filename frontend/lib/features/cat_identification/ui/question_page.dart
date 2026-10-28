import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/identification_provider.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  String _selectedColor = 'Orange / Jahe';
  String _selectedPattern = 'Tabby / Belang';
  String _selectedTail = 'Panjang Lurus';

  void _onSubmit() async {
    final provider = context.read<IdentificationProvider>();
    final success = await provider.identifyByQuestions({
      'primary_color': _selectedColor,
      'pattern': _selectedPattern,
      'tail': _selectedTail,
    });

    if (mounted && success) {
      context.push('/identify/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IdentificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kuesioner Ciri Fisik Kucing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identifikasi Berdasarkan Ciri Fisik',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Jawab pertanyaan berikut untuk membantu sistem mencocokkan kucing dengan database kampus.',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text('1. Warna Dominan Bulu Kucing', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.palette_outlined)),
              items: const [
                DropdownMenuItem(value: 'Orange / Jahe', child: Text('Orange / Jahe (Kucing Oren)')),
                DropdownMenuItem(value: 'Hitam', child: Text('Hitam Pekat')),
                DropdownMenuItem(value: 'Putih', child: Text('Putih Polos')),
                DropdownMenuItem(value: 'Abu-abu', child: Text('Abu-abu / Kelabu')),
                DropdownMenuItem(value: 'Kembang Telon (Calico)', child: Text('Kembang Telon / Tiga Warna (Calico)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedColor = val);
              },
            ),
            const SizedBox(height: 20),
            const Text('2. Corak / Pola Bulu', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPattern,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.texture)),
              items: const [
                DropdownMenuItem(value: 'Tabby / Belang', child: Text('Tabby / Bergaris Garis')),
                DropdownMenuItem(value: 'Tuxedo', child: Text('Tuxedo (Hitam & Putih di Dada)')),
                DropdownMenuItem(value: 'Solid / Polos', child: Text('Solid / Satu Warna Saja')),
                DropdownMenuItem(value: 'Bicolor', child: Text('Dua Warna Campur')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedPattern = val);
              },
            ),
            const SizedBox(height: 20),
            const Text('3. Bentuk Ekor', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTail,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.line_axis)),
              items: const [
                DropdownMenuItem(value: 'Panjang Lurus', child: Text('Panjang Lurus')),
                DropdownMenuItem(value: 'Pendek / Bundel', child: Text('Pendek / Bundel (Bobtail)')),
                DropdownMenuItem(value: 'Bengkok di Ujung', child: Text('Bengkok di Ujung')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTail = val);
              },
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Cocokkan Karakteristik',
              isLoading: provider.isLoading,
              onPressed: _onSubmit,
              icon: Icons.search,
            ),
          ],
        ),
      ),
    );
  }
}
