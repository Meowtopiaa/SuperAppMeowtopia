import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/cat_hunter_provider.dart';

class CatDexPage extends StatefulWidget {
  const CatDexPage({super.key});

  @override
  State<CatDexPage> createState() => _CatDexPageState();
}

class _CatDexPageState extends State<CatDexPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatHunterProvider>().fetchMyDex();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hunter = context.watch<CatHunterProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telcat - Koleksi Cat Dex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Papan Peringkat',
            onPressed: () => context.push('/hunter/leaderboard'),
          ),
        ],
      ),
      body: hunter.isLoading
          ? const LoadingIndicator(message: 'Membuka Cat Dex...')
          : hunter.errorMessage != null
              ? ErrorView(
                  message: hunter.errorMessage!,
                  onRetry: () => hunter.fetchMyDex(),
                )
              : hunter.dexList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pets, size: 70, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Belum ada kucing yang tertangkap di Cat Dex kamu.'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Pindai Kalung Kucing'),
                            onPressed: () => context.push('/hunter/encounter'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: hunter.dexList.length,
                      itemBuilder: (context, index) {
                        final item = hunter.dexList[index];
                        final cat = item.cat;
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () {
                              if (cat != null) {
                                context.push('/cats/${cat.id}');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: AppConstants.primaryLight,
                                    child: const Icon(Icons.pets, size: 36, color: AppConstants.primaryColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    cat?.name ?? 'Kucing #${item.catId}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Level ${item.friendshipLevel} • ${item.encountersCount}x temu',
                                    style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.catching_pokemon, color: Colors.white),
        label: const Text('Mulai Encounter', style: TextStyle(color: Colors.white)),
        onPressed: () => context.push('/hunter/encounter'),
      ),
    );
  }
}
