import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/cat_hunter_provider.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatHunterProvider>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hunter = context.watch<CatHunterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Papan Peringkat Pemburu Kucing')),
      body: hunter.isLoading
          ? const LoadingIndicator(message: 'Memuat peringkat...')
          : hunter.errorMessage != null
          ? ErrorView(
              message: hunter.errorMessage!,
              onRetry: () => hunter.fetchLeaderboard(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hunter.leaderboard.length,
              itemBuilder: (context, index) {
                final item = hunter.leaderboard[index];
                final rank = index + 1;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3
                          ? AppConstants.primaryColor
                          : Colors.grey.shade200,
                      foregroundColor: rank <= 3
                          ? Colors.white
                          : Colors.black87,
                      child: Text(
                        '#$rank',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${item.pointsBalance} Pts',
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
