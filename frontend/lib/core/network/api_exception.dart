class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic errors;
  final String? requestId;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors,
    this.requestId,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, int? statusCode) {
    return ApiException(
      message: json['message']?.toString() ?? 'Terjadi kesalahan sistem.',
      statusCode: statusCode,
      code: json['code']?.toString(),
      errors: json['errors'],
      requestId: json['request_id']?.toString(),
    );
  }

  @override
  String toString() => message;
}
