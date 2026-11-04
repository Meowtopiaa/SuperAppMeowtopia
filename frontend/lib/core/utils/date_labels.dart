String relativeTime(DateTime? date) {
  if (date == null) return 'Belum ada catatan';
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'Baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} mnt lalu';
  if (difference.inHours < 24) return '${difference.inHours} jam lalu';
  return '${difference.inDays} hari lalu';
}

String wibTime(DateTime date) {
  final wib = date.toUtc().add(const Duration(hours: 7));
  return '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')} WIB';
}
