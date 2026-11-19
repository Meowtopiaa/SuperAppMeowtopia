import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../cat/data/cat_model.dart';
import 'adoption_catalog_model.dart';
import 'mock_adoption_repository.dart';

/// Sumber data katalog adopsi (EN-12). Filter dilakukan di aplikasi,
/// jadi kontrak GET /adoption/cats tidak berubah.
abstract class AdoptionCatalogRepository {
  Future<List<AdoptionCatalogCat>> getCatalog();
}

/// Katalog dari server: GET /api/v1/adoption/cats (PRD 8.6).
typedef CatalogGet = Future<Response> Function(
  String path, {
  Map<String, dynamic>? queryParameters,
});

class ApiAdoptionCatalogRepository implements AdoptionCatalogRepository {
  final CatalogGet _get;

  /// Batas halaman yang diambil sekaligus, agar daftar tidak tak terbatas.
  static const int maxPages = 5;
  static const int perPage = 50;

  /// [get] dapat diganti di tes; bawaannya memakai ApiClient milik Core.
  ApiAdoptionCatalogRepository({CatalogGet? get})
      : _get = get ?? ApiClient().get;

  @override
  Future<List<AdoptionCatalogCat>> getCatalog() async {
    final cats = <AdoptionCatalogCat>[];
    var page = 1;
    while (page <= maxPages) {
      final Response response;
      try {
        response = await _get(
          '/adoption/cats',
          queryParameters: {'page': page, 'per_page': perPage},
        );
      } on DioException catch (e) {
        final error = e.error;
        throw error is ApiException
            ? error
            : ApiException(message: 'Katalog belum bisa dimuat.');
      }

      final body = response.data;
      if (body is! Map<String, dynamic> ||
          body['success'] != true ||
          body['data'] is! List) {
        throw ApiException(message: 'Respons katalog tidak dikenali.');
      }
      cats.addAll(
        (body['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(AdoptionCatalogCat.fromJson),
      );

      final meta = body['meta'];
      final hasMore = meta is Map<String, dynamic> && meta['has_more'] == true;
      if (!hasMore) break;
      page++;
    }
    return cats;
  }
}

/// Katalog dari data tiruan untuk mode demo. Memakai [MockAdoptionRepository]
/// yang sama dengan provider supaya kucing yang sudah diambil ikut hilang.
class MockAdoptionCatalogRepository implements AdoptionCatalogRepository {
  final MockAdoptionRepository _source;

  MockAdoptionCatalogRepository(this._source);

  /// Kelompok umur data tiruan (CatModel milik modul cat belum punya kolom umur).
  static const Map<int, String> _ageById = {
    101: 'ADULT',
    102: 'ADULT',
    103: 'KITTEN',
    104: 'SENIOR',
    105: 'KITTEN',
  };

  @override
  Future<List<AdoptionCatalogCat>> getCatalog() async {
    final cats = await _source.getReadyCats();
    return cats.map(_fromMock).toList();
  }

  static AdoptionCatalogCat _fromMock(CatModel cat) {
    final colors = [cat.primaryColor, cat.pattern]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return AdoptionCatalogCat(
      id: cat.id.toString(),
      name: cat.name,
      gender: switch (cat.gender.toLowerCase()) {
        'male' => 'MALE',
        'female' => 'FEMALE',
        _ => 'UNKNOWN',
      },
      ageGroup: _ageById[cat.id] ?? 'UNKNOWN',
      colorPattern: colors.isEmpty ? null : colors,
      isSterilized: cat.sterilizationStatus,
      description: cat.description,
      photoUrl: cat.primaryPhotoUrl,
    );
  }
}
