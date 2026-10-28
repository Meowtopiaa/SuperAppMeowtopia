import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/feeding_spot_provider.dart';

class RecordFeedingPage extends StatefulWidget {
  final int? spotId;
  final String? initialToken;

  const RecordFeedingPage({super.key, this.spotId, this.initialToken});

  @override
  State<RecordFeedingPage> createState() => _RecordFeedingPageState();
}

class _RecordFeedingPageState extends State<RecordFeedingPage> {
  late final TextEditingController _spotIdController;
  late final TextEditingController _qrTokenController;
  final TextEditingController _notesController = TextEditingController();
  String _foodType = 'dry_food';

  @override
  void initState() {
    super.initState();
    _spotIdController = TextEditingController(text: widget.spotId?.toString() ?? '1');
    _qrTokenController = TextEditingController(text: widget.initialToken ?? 'FS-FIT-01-QR');
  }

  @override
  void dispose() {
    _spotIdController.dispose();
    _qrTokenController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    final provider = context.read<FeedingSpotProvider>();
    final spotId = int.tryParse(_spotIdController.text) ?? 1;

    final success = await provider.submitFeeding(
      spotId: spotId,
      qrToken: _qrTokenController.text.trim(),
      foodType: _foodType,
      notes: _notesController.text.trim(),
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemberian makan berhasil dicatat! +15 Poin diperoleh 🎉'),
          backgroundColor: AppConstants.successColor,
        ),
      );
      context.pop();
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Pemberian Makan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pindai QR Titik Feeding Spot Resmi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _qrTokenController,
              decoration: const InputDecoration(
                labelText: 'Token QR Spot (Hasil Scan)',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Jenis Makanan Kucing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _foodType,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.fastfood_outlined)),
              items: const [
                DropdownMenuItem(value: 'dry_food', child: Text('Dry Food (Makanan Kering)')),
                DropdownMenuItem(value: 'wet_food', child: Text('Wet Food (Makanan Basah)')),
                DropdownMenuItem(value: 'water', child: Text('Air Minum Bersih')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _foodType = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Lapangan (Opsional)',
                hintText: 'Misal: Mangkok sudah dicuci bersih terlebih dahulu.',
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Kirim & Dapatkan 15 Poin',
              isLoading: provider.isLoading,
              onPressed: _onSubmit,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}
