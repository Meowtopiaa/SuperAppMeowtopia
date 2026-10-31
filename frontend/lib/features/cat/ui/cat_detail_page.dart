import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/cat_provider.dart';

class CatDetailPage extends StatefulWidget {
  final int catId;

  const CatDetailPage({super.key, required this.catId});

  @override
  State<CatDetailPage> createState() => _CatDetailPageState();
}

class _CatDetailPageState extends State<CatDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatProvider>().fetchCatDetail(widget.catId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CatProvider>();

    if (catProvider.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat profil kucing...'),
      );
    }

    if (catProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: catProvider.errorMessage!,
          onRetry: () => catProvider.fetchCatDetail(widget.catId),
        ),
      );
    }

    final cat = catProvider.selectedCat;
    if (cat == null) {
      return const Scaffold(
        body: Center(child: Text('Kucing tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(cat.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppConstants.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  image: cat.primaryPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(cat.primaryPhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: cat.primaryPhotoUrl == null
                    ? const Icon(
                        Icons.pets,
                        size: 80,
                        color: AppConstants.primaryColor,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              cat.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(cat.breed)),
                Chip(
                  label: Text(cat.gender == 'male' ? 'Jantan ♂' : 'Betina ♀'),
                ),
                Chip(label: Text('Kondisi: ${cat.healthStatus}')),
                if (cat.sterilizationStatus)
                  const Chip(
                    label: Text('Sudah Steril ✓'),
                    backgroundColor: Color(0xFFD1FAE5),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi Kucing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              cat.description ?? 'Belum ada deskripsi khusus untuk kucing ini.',
              style: const TextStyle(
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.qr_code,
                  color: AppConstants.primaryColor,
                ),
                title: const Text('Token QR Kalung'),
                subtitle: Text(cat.qrCodeToken),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
