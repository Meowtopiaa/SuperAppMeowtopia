enum QrKind { cat, spot, unknown }

class QrPayload {
  final QrKind kind;
  final String value;
  const QrPayload(this.kind, this.value);
}

QrPayload parseQr(String raw) {
  final p = raw.trim().split('.');
  if (p.length == 3 && p[0] == 'MTP1') {
    if (p[1] == 'C') return QrPayload(QrKind.cat, p[2]);
    if (p[1] == 'S') return QrPayload(QrKind.spot, p[2]);
  }
  return QrPayload(QrKind.unknown, raw.trim()); // Fallback input manual
}

