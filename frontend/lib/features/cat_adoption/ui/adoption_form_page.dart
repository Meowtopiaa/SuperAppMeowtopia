import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/adoption_provider.dart';

class AdoptionFormPage extends StatefulWidget {
  final int catId;
  final String catName;

  const AdoptionFormPage({
    super.key,
    required this.catId,
    required this.catName,
  });

  @override
  State<AdoptionFormPage> createState() => _AdoptionFormPageState();
}

class _AdoptionFormPageState extends State<AdoptionFormPage> {
  String _housingType = 'kos';
  bool _financialReadiness = true;
  bool _familyPermission = true;

  void _onSubmit() async {
    final adoption = context.read<AdoptionProvider>();

    final success = await adoption.submitApplication(
      catId: widget.catId,
      housingType: _housingType,
      financialReadiness: _financialReadiness,
      familyPermission: _familyPermission,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Formulir adopsi berhasil dikirim! Menunggu persetujuan admin.',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
      context.pop();
    } else if (mounted && adoption.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adoption.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adoption = context.watch<AdoptionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Adopsi: ${widget.catName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulir Kesiapan & Komitmen Adopter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesuai ketentuan kesejahteraan hewan, mohon lengkapi kriteria tempat tinggal dan komitmen Anda.',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tipe Tempat Tinggal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _housingType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.home_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'kos',
                  child: Text('Kos (Boleh Pelihara Hewan)'),
                ),
                DropdownMenuItem(
                  value: 'rumah_kontrakan',
                  child: Text('Rumah Kontrakan'),
                ),
                DropdownMenuItem(
                  value: 'rumah_pribadi',
                  child: Text('Rumah Pribadi'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _housingType = val);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Kesiapan Finansial'),
              subtitle: const Text(
                'Sanggup memenuhi pakan, pasir, dan vaksin rutin kucing.',
              ),
              value: _financialReadiness,
              onChanged: (val) => setState(() => _financialReadiness = val),
            ),
            SwitchListTile(
              title: const Text('Izin Pemilik Tempat / Keluarga'),
              subtitle: const Text(
                'Telah mendapat izin dari pemilik kos atau keluarga di rumah.',
              ),
              value: _familyPermission,
              onChanged: (val) => setState(() => _familyPermission = val),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Kirim Pengajuan Adopsi',
              isLoading: adoption.isLoading,
              onPressed: _onSubmit,
              icon: Icons.send_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
