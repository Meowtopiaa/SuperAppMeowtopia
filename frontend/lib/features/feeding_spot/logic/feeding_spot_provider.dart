import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../data/demo_feeding_data.dart';
import '../data/feeding_session.dart';
import '../data/feeding_spot_model.dart';
import '../data/feeding_spot_service.dart';
import '../feeding_spot_actions.dart';

class FeedingSpotProvider extends ChangeNotifier {
  FeedingSpotProvider({
    this.isDemo = AppConstants.demoMode,
    FeedingSpotService? service,
  }) : _service = service ?? FeedingSpotService() {
    registerFeedingSpotActions();
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
  bool _sortedByDistance = false;
  String? _errorMessage;

  List<FeedingSpotModel> get spots => List.unmodifiable(
    _spots.where((s) => s.status.toLowerCase() != 'inactive'),
  );
  List<FeedingSubmission> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get sortedByDistance => _sortedByDistance;
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

  /// Fetch spots and sort client-side by nearest GPS location (or alphabetically if permission denied per AFS-02 & IT-14).
  Future<void> fetchSpots({bool refresh = false}) async {
    if (_isLoading || (_loaded && !refresh)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (!isDemo) {
        _spots = await _service.getSpots();
        try {
          final remoteHistory = await _service.getMyActivities();
          _history
            ..clear()
            ..addAll(remoteHistory);
        } catch (_) {
          // Non-blocking if user is not logged in or history fetch fails
        }
      }
      await _sortSpotsClientSide();
      _loaded = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch current user's feeding activities from GET /api/v1/feeding/activities/mine.
  Future<void> fetchMyActivities() async {
    if (isDemo) return;
    try {
      final remoteHistory = await _service.getMyActivities();
      _history
        ..clear()
        ..addAll(remoteHistory);
      notifyListeners();
    } catch (_) {
      // Non-blocking if user is unauthenticated
    }
  }

  /// AFS-02 & Hard Rule #8: GPS is used strictly on the device to sort nearest spots and is never sent to the server.
  /// If location permission is denied or unavailable, spots remain visible and are sorted alphabetically by name (IT-14).
  Future<void> _sortSpotsClientSide() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _sortAlphabetically();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _sortAlphabetically();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      _spots = _spots
          .map(
            (s) => s.copyWith(
              distanceMeters: Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                s.latitude,
                s.longitude,
              ),
            ),
          )
          .toList()
        ..sort(
          (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
            b.distanceMeters ?? double.infinity,
          ),
        );
      _sortedByDistance = true;
    } catch (_) {
      _sortAlphabetically();
    }
  }

  void _sortAlphabetically() {
    _sortedByDistance = false;
    _spots.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<FeedingSession> openSession(
    String rawToken, {
    String? expectedSpotId,
  }) async {
    final token = rawToken.trim();
    if (token.isEmpty) throw StateError('Masukkan token QR spot yang valid.');
    await fetchSpots();

    if (!isDemo) {
      final sessionData = await _service.startSession(token);
      final activityId = sessionData['activity_id'].toString();
      final spotJson = Map<String, dynamic>.from(sessionData['spot'] as Map);
      final spot = FeedingSpotModel.fromJson(spotJson);

      if (expectedSpotId != null &&
          expectedSpotId.isNotEmpty &&
          spot.id != expectedSpotId &&
          spot.code != expectedSpotId) {
        throw StateError(
          'QR ini milik spot lain. Pindai QR di spot yang dipilih.',
        );
      }

      // Immediately confirm intent on server (AFS-04)
      await _service.confirmIntent(activityId);

      final startedAt = DateTime.tryParse(
            sessionData['scanned_at']?.toString() ?? '',
          ) ??
          DateTime.now();
      final expiresAt = DateTime.tryParse(
            sessionData['finalize_deadline_at']?.toString() ?? '',
          ) ??
          startedAt.add(const Duration(minutes: 60));
      final intentDeadlineAt = DateTime.tryParse(
        sessionData['intent_deadline_at']?.toString() ?? '',
      );

      session = FeedingSession(
        id: activityId,
        spot: spot,
        startedAt: startedAt,
        expiresAt: expiresAt,
        intentDeadlineAt: intentDeadlineAt,
      );
      notifyListeners();
      return session!;
    }

    // Demo Mode Fallback
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
        match.id != expectedSpotId) {
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
      id: 'LOKAL-${now.microsecondsSinceEpoch}',
      spot: match,
      startedAt: now,
      expiresAt: now.add(const Duration(minutes: 60)),
      intentDeadlineAt: now.add(const Duration(minutes: 15)),
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

    final now = DateTime.now();

    if (!isDemo) {
      // 1. Upload each photo to POST /api/v1/media (purpose: feeding_proof)
      final mediaIds = <String>[];
      for (var i = 0; i < current.evidence.length; i++) {
        final ev = current.evidence[i];
        if (ev.mediaId != null && ev.mediaId!.isNotEmpty) {
          mediaIds.add(ev.mediaId!);
        } else {
          final uploadedId = await _service.uploadEvidencePhoto(ev.bytes, i);
          mediaIds.add(uploadedId);
        }
      }

      // 2. Finalize session at POST /api/v1/feeding/activities/{id}/finalize
      final finalizeData = await _service.finalizeSession(
        activityId: current.id,
        mediaIds: mediaIds,
        foodType: current.foodType,
        foodAmount: current.quantity,
        catCode: current.catCode,
        notes: current.notes.trim(),
      );

      final submission = FeedingSubmission.fromJson(
        finalizeData,
        fallbackSpot: current.spot,
      );

      final enriched = FeedingSubmission(
        id: submission.id,
        spot: current.spot,
        createdAt: submission.createdAt,
        status: submission.status,
        rewardStatus: submission.rewardStatus,
        rewardCapped: submission.rewardCapped,
        foodType: current.foodType,
        quantity: current.quantity,
        evidence: List.unmodifiable(current.evidence),
        notes: current.notes.trim(),
        potentialPoints: submission.potentialPoints,
        creditedPoints: submission.creditedPoints,
      );

      _history.insert(0, enriched);
      _lastSubmitted[current.spot.id] = now;
      await fetchSpots(refresh: true);
      notifyListeners();
      return enriched;
    }

    // Demo Mode Submission
    final item = FeedingSubmission(
      id: current.id,
      spot: current.spot,
      createdAt: now,
      status: FeedingStatus.underReview,
      rewardStatus: 'PENDING',
      foodType: current.foodType,
      quantity: current.quantity,
      evidence: List.unmodifiable(current.evidence),
      notes: current.notes.trim(),
      potentialPoints: 10,
    );
    _history.insert(0, item);
    _lastSubmitted[current.spot.id] = now;
    notifyListeners();
    return item;
  }
}
