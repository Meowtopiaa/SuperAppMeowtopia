import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
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
      _sortSpotsClientSide();
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
      if (!isDemo) {
        _spots = await _service.getSpots();
        await fetchMyActivities();
      }
      await _sortSpotsClientSide();
      _loaded = true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyActivities() async {
    if (isDemo) return;
    try {
      final spotsMap = {for (final s in _spots) s.id: s};
      final items = await _service.getMyActivities(spotsMap);
      _history
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (_) {
      // Abaikan jika pengguna belum login saat melihat daftar spot publik
    }
  }

  /// Mengurutkan spot terdekat di sisi klien (HP) tanpa mengirim atau menyimpan
  /// koordinat GPS pengguna ke server (sesuai Aturan Keras #8 & AFS-02).
  /// Jika izin lokasi tidak diberikan, otomatis fallback ke urutan alfabetis.
  Future<void> _sortSpotsClientSide() async {
    if (_spots.isEmpty) return;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _sortAlphabetically();
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _sortAlphabetically();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      _spots = _spots.map((spot) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          spot.latitude,
          spot.longitude,
        );
        return spot.copyWith(distanceMeters: distance);
      }).toList()
        ..sort(
          (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
            b.distanceMeters ?? double.infinity,
          ),
        );
      notifyListeners();
    } catch (_) {
      _sortAlphabetically();
    }
  }

  void _sortAlphabetically() {
    _spots = [..._spots]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  Future<FeedingSession> openSession(
    String rawToken, {
    String? expectedSpotId,
  }) async {
    final token = rawToken.trim();
    if (token.isEmpty) throw StateError('Masukkan token QR spot yang valid.');
    await fetchSpots();

    if (!isDemo) {
      try {
        final data = await _service.openSession(qrToken: token);
        final spotJson = data['spot'] as Map<String, dynamic>?;
        final activityId =
            (data['id'] ?? data['activity_id'])?.toString() ?? '';
        final spotId =
            (data['spot_id'] ?? spotJson?['id'])?.toString() ?? '';
        if (expectedSpotId != null &&
            expectedSpotId.isNotEmpty &&
            spotId != expectedSpotId &&
            spotJson?['code']?.toString() != expectedSpotId) {
          throw StateError(
            'QR ini milik spot lain. Pindai QR di spot yang dipilih.',
          );
        }

        await _service.confirmIntent(activityId);

        final matchedSpot =
            spotById(spotId) ??
            (spotJson != null
                ? FeedingSpotModel.fromJson(spotJson)
                : await _service.getSpotDetail(spotId));

        final now = DateTime.now();
        final startedAt = data['scanned_at'] != null
            ? DateTime.tryParse(data['scanned_at'].toString()) ?? now
            : now;
        final expiresAt = data['finalize_deadline_at'] != null
            ? DateTime.tryParse(data['finalize_deadline_at'].toString()) ??
                  now.add(const Duration(minutes: 15))
            : now.add(const Duration(minutes: 15));

        final intentDeadlineAt = data['intent_deadline_at'] != null
            ? DateTime.tryParse(data['intent_deadline_at'].toString())
            : startedAt.add(const Duration(minutes: 15));
        final finalizeDeadlineAt = data['finalize_deadline_at'] != null
            ? DateTime.tryParse(data['finalize_deadline_at'].toString())
            : null;

        session = FeedingSession(
          id: activityId,
          feedingRecordRef: data['feeding_record_ref']?.toString(),
          spot: matchedSpot,
          startedAt: startedAt,
          expiresAt: finalizeDeadlineAt ?? intentDeadlineAt ?? now.add(const Duration(minutes: 15)),
          intentDeadlineAt: intentDeadlineAt,
          finalizeDeadlineAt: finalizeDeadlineAt,
        );
        notifyListeners();
        return session!;
      } catch (e) {
        throw StateError(_extractErrorMessage(e));
      }
    }

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
    final now = DateTime.now();
    session = FeedingSession(
      id: '01JAFS00000000000000999999',
      feedingRecordRef: 'FD-${now.millisecondsSinceEpoch}',
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

    if (!isDemo) {
      try {
        final mediaIds = <String>[];
        for (var i = 0; i < current.evidence.length; i++) {
          final evidence = current.evidence[i];
          final mediaId =
              evidence.mediaId ??
              await _service.uploadEvidence(
                evidence.bytes,
                filename: 'feeding-${current.id}-${i + 1}.jpg',
              );
          mediaIds.add(mediaId);
        }

        final data = await _service.finalizeSession(
          activityId: current.id,
          mediaIds: mediaIds,
          foodType: current.foodType,
          foodAmount: current.quantity,
          notes: current.notes.trim(),
          catId: current.catId,
          catCode: current.catCode,
        );

        final submission = FeedingSubmission.fromJson(
          data,
          fallbackSpot: current.spot,
          localEvidence: List.unmodifiable(current.evidence),
        );
        _history.insert(0, submission);
        _lastSubmitted[current.spot.id] = DateTime.now();
        notifyListeners();
        return submission;
      } catch (e) {
        throw StateError(_extractErrorMessage(e));
      }
    }

    final now = DateTime.now();
    final item = FeedingSubmission(
      id: current.id,
      feedingRecordRef: current.feedingRecordRef,
      spot: current.spot,
      createdAt: now,
      status: FeedingStatus.underReview,
      rewardStatus: 'PENDING',
      foodType: current.foodType,
      quantity: current.quantity,
      evidence: List.unmodifiable(current.evidence),
      notes: current.notes.trim(),
      catId: current.catId,
      potentialPoints: 10,
    );
    _history.insert(0, item);
    _lastSubmitted[current.spot.id] = now;
    notifyListeners();
    return item;
  }

  String _extractErrorMessage(Object error) {
    if (error is ApiException) {
      switch (error.code) {
        case 'COOLDOWN_ACTIVE':
          return 'Spot ini baru saja diberi makan dalam 6 jam terakhir. Silakan pilih spot lain yang membutuhkan pakan.';
        case 'SESSION_EXPIRED':
          return 'Sesi pemberian makan telah kedaluwarsa. Silakan pindai ulang QR di spot.';
        case 'QR_WRONG_TYPE':
          return 'Kode QR tidak sesuai. Pastikan Anda memindai kode QR resmi titik pakan (MTP1.S.*).';
        case 'SPOT_UNAVAILABLE':
        case 'SPOT_NOT_FOUND':
          return 'Spot pakan ini sedang dalam perawatan atau sementara tidak tersedia.';
        case 'DAILY_CAP_REACHED':
          return 'Batas reward harian Anda telah tercapai. Anda tetap dapat memberi makan, namun poin tidak bertambah hari ini.';
        case 'IDEMPOTENCY_CONFLICT':
          return 'Permintaan sedang diproses atau sudah tercatat sebelumnya. Muat ulang halaman.';
        default:
          return error.message;
      }
    }
    final raw = error.toString();
    return raw.replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '');
  }
}
