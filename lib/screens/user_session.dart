import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static String userId = '';
  static String userType = ''; // ← Agregado

  static Future<void> saveUser(String id, String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
    await prefs.setString('userType', type);
    userId = id;
    userType = type;
  }

  static Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    userType = prefs.getString('userType') ?? '';
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userType');
    userId = '';
    userType = '';
  }

  static bool get isLoggedIn => userId.isNotEmpty;
}
