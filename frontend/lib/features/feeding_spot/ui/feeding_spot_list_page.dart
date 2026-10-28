import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/feeding_spot_provider.dart';

class FeedingSpotListPage extends StatefulWidget {
  const FeedingSpotListPage({super.key});

  @override
  State<FeedingSpotListPage> createState() => _FeedingSpotListPageState();
}

class _FeedingSpotListPageState extends State<FeedingSpotListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedingSpotProvider>().fetchSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopt Feeding Spot (Acumalaka)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchSpots(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator(message: 'Memuat titik feeding spot...')
          : provider.errorMessage != null
              ? ErrorView(
                  message: provider.errorMessage!,
                  onRetry: () => provider.fetchSpots(),
                )
              : provider.spots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.dinner_dining, size: 70, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('Belum ada titik feeding spot terdaftar'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.push('/feeding/record'),
                            child: const Text('Beri Makan & Scan QR'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.spots.length,
                      itemBuilder: (context, index) {
                        final spot = provider.spots[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConstants.primaryLight,
                              child: const Icon(Icons.location_on, color: AppConstants.primaryColor),
                            ),
                            title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${spot.locationName} • Mangkok: ${spot.bowlCondition}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => context.push('/feeding/record?spot_id=${spot.id}&code=${spot.code}&token=${spot.qrToken}'),
                              child: const Text('Beri Makan'),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan QR Spot', style: TextStyle(color: Colors.white)),
        onPressed: () => context.push('/feeding/record'),
      ),
    );
  }
}
