import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2/klinik_api";

  // existing login/register endpoints (if ada)
  static Future<Map<String, dynamic>> login(String nik, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nik": nik, "password": password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(
    String nik,
    String nama,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/register.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nik": nik, "nama": nama, "password": password}),
    );
    return jsonDecode(res.body);
  }

  // dokter list
  static Future<List<dynamic>> getDokter() async {
    final res = await http.get(Uri.parse("$baseUrl/get_dokter.php"));
    // expect JSON array
    return jsonDecode(res.body) as List<dynamic>;
  }

  // buat janji
  static Future<Map<String, dynamic>> buatJanji({
    required int idPasien,
    required int idDokter,
    required String tanggal,
    required String jam,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/buat_janji.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_pasien": idPasien,
        "id_dokter": idDokter,
        "tanggal": tanggal,
        "jam": jam,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // get antrian pasien
  static Future<Map<String, dynamic>> getAntrian(int idPasien) async {
    final res = await http.get(
      Uri.parse("$baseUrl/get_antrian.php?id_pasien=$idPasien"),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
