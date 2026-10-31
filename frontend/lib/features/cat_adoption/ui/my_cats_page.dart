import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/adoption_provider.dart';

class MyCatsPage extends StatefulWidget {
  const MyCatsPage({super.key});

  @override
  State<MyCatsPage> createState() => _MyCatsPageState();
}

class _MyCatsPageState extends State<MyCatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchMyCats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adoption = context.watch<AdoptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kucing Saya (Post-Adoption)')),
      body: adoption.isLoading
          ? const LoadingIndicator(message: 'Memuat data adopsi Anda...')
          : adoption.errorMessage != null
          ? ErrorView(
              message: adoption.errorMessage!,
              onRetry: () => adoption.fetchMyCats(),
            )
          : adoption.myCats.isEmpty
          ? const Center(
              child: Text('Anda belum memiliki kucing yang diadopsi.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adoption.myCats.length,
              itemBuilder: (context, index) {
                final app = adoption.myCats[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppConstants.primaryLight,
                      child: Icon(
                        Icons.favorite,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    title: Text(app.cat?.name ?? 'Kucing #${app.catId}'),
                    subtitle: Text('Status Adopsi: ${app.status}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur laporan 2-mingguan siap dikembangkan!',
                            ),
                          ),
                        );
                      },
                      child: const Text('Lapor Kondisi'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
