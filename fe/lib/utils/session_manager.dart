import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyLogin = 'isLogin';
  static const _keyId = 'id';
  static const _keyNama = 'nama';

  static Future<void> saveLogin(int id, String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogin, true);
    await prefs.setInt(_keyId, id);
    await prefs.setString(_keyNama, nama);
  }

  static Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLogin) ?? false;
  }

  static Future<int?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyId);
  }

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNama);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
