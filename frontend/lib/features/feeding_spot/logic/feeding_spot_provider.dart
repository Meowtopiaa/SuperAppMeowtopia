import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../data/demo_feeding_data.dart';
import '../data/feeding_session.dart';
import '../data/feeding_spot_model.dart';
import '../data/feeding_spot_service.dart';

class FeedingSpotProvider extends ChangeNotifier {
  FeedingSpotProvider({
    this.isDemo = AppConstants.demoMode,
    FeedingSpotService? service,
  }) : _service = service ?? FeedingSpotService() {
    if (isDemo) {
      _spots = demoFeedingSpots(DateTime.now());
      _history.addAll(demoFeedingHistory(_spots, DateTime.now()));
      _loaded = true;
    }
  }
  final bool isDemo;
  final FeedingSpotService _service;
  List<FeedingSpotModel> _spots = [];
  final List<FeedingSubmission> _history = [];
  final Set<String> _favorites = {};
  final Map<String, DateTime> _lastSubmitted = {};
  FeedingSession? session;
  bool _isLoading = false;
  bool _loaded = false;
  String? _errorMessage;
  List<FeedingSpotModel> get spots => List.unmodifiable(
    _spots.where((s) => s.status.toLowerCase() != 'inactive'),
  );
  List<FeedingSubmission> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingCount =>
      _history.where((s) => s.status == FeedingStatus.underReview).length;
  int get creditedPoints =>
      _history.fold(0, (sum, s) => sum + s.creditedPoints);
  bool isFavorite(String id) => _favorites.contains(id);
  void toggleFavorite(String id) {
    if (!_favorites.add(id)) _favorites.remove(id);
    notifyListeners();
  }

  FeedingSpotModel? spotById(String id) {
    for (final spot in spots) {
      if (spot.id == id || spot.code == id) return spot;
    }
    return null;
  }

  FeedingSubmission? submissionById(String id) {
    for (final item in history) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> fetchSpots({bool refresh = false}) async {
    if (_isLoading || (_loaded && !refresh)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (!isDemo) _spots = await _service.getSpots();
      _loaded = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FeedingSession> openSession(
    String rawToken, {
    String? expectedSpotId,
  }) async {
    final token = rawToken.trim();
    if (token.isEmpty) throw StateError('Masukkan token QR spot yang valid.');
    await fetchSpots();
    FeedingSpotModel? match;
    for (final spot in spots) {
      if (spot.qrToken == token ||
          'SPOT:${spot.code}' == token ||
          'MTP1.S.${spot.code}' == token ||
          spot.code == token) {
        match = spot;
      }
    }
    if (match == null) {
      throw StateError(
        'QR tidak dikenali sebagai QR spot. Gunakan QR resmi di lokasi.',
      );
    }
    if (expectedSpotId != null &&
        expectedSpotId.isNotEmpty &&
        match.id != expectedSpotId &&
        match.code != expectedSpotId) {
      throw StateError(
        'QR ini milik spot lain. Pindai QR di spot yang dipilih.',
      );
    }
    if (!match.isActive) {
      throw StateError(
        'Spot ini sedang tidak tersedia. Pilih spot aktif lainnya.',
      );
    }
    final last = _lastSubmitted[match.id];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(hours: 6)) {
      throw StateError(
        'Kegiatan di spot ini sudah diajukan. Tunggu 6 jam untuk kegiatan berikutnya.',
      );
    }
    if (!isDemo) {
      throw StateError(
        'Layanan sesi dan verifikasi bukti belum tersedia. Coba lagi setelah integrasi backend siap.',
      );
    }
    final now = DateTime.now();
    session = FeedingSession(
      id: 'LOKAL-${now.microsecondsSinceEpoch}',
      spot: match,
      startedAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );
    notifyListeners();
    return session!;
  }

  Future<void> addExampleEvidence({int? replaceIndex}) async {
    if (!isDemo) {
      throw StateError('Foto contoh hanya tersedia dalam mode pratinjau.');
    }
    final data = await rootBundle.load('assets/images/figma/feeding-proof.png');
    addEvidence(
      FeedingEvidence(
        bytes: data.buffer.asUint8List(),
        capturedAt: DateTime.now(),
        isExample: true,
      ),
      replaceIndex: replaceIndex,
    );
  }

  void addEvidence(FeedingEvidence photo, {int? replaceIndex}) {
    final current = session;
    if (current == null || current.isExpired) {
      throw StateError('Sesi berakhir. Pindai ulang QR spot.');
    }
    if (photo.bytes.isEmpty || photo.bytes.length > 10 * 1024 * 1024) {
      throw StateError('Foto tidak valid atau lebih besar dari 10 MB.');
    }
    if (replaceIndex != null &&
        replaceIndex >= 0 &&
        replaceIndex < current.evidence.length) {
      current.evidence[replaceIndex] = photo;
    } else {
      if (current.evidence.length >= 3) {
        throw StateError('Maksimal tiga foto per pengajuan.');
      }
      current.evidence.add(photo);
    }
    notifyListeners();
  }

  void removeEvidence(int index) {
    session?.evidence.removeAt(index);
    notifyListeners();
  }

  Future<FeedingSubmission> submitSession() async {
    final current = session;
    if (current == null) throw StateError('Pindai QR spot terlebih dahulu.');
    for (final item in _history) {
      if (item.id == current.id) return item;
    }
    if (!current.canSubmit) {
      throw StateError(
        'Sesi harus aktif dan minimal satu foto wajib tersedia.',
      );
    }
    if (!isDemo) throw StateError('Layanan pengiriman bukti belum tersedia.');
    final now = DateTime.now();
    final item = FeedingSubmission(
      id: current.id,
      spot: current.spot,
      createdAt: now,
      status: FeedingStatus.underReview,
      foodType: current.foodType,
      quantity: current.quantity,
      evidence: List.unmodifiable(current.evidence),
      notes: current.notes.trim(),
    );
    _history.insert(0, item);
    _lastSubmitted[current.spot.id] = now;
    notifyListeners();
    return item;
  }
}
