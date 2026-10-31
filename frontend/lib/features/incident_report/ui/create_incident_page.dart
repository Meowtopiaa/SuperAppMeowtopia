import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/incident_provider.dart';

class CreateIncidentPage extends StatefulWidget {
  const CreateIncidentPage({super.key});

  @override
  State<CreateIncidentPage> createState() => _CreateIncidentPageState();
}

class _CreateIncidentPageState extends State<CreateIncidentPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _incidentType = 'injured';
  String _urgencyLevel = 'high';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan rincian insiden wajib diisi')),
      );
      return;
    }

    final provider = context.read<IncidentProvider>();
    final success = await provider.submitIncident(
      title: _titleController.text.trim(),
      incidentType: _incidentType,
      urgencyLevel: _urgencyLevel,
      description: _descController.text.trim(),
      latitude: -6.9735,
      longitude: 107.6300,
      locationNote: _locationController.text.trim(),
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Laporan insiden darurat berhasil dikirim! Tim relawan telah disiagakan.',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Insiden Darurat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Insiden',
                hintText: 'Contoh: Kucing Terjebak di Selokan Gedung Selaru',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _incidentType,
              decoration: const InputDecoration(labelText: 'Tipe Insiden'),
              items: const [
                DropdownMenuItem(
                  value: 'injured',
                  child: Text('Kucing Terluka / Tertabrak'),
                ),
                DropdownMenuItem(
                  value: 'severely_ill',
                  child: Text('Sakit Parah / Muntah Darah'),
                ),
                DropdownMenuItem(
                  value: 'trapped',
                  child: Text('Terjebak di Ketinggian / Saluran'),
                ),
                DropdownMenuItem(
                  value: 'abuse',
                  child: Text('Dugaan Penganiayaan Hewan'),
                ),
                DropdownMenuItem(
                  value: 'missing',
                  child: Text('Kucing Hilang / Dicari'),
                ),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _incidentType = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _urgencyLevel,
              decoration: const InputDecoration(labelText: 'Tingkat Urgensi'),
              items: const [
                DropdownMenuItem(
                  value: 'critical',
                  child: Text('Kritis (Butuh Penanganan < 30 Menit)'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text('Tinggi (Segera / Hari Ini)'),
                ),
                DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                DropdownMenuItem(value: 'low', child: Text('Rendah')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _urgencyLevel = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokasi Patokan Kampus',
                hintText: 'Contoh: Dekat kantin Fakultas Rekayasa Industri',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Rincian Kondisi Insiden',
                hintText: 'Jelaskan kondisi fisik kucing, ciri-ciri, dan hal darurat lainnya...',
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Kirim Laporan Darurat',
              backgroundColor: AppConstants.dangerColor,
              isLoading: provider.isLoading,
              onPressed: _onSubmit,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
