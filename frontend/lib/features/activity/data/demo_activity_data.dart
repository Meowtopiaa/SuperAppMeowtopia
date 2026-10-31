import '../../../core/navigation/app_feature.dart';
import 'activity_entry.dart';

List<ActivityEntry> previewActivities(DateTime now) => [
  ActivityEntry(
    id: 'preview-identification',
    feature: AppFeature.identification,
    title: 'Mengenali Oyen',
    description: 'Identifikasi melalui QR kalung',
    status: 'Dikenali',
    createdAt: now.subtract(const Duration(minutes: 35)),
  ),
  ActivityEntry(
    id: 'preview-hunter',
    feature: AppFeature.hunter,
    title: 'Bertemu Mochi',
    description: 'Perjumpaan di area kampus',
    status: 'Masuk koleksi',
    createdAt: now.subtract(const Duration(hours: 3)),
  ),
  ActivityEntry(
    id: 'preview-adoption',
    feature: AppFeature.adoption,
    title: 'Pengajuan kelayakan adopter',
    description: 'Komitmen dan kesiapan perawatan',
    status: 'Dalam pemeriksaan',
    createdAt: now.subtract(const Duration(days: 1)),
  ),
  ActivityEntry(
    id: 'preview-incident',
    feature: AppFeature.incident,
    title: 'Laporan kucing membutuhkan bantuan',
    description: 'Area perpustakaan kampus',
    status: 'Diterima',
    createdAt: now.subtract(const Duration(days: 2)),
  ),
];
