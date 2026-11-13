import 'package:flutter_test/flutter_test.dart';

import 'package:meowtopia/features/cat_adoption/data/adoption_constants.dart';
import 'package:meowtopia/features/cat_adoption/data/adoption_enums.dart';
import 'package:meowtopia/features/cat_adoption/data/mock_adoption_repository.dart';
import 'package:meowtopia/features/cat_adoption/logic/adoption_provider.dart';

void main() {
  group('MockAdoptionRepository Unit Tests (PRD §5.4, §7.4, ADP-01..15)', () {
    late MockAdoptionRepository repo;

    setUp(() {
      repo = MockAdoptionRepository();
    });

    test('ADP-05: getReadyCats mengembalikan daftar kucing berstatus READY',
        () async {
      final cats = await repo.getReadyCats();
      expect(cats, isNotEmpty);
      for (final cat in cats) {
        expect(cat.adoptionStatus, equals('ready'));
      }
    });

    test('ADP-01: submitApplication melempar NOT_STUDENT jika user bukan mahasiswa',
        () async {
      expect(
        () => repo.submitApplication(
          catId: 101,
          catName: 'Miko Selasar',
          applicantName: 'Dr. Dosen',
          applicantEmail: 'dosen@kampus.ac.id',
          applicantUserType: 'dosen', // Dosen dilarang mengadopsi (ADP-01)
          housingType: 'rumah_pribadi',
          financialReadiness: true,
          familyPermission: true,
          longTermPlan: 'Dirawat di rumah',
          homePhotoPath: 'mock://photo.jpg',
          commitmentAccepted: true,
        ),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('NOT_STUDENT'))),
      );
    });

    test('ADP-02: saveDraft dapat disimpan tanpa memilih kucing (catId null)',
        () async {
      final draft = await repo.saveDraft(
        catId: null,
        catName: null,
        applicantName: 'M. Helmi Afriza',
        applicantEmail: 'helmi@student.ac.id',
        applicantUserType: 'mahasiswa',
        housingType: 'kos',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Masih cari kucing yang pas',
        homePhotoPath: null,
        commitmentAccepted: false,
      );

      expect(draft.id, isPositive);
      expect(draft.catId, isNull);
      expect(draft.status, equals(ApplicationStatus.DRAFT));
      expect(draft.isDraft, isTrue);
    });

    test(
        'ADP-03: precheckPassed bernilai true jika finansial, izin, dan foto terpenuhi',
        () async {
      final submitted = await repo.submitApplication(
        catId: 101,
        catName: 'Miko Selasar',
        applicantName: 'M. Helmi Afriza',
        applicantEmail: 'helmi@student.ac.id',
        applicantUserType: 'mahasiswa',
        housingType: 'kos',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Tinggal di kos kucing-friendly',
        homePhotoPath: 'mock://camera/room.jpg',
        commitmentAccepted: true,
      );

      expect(submitted.status, equals(ApplicationStatus.SUBMITTED));
      expect(submitted.precheckPassed, isTrue);
    });

    test(
        'ADP-04: resubmitApplication berhasil mengubah status REVISION_REQUESTED -> SUBMITTED',
        () async {
      // ID 201 di mock repository memiliki status REVISION_REQUESTED
      final resubmitted = await repo.resubmitApplication(
        applicationId: 201,
        housingType: 'kos',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Lampiran surat izin pemilik kos sudah lengkap.',
        homePhotoPath: 'mock://camera/new_room.jpg',
        commitmentAccepted: true,
      );

      expect(resubmitted.id, equals(201));
      expect(resubmitted.status, equals(ApplicationStatus.SUBMITTED));
      expect(resubmitted.adminNotes, isNull);
    });

    test('ADP-06 & ADP-07: completePickup menghasilkan adopsi ACTIVE',
        () async {
      // 103 adalah Boni Kantin Barat, token: MTP1.C.BONI103
      final active = await repo.completePickup(
        applicationId: 203,
        catId: 103,
        scannedQrToken: 'MTP1.C.BONI103',
        collarPhotoPath: 'mock://collar.jpg',
        confirmedResponsibility: true,
      );

      expect(active.status, equals(ActiveAdoptionStatus.ACTIVE));
      expect(active.isActive, isTrue);
      expect(active.catId, equals(103));
    });

    test('ADP-06: completePickup gagal jika scanned QR token tidak cocok',
        () async {
      expect(
        () => repo.completePickup(
          applicationId: 203,
          catId: 103,
          scannedQrToken: 'MTP1.C.SALAH_TOKEN',
          collarPhotoPath: 'mock://collar.jpg',
          confirmedResponsibility: true,
        ),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('QR_WRONG_CAT'))),
      );
    });

    test('ADP-08: getMyActiveAdoptions hanya mengembalikan adopsi berstatus ACTIVE',
        () async {
      final adoptions = await repo.getMyActiveAdoptions();
      expect(adoptions, isNotEmpty);
      for (final a in adoptions) {
        expect(a.status, equals(ActiveAdoptionStatus.ACTIVE));
      }
    });

    test('ADP-09 & ADP-10: submitFollowup berhasil mencatat laporan berkala',
        () async {
      final followup = await repo.submitFollowup(
        adoptionId: 501,
        cycleNumber: 3,
        photoPath: 'mock://camera/flw3.jpg',
        condition: 'Sangat Sehat & Ceria',
        notes: 'Nafsu makan bertambah.',
      );

      expect(followup.adoptionId, equals(501));
      expect(followup.cycleNumber, equals(3));
      expect(followup.condition, equals('Sangat Sehat & Ceria'));
    });

    test(
        'ADP-11 & OQ-08: requestReturn melempar RETURN_DISABLED jika return_enabled = false',
        () async {
      if (!kAdoptionReturnEnabled) {
        expect(
          () => repo.requestReturn(
            adoptionId: 501,
            reasonType: ReturnReasonType.EMERGENCY,
            reason: 'Pindah kota mendadak',
          ),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('RETURN_DISABLED'))),
        );
      }
    });

    test(
        'ADP-13: reportIssue mencatat laporan kendala tanpa mewajibkan foto dan tidak menutup adopsi',
        () async {
      final report = await repo.reportIssue(
        adoptionId: 501,
        catId: 105,
        category: AdoptionIssueCategory.SICK,
        description: 'Kucing batuk pilek sejak pagi hari.',
        photoPath: null, // Foto TIDAK wajib (ADP-13)
      );

      expect(report.category, equals(AdoptionIssueCategory.SICK));
      expect(report.photoPath, isNull);
      expect(report.handled, isFalse);

      // Pastikan adopsi aktif tetap berstatus ACTIVE (tidak menutup adopsi otomatis)
      final adoptions = await repo.getMyActiveAdoptions();
      final active = adoptions.firstWhere((a) => a.id == 501);
      expect(active.status, equals(ActiveAdoptionStatus.ACTIVE));
    });

    test('State Gagal: simulateNetworkError melempar exception saat jaringan putus',
        () async {
      repo.simulateNetworkError = true;
      expect(
        () => repo.getReadyCats(),
        throwsA(predicate((e) =>
            e is Exception && e.toString().contains('Gagal menghubungi server'))),
      );
    });
  });

  group('AdoptionProvider State Management Tests', () {
    late AdoptionProvider provider;

    setUp(() {
      provider = AdoptionProvider();
    });

    test('Provider memuat data awal dengan sukses', () async {
      await provider.fetchInitialData();
      expect(provider.readyCats, isNotEmpty);
      expect(provider.myApplications, isNotEmpty);
      expect(provider.myActiveAdoptions, isNotEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('setUserType mengubah status isStudent dengan reaktif', () {
      expect(provider.isStudent, isTrue);

      provider.setUserType('dosen');
      expect(provider.isStudent, isFalse);
      expect(provider.userType, equals('dosen'));

      provider.setUserType('mahasiswa');
      expect(provider.isStudent, isTrue);
    });

    test('State Gagal: submitApplication dosen menyimpan errorMessage di Provider',
        () async {
      provider.setUserType('dosen');

      final result = await provider.submitApplication(
        catId: 101,
        catName: 'Miko Selasar',
        housingType: 'rumah_pribadi',
        financialReadiness: true,
        familyPermission: true,
        longTermPlan: 'Dirawat keluarga',
        homePhotoPath: 'mock://photo.jpg',
        commitmentAccepted: true,
      );

      expect(result, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('NOT_STUDENT'));
    });
  });
}

