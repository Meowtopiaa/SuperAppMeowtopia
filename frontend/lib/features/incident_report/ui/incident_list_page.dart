import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/incident_provider.dart';

class IncidentListPage extends StatefulWidget {
  const IncidentListPage({super.key});

  @override
  State<IncidentListPage> createState() => _IncidentListPageState();
}

class _IncidentListPageState extends State<IncidentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentProvider>().fetchIncidents();
    });
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'critical':
      case 'high':
        return AppConstants.dangerColor;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = context.watch<IncidentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapor Insiden Darurat (Optimind)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => incident.fetchIncidents(),
          ),
        ],
      ),
      body: incident.isLoading
          ? const LoadingIndicator(message: 'Memuat laporan insiden...')
          : incident.errorMessage != null
          ? ErrorView(
              message: incident.errorMessage!,
              onRetry: () => incident.fetchIncidents(),
            )
          : incident.incidents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.healing_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada insiden darurat aktif saat ini. Kampus aman!',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.dangerColor,
                    ),
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('Buat Laporan Baru'),
                    onPressed: () => context.push('/incidents/create'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: MeowPage.scrollPadding(context, top: 16, bottom: 16),
              itemCount: incident.incidents.length,
              itemBuilder: (context, index) {
                final item = incident.incidents[index];
                final urgencyColor = _getUrgencyColor(item.urgencyLevel);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: urgencyColor.withValues(alpha: 0.15),
                      child: Icon(Icons.emergency, color: urgencyColor),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${item.incidentType.toUpperCase()} • Status: ${item.status}\n${item.locationNote ?? ''}',
                    ),
                    isThreeLine: item.locationNote != null,
                    trailing: Chip(
                      label: Text(
                        item.urgencyLevel.toUpperCase(),
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: urgencyColor.withValues(alpha: 0.1),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.dangerColor,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text(
          'Lapor Insiden',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () => context.push('/incidents/create'),
      ),
    );
  }
}
