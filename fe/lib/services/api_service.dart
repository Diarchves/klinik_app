import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2/klinik_api',
  );

  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> _jsonHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri _uri(String endpoint, [Map<String, dynamic>? query]) {
    final normalized = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    final uri = Uri.parse('$baseUrl/$normalized');
    if (query == null) {
      return uri;
    }
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      final stringified = value.toString();
      if (stringified.isEmpty) return;
      filtered[key] = stringified;
    });
    return filtered.isEmpty ? uri : uri.replace(queryParameters: filtered);
  }

  static Future<T> _request<T>(Future<http.Response> request) async {
    final response = await request.timeout(_timeout);
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as T;
    }

    if (decoded is Map<String, dynamic> && decoded['message'] != null) {
      throw Exception(decoded['message']);
    }

    throw Exception('Permintaan gagal (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> login(
    String nik,
    String password,
  ) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('login.php'),
        headers: _jsonHeaders(),
        body: jsonEncode({'nik': nik, 'password': password}),
      ),
    );
  }

  static Future<Map<String, dynamic>> adminLogin(
    String username,
    String password,
  ) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('admin_login.php'),
        headers: _jsonHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
  }

  static Future<Map<String, dynamic>> register({
    required String nik,
    required String nama,
    required String password,
    String? tanggalLahir,
    String? alamat,
    String? noTelepon,
  }) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('register.php'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'nik': nik,
          'nama': nama,
          'password': password,
          'tanggal_lahir': tanggalLahir,
          'alamat': alamat,
          'no_telepon': noTelepon,
        }),
      ),
    );
  }

  static Future<List<dynamic>> getDokter() {
    return _request<List<dynamic>>(
      http.get(_uri('get_dokter.php')),
    );
  }

  static Future<Map<String, dynamic>> createDokter({
    required String nama,
    required String spesialisasi,
    String? noTelepon,
    String? jadwal,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('dokter.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'nama': nama,
          'spesialisasi': spesialisasi,
          'no_telepon': noTelepon,
          'jadwal_praktik': jadwal,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> updateDokter({
    required int idDokter,
    required String token,
    String? nama,
    String? spesialisasi,
    String? noTelepon,
    String? jadwal,
  }) {
    return _request<Map<String, dynamic>>(
      http.patch(
        _uri('dokter.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'id_dokter': idDokter,
          if (nama != null) 'nama': nama,
          if (spesialisasi != null) 'spesialisasi': spesialisasi,
          if (noTelepon != null) 'no_telepon': noTelepon,
          if (jadwal != null) 'jadwal_praktik': jadwal,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> deleteDokter({
    required int idDokter,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.delete(
        _uri('dokter.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({'id_dokter': idDokter}),
      ),
    );
  }

  static Future<Map<String, dynamic>> buatJanji({
    required int idPasien,
    required int idDokter,
    required String tanggal,
    required String jam,
    String? poli,
    String? catatan,
  }) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('buat_janji.php'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'id_pasien': idPasien,
          'id_dokter': idDokter,
          'tanggal': tanggal,
          'jam': jam,
          'poli': poli,
          'catatan': catatan,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getAntrian(int idPasien) {
    return _request<Map<String, dynamic>>(
      http.get(
        _uri('get_antrian.php', {'id_pasien': idPasien}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getAntrianAdmin({
    int? idDokter,
    String? tanggal,
    String? status,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.get(
        _uri('antrian.php', {
          'id_dokter': idDokter,
          'tanggal': tanggal,
          'status': status,
        }),
        headers: _jsonHeaders(token: token),
      ),
    );
  }

  static Future<Map<String, dynamic>> updateAntrian({
    required int idAntrian,
    String? status,
    int? noAntrian,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.patch(
        _uri('antrian.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'id_antrian': idAntrian,
          if (status != null) 'status': status,
          if (noAntrian != null) 'no_antrian': noAntrian,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getRekamMedis(int idPasien) {
    return _request<Map<String, dynamic>>(
      http.get(
        _uri('rekam_medis.php', {'id_pasien': idPasien}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getRekamMedisAdmin({
    int? idJanji,
    int? idPasien,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.get(
        _uri('rekam_medis.php', {
          'id_janji': idJanji,
          'id_pasien': idPasien,
        }),
        headers: _jsonHeaders(token: token),
      ),
    );
  }

  static Future<Map<String, dynamic>> createRekamMedis({
    required int idJanji,
    String? diagnosa,
    String? tindakan,
    String? catatan,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('rekam_medis.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'id_janji': idJanji,
          'diagnosa': diagnosa,
          'tindakan': tindakan,
          'catatan': catatan,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> updateRekamMedis({
    required int idRekamMedis,
    String? diagnosa,
    String? tindakan,
    String? catatan,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.patch(
        _uri('rekam_medis.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'id_rekam_medis': idRekamMedis,
          if (diagnosa != null) 'diagnosa': diagnosa,
          if (tindakan != null) 'tindakan': tindakan,
          if (catatan != null) 'catatan': catatan,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> deleteRekamMedis({
    required int idRekamMedis,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.delete(
        _uri('rekam_medis.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({'id_rekam_medis': idRekamMedis}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getObat() {
    return _request<Map<String, dynamic>>(
      http.get(_uri('obat.php')),
    );
  }

  static Future<Map<String, dynamic>> createObat({
    required String nama,
    String? jenis,
    String? bentuk,
    int? stok,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.post(
        _uri('obat.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'nama_obat': nama,
          'jenis': jenis,
          'bentuk': bentuk,
          'stok': stok,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> updateObat({
    required int idObat,
    required String token,
    String? nama,
    String? jenis,
    String? bentuk,
    int? stok,
  }) {
    return _request<Map<String, dynamic>>(
      http.patch(
        _uri('obat.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          'id_obat': idObat,
          if (nama != null) 'nama_obat': nama,
          if (jenis != null) 'jenis': jenis,
          if (bentuk != null) 'bentuk': bentuk,
          if (stok != null) 'stok': stok,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> deleteObat({
    required int idObat,
    required String token,
  }) {
    return _request<Map<String, dynamic>>(
      http.delete(
        _uri('obat.php'),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({'id_obat': idObat}),
      ),
    );
  }

  static Future<Map<String, dynamic>> getLaporan({
    String? periode,
    String? jenis,
  }) {
    if ((periode == null || periode.isEmpty) && (jenis == null || jenis.isEmpty)) {
      throw Exception('Jenis atau periode laporan wajib diisi');
    }
    return _request<Map<String, dynamic>>(
      http.get(
        _uri('laporan.php', {
          'periode': periode,
          'jenis': jenis,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getJadwalDokter(
    int idDokter, {
    String? tanggalMulai,
    String? tanggalSelesai,
  }) {
    return _request<Map<String, dynamic>>(
      http.get(
        _uri('jadwal.php', {
          'id_dokter': idDokter,
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
        }),
      ),
    );
  }

  static Future<Map<String, dynamic>> getPasienList() {
    return _request<Map<String, dynamic>>(
      http.get(_uri('pasien.php')),
    );
  }
}
