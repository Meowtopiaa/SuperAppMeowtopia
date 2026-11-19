import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meowtopia/core/network/api_exception.dart';
import 'package:meowtopia/features/cat_adoption/data/adoption_catalog_model.dart';
import 'package:meowtopia/features/cat_adoption/data/adoption_catalog_repository.dart';
import 'package:meowtopia/features/cat_adoption/data/mock_adoption_repository.dart';
import 'package:meowtopia/features/cat_adoption/logic/adoption_provider.dart';

/// EN-12: katalog kucing READY tanpa data pribadi.
void main() {
  Response jsonResponse(Map<String, dynamic> body, {int status = 200}) =>
      Response(
        requestOptions: RequestOptions(path: '/adoption/cats'),
        statusCode: status,
        data: body,
      );

  group('AdoptionCatalogCat.fromJson', () {
    test('membaca field publik dan mengabaikan field lain', () {
      final cat = AdoptionCatalogCat.fromJson({
        'id': '01JD7Q8Z5X6Y7Z8A9B0C1D2E3F',
        'name': 'Luna',
        'gender': 'FEMALE',
        'age_group': 'KITTEN',
        'color_pattern': 'Calico',
        'is_sterilized': true,
        'description': 'Tenang.',
        'primary_photo_media_id': '01JD7Q8Z5X6Y7Z8A9B0C1D2E3G',
        'adoption_status': 'READY',
        // Field yang tidak boleh dipakai walaupun ikut terkirim.
        'unique_code': 'LUNA-01',
        'last_seen_lat': -6.97,
      });

      expect(cat.id, '01JD7Q8Z5X6Y7Z8A9B0C1D2E3F');
      expect(cat.genderLabel, 'Betina');
      expect(cat.ageLabel, 'Anak kucing');
      expect(cat.colorPattern, 'Calico');
      expect(cat.isSterilized, isTrue);
      expect(cat.primaryPhotoMediaId, '01JD7Q8Z5X6Y7Z8A9B0C1D2E3G');
      expect(cat.photoUrl, isNull);
    });

    test('nilai kosong tidak dianggap fakta', () {
      final cat =
          AdoptionCatalogCat.fromJson({'id': 'X', 'name': ' ', 'gender': null});
      expect(cat.name, 'Tanpa nama');
      expect(cat.gender, 'UNKNOWN');
      expect(cat.ageLabel, isNull);
      expect(cat.isSterilized, isNull);
      expect(cat.description, isNull);
    });
  });

  group('AdoptionCatalogFilter', () {
    const male = AdoptionCatalogCat(
        id: '1', name: 'A', gender: 'MALE', ageGroup: 'KITTEN');
    const female = AdoptionCatalogCat(
        id: '2', name: 'B', gender: 'FEMALE', ageGroup: 'ADULT');

    test('filter kosong meloloskan semua', () {
      const filter = AdoptionCatalogFilter();
      expect(filter.isEmpty, isTrue);
      expect([male, female].where(filter.matches), hasLength(2));
    });

    test('filter jenis kelamin dan umur bisa digabung', () {
      expect(const AdoptionCatalogFilter(gender: 'MALE').matches(male), isTrue);
      expect(
          const AdoptionCatalogFilter(gender: 'MALE').matches(female), isFalse);
      expect(
        const AdoptionCatalogFilter(gender: 'FEMALE', ageGroup: 'ADULT')
            .matches(female),
        isTrue,
      );
      expect(
        const AdoptionCatalogFilter(gender: 'FEMALE', ageGroup: 'KITTEN')
            .matches(female),
        isFalse,
      );
    });
  });

  group('ApiAdoptionCatalogRepository', () {
    test(
        'memanggil /adoption/cats tanpa parameter tambahan dan membaca semua halaman',
        () async {
      final calls = <Map<String, dynamic>>[];
      final repo = ApiAdoptionCatalogRepository(
        get: (path, {queryParameters}) async {
          expect(path, '/adoption/cats');
          calls.add(queryParameters!);
          final page = queryParameters['page'] as int;
          return jsonResponse({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'cat-$page',
                'name': 'Kucing $page',
                'adoption_status': 'READY'
              },
            ],
            'meta': {'has_more': page < 2},
          });
        },
      );

      final cats = await repo.getCatalog();

      expect(cats.map((c) => c.id), ['cat-1', 'cat-2']);
      expect(calls, hasLength(2));
      // Hanya parameter yang ada di kontrak PRD 8.1: page dan per_page.
      expect(calls.first.keys.toSet(), {'page', 'per_page'});
    });

    test('meneruskan pesan error server (misalnya NOT_STUDENT)', () async {
      final repo = ApiAdoptionCatalogRepository(
        get: (path, {queryParameters}) async => throw DioException(
          requestOptions: RequestOptions(path: path),
          error: ApiException(
            message: 'Fitur adopsi hanya untuk mahasiswa.',
            statusCode: 403,
            code: 'NOT_STUDENT',
          ),
        ),
      );

      expect(
        repo.getCatalog(),
        throwsA(
            isA<ApiException>().having((e) => e.code, 'code', 'NOT_STUDENT')),
      );
    });

    test('menolak respons yang bentuknya tidak dikenali', () async {
      final repo = ApiAdoptionCatalogRepository(
        get: (path, {queryParameters}) async =>
            jsonResponse({'success': false}),
      );
      expect(repo.getCatalog(), throwsA(isA<ApiException>()));
    });
  });

  group('MockAdoptionCatalogRepository', () {
    test('mengubah data tiruan menjadi item katalog', () async {
      final repo = MockAdoptionCatalogRepository(MockAdoptionRepository());
      final cats = await repo.getCatalog();
      expect(cats, isNotEmpty);
      expect(cats.every((c) => c.gender == 'MALE' || c.gender == 'FEMALE'),
          isTrue);
    });
  });

  group('AdoptionProvider katalog', () {
    AdoptionProvider makeProvider() => AdoptionProvider(
          catalogRepository: _FakeCatalog(const [
            AdoptionCatalogCat(
                id: 'a', name: 'Miko', gender: 'MALE', ageGroup: 'ADULT'),
            AdoptionCatalogCat(
                id: 'b', name: 'Luna', gender: 'FEMALE', ageGroup: 'KITTEN'),
          ]),
        );

    test('memuat katalog lalu menyaring di aplikasi tanpa memuat ulang',
        () async {
      final fake = _FakeCatalog(const [
        AdoptionCatalogCat(id: 'a', name: 'Miko', gender: 'MALE'),
        AdoptionCatalogCat(id: 'b', name: 'Luna', gender: 'FEMALE'),
      ]);
      final provider = AdoptionProvider(catalogRepository: fake);

      await provider.fetchCatalog();
      expect(provider.catalogCats, hasLength(2));
      expect(provider.isCatalogLoading, isFalse);
      expect(provider.catalogError, isNull);

      provider.setCatalogFilter(const AdoptionCatalogFilter(gender: 'FEMALE'));
      expect(provider.catalogCats.single.name, 'Luna');
      expect(fake.calls, 1);
    });

    test('filter umur bekerja', () async {
      final provider = makeProvider();
      await provider.fetchCatalog();

      provider
          .setCatalogFilter(const AdoptionCatalogFilter(ageGroup: 'KITTEN'));
      expect(provider.catalogCats.single.name, 'Luna');

      provider.setCatalogFilter(const AdoptionCatalogFilter());
      expect(provider.catalogCats, hasLength(2));
    });

    test('kegagalan memuat ditampilkan sebagai error, bukan daftar kosong',
        () async {
      final provider =
          AdoptionProvider(catalogRepository: _FakeCatalog.failing());

      await provider.fetchCatalog();

      expect(provider.catalogError, 'Katalog belum bisa dimuat.');
      expect(provider.isCatalogLoading, isFalse);
    });
  });
}

class _FakeCatalog implements AdoptionCatalogRepository {
  final List<AdoptionCatalogCat> cats;
  final bool fail;
  int calls = 0;

  _FakeCatalog(this.cats) : fail = false;
  _FakeCatalog.failing()
      : cats = const [],
        fail = true;

  @override
  Future<List<AdoptionCatalogCat>> getCatalog() async {
    calls++;
    if (fail) throw ApiException(message: 'Katalog belum bisa dimuat.');
    return cats;
  }
}
