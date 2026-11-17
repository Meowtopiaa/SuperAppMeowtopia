import 'package:flutter_test/flutter_test.dart';
import 'package:meowtopia/core/scanner/qr_parser.dart';
import 'package:meowtopia/features/feeding_spot/data/feeding_spot_model.dart';
import 'package:meowtopia/features/feeding_spot/logic/feeding_spot_provider.dart';

void main() {
  group('QR Parser Unit Tests (MEOW-27 & MEOW-28)', () {
    test('parseQr mengenali MTP1.S.<token> sebagai QR Spot', () {
      final res = parseQr('MTP1.S.TOKEN_SPOT_TULT_01_ABC123');
      expect(res.kind, QrKind.spot);
      expect(res.value, 'TOKEN_SPOT_TULT_01_ABC123');
    });

    test('parseQr mengenali MTP1.C.<token> sebagai QR Kucing', () {
      final res = parseQr('MTP1.C.TOKEN_CAT_01_XYZ789');
      expect(res.kind, QrKind.cat);
      expect(res.value, 'TOKEN_CAT_01_XYZ789');
    });

    test('parseQr memetakan teks lain / kode manual sebagai QrKind.unknown', () {
      final manual = parseQr('SPOT-TULT-01');
      expect(manual.kind, QrKind.unknown);
      expect(manual.value, 'SPOT-TULT-01');

      final invalid = parseQr('https://example.com');
      expect(invalid.kind, QrKind.unknown);
    });
  });

  group('Telkom University 38-Location Denah Mapping Tests (MEOW-26)', () {
    test('Memiliki tepat 38 lokasi resmi sesuai denah Telkom University', () {
      expect(TelkomCampusLocation.all.length, 38);
      expect(TelkomCampusLocation.all.first.number, 1);
      expect(
        TelkomCampusLocation.all.first.name,
        'Telkom University Landmark Tower (TULT)',
      );
      expect(TelkomCampusLocation.all.last.number, 38);
      expect(TelkomCampusLocation.all.last.name, 'Jogging Track');
    });

    test('Resolusi lokasi spot sesuai denah berdasarkan kode dan koordinat', () {
      final tult = TelkomCampusLocation.resolve(
        -6.96930,
        107.62815,
        code: 'SPOT-TULT-01',
      );
      expect(tult.number, 1);
      expect(tult.name, 'Telkom University Landmark Tower (TULT)');

      final gku = TelkomCampusLocation.resolve(
        -6.97195,
        107.62955,
        code: 'SPOT-GKU-01',
      );
      expect(gku.number, 7);
      expect(gku.name, 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)');

      final msu = TelkomCampusLocation.resolve(-6.97525, 107.63165);
      expect(msu.number, 37);
      expect(msu.name, 'Masjid Syamsul Ulum');
    });

    test('FeedingSpotModel.fromJson memetakan location_name, image_url, status_reason, dan is_stale', () {
      final model = FeedingSpotModel.fromJson({
        'id': '01JAFS00000000000000000101',
        'code': 'SPOT-GKU-01',
        'name': 'Spot Pakan GKU Gazebo',
        'location_number': 7,
        'location_name': 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)',
        'latitude': -6.97195,
        'longitude': 107.62955,
        'status': 'TEMPORARILY_UNAVAILABLE',
        'status_reason': 'Pembersihan wadah pakan',
        'image_url': 'http://127.0.0.1:8000/api/v1/feeding/spots/01JAFS00000000000000000101/photo',
        'has_pending_review': true,
        'aggregate': {
          'verified_count': 5,
          'pending_count': 1,
          'is_stale': false,
        },
      });

      expect(model.code, 'SPOT-GKU-01');
      expect(model.locationNumber, 7);
      expect(model.locationName, 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)');
      expect(model.statusReason, 'Pembersihan wadah pakan');
      expect(model.imageUrl, isNotNull);
      expect(model.hasPendingReview, isTrue);
      expect(model.isStale, isFalse);
    });
  });

  group('FeedingSpotProvider QR & Manual Code Scenarios (MEOW-27 & MEOW-28)', () {
    test('Menolak QR kucing dengan pesan QR_WRONG_TYPE', () async {
      final provider = FeedingSpotProvider(isDemo: true);
      expect(
        () => provider.openSession('MTP1.C.CAT_TOKEN_123'),
        throwsA(
          predicate((e) => e.toString().contains('QR_WRONG_TYPE')),
        ),
      );
    });

    test('Membuka sesi dengan QR Spot valid maupun kode manual SPOT-TULT-01', () async {
      final provider = FeedingSpotProvider(isDemo: true);
      final session = await provider.openSession('SPOT-TULT-01');
      expect(session.spot.code, 'SPOT-TULT-01');
      expect(
        session.spot.locationName,
        'Telkom University Landmark Tower (TULT)',
      );
    });
  });
}
