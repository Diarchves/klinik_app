import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Uri _uri(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$baseUrl/$clean');
  }

  static Future<Map<String, dynamic>> login(String nik, String password) async {
    final response = await http.post(
      _uri('login.php'),
      headers: _jsonHeaders,
      body: jsonEncode({'nik': nik, 'password': password}),
    );
    return _ensureSuccess(_parseMapResponse(response));
  }

  static Future<Map<String, dynamic>> register({
    required String nik,
    required String nama,
    required String password,
    String? tanggalLahir,
    String? alamat,
    String? noTelepon,
  }) async {
    final response = await http.post(
      _uri('register.php'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'nik': nik,
        'nama': nama,
        'password': password,
        if (tanggalLahir != null && tanggalLahir.isNotEmpty)
          'tanggal_lahir': tanggalLahir,
        if (alamat != null && alamat.isNotEmpty) 'alamat': alamat,
        if (noTelepon != null && noTelepon.isNotEmpty) 'no_telepon': noTelepon,
      }),
    );
    return _ensureSuccess(_parseMapResponse(response));
  }

  static Future<List<dynamic>> getDokter() async {
    final response = await http.get(_uri('get_dokter.php'));
    _throwWhenFailed(response);
    final decoded = _decodeBody(response);
    if (decoded is List) {
      return decoded;
    }
    throw ApiException('Format data dokter tidak sesuai');
  }

  static Future<Map<String, dynamic>> buatJanji({
    required int idPasien,
    required int idDokter,
    required String tanggal,
    required String jam,
    String? poli,
    String? catatan,
  }) async {
    final response = await http.post(
      _uri('buat_janji.php'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'id_pasien': idPasien,
        'id_dokter': idDokter,
        'tanggal': tanggal,
        'jam': jam,
        if (poli != null && poli.isNotEmpty) 'poli': poli,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      }),
    );
    return _ensureSuccess(_parseMapResponse(response));
  }

  static Future<Map<String, dynamic>> getAntrian(int idPasien) async {
    final response = await http.get(
      _uri('get_antrian.php?id_pasien=$idPasien'),
    );
    return _ensureSuccess(_parseMapResponse(response));
  }

  static Map<String, dynamic> _parseMapResponse(http.Response response) {
    _throwWhenFailed(response);
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Server mengembalikan format tidak dikenal');
  }

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException('Gagal membaca respons dari server');
    }
  }

  static Map<String, dynamic> _ensureSuccess(Map<String, dynamic> payload) {
    if (payload['success'] == true) {
      return payload;
    }
    throw ApiException(payload['message']?.toString() ?? 'Permintaan gagal');
  }

  static void _throwWhenFailed(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return;
    }
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }
    }
    final message =
        (body is Map && body['message'] != null) ? body['message'].toString() : null;
    throw ApiException(message ?? 'Server error ($status)', statusCode: status);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
