import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/adoption_provider.dart';

class AdoptionCatalogPage extends StatefulWidget {
  const AdoptionCatalogPage({super.key});

  @override
  State<AdoptionCatalogPage> createState() => _AdoptionCatalogPageState();
}

class _AdoptionCatalogPageState extends State<AdoptionCatalogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchReadyCats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adoption = context.watch<AdoptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopsi Kucing (E-Nigma)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Kucing Saya',
            onPressed: () => context.push('/adoption/my-cats'),
          ),
        ],
      ),
      body: adoption.isLoading
          ? const LoadingIndicator(message: 'Memuat katalog adopsi...')
          : adoption.errorMessage != null
              ? ErrorView(
                  message: adoption.errorMessage!,
                  onRetry: () => adoption.fetchReadyCats(),
                )
              : adoption.readyCats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pets, size: 70, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Belum ada kucing yang siap diadopsi saat ini.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.push('/adoption/my-cats'),
                            child: const Text('Lihat Riwayat & Kucing Saya'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: adoption.readyCats.length,
                      itemBuilder: (context, index) {
                        final cat = adoption.readyCats[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppConstants.primaryLight,
                                  child: const Icon(Icons.pets, color: AppConstants.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text('${cat.breed} • ${cat.gender == 'male' ? 'Jantan' : 'Betina'}'),
                                      Text(
                                        cat.sterilizationStatus ? 'Sudah Steril ✓' : 'Belum Steril',
                                        style: TextStyle(
                                          color: cat.sterilizationStatus ? AppConstants.successColor : AppConstants.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => context.push('/adoption/apply?cat_id=${cat.id}&name=${cat.name}'),
                                  child: const Text('Adopsi'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
