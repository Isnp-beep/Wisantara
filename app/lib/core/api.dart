import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Klien REST untuk API PHP Wisantara.
class Api {
  String base;
  String? token;
  Api(this.base, [this.token]);

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final u = Uri.parse('$base$path');
    if (query == null || query.isEmpty) return u;
    final q = <String, String>{};
    query.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    return u.replace(queryParameters: q);
  }

  dynamic _handle(http.Response r) {
    dynamic data;
    try {
      data = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw ApiException('Respons server tidak valid (${r.statusCode}). Cek URL API.', r.statusCode);
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return data;
    final msg = (data is Map && data['error'] != null) ? '${data['error']}' : 'Terjadi kesalahan (${r.statusCode})';
    throw ApiException(msg, r.statusCode);
  }

  Future<dynamic> _run(Future<http.Response> Function() f) async {
    try {
      return _handle(await f().timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server. Pastikan Laragon menyala dan URL API benar.');
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => http.get(_uri(path, query), headers: _headers));
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _run(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _run(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _run(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> delete(String path) => _run(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> postMultipart(String path, Map<String, String> fields, {String? filePath}) async {
    try {
      final req = http.MultipartRequest('POST', _uri(path));
      req.headers['Accept'] = 'application/json';
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll(fields);
      if (filePath != null) req.files.add(await http.MultipartFile.fromPath('image', filePath));
      final streamed = await req.send().timeout(const Duration(seconds: 40));
      return _handle(await http.Response.fromStream(streamed));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Gagal mengunggah. Periksa koneksi ke server.');
    }
  }
}
