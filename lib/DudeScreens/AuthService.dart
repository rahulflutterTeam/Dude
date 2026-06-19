// Updated AuthService

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyPhone = 'user_phone';
  static const String _keyIsOnline = 'staff_is_online';
  static const String _keyCallType = 'staff_call_type';

  // Save after successful login
  static Future<void> saveLoginData({
    required String token,
    String? userId,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (userId != null) await prefs.setString(_keyUserId, userId);
    if (phone != null) await prefs.setString(_keyPhone, phone);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    print("Token ::::::: $token");
    return token != null && token.isNotEmpty;
  }

  // Logout / clear - COMPLETE CLEAR
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all authentication-related keys
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);

    // Clear staff-specific status
    await prefs.remove(_keyIsOnline);
    await prefs.remove(_keyCallType);

    // Clear any other app-specific data
    await prefs.remove('staff_data');
    await prefs.remove('staff_profile');
    await prefs.remove('isLoggedIn');

    // Optional: Clear all preferences (use with caution)
    // await prefs.clear();

    print("✅ All auth data cleared from SharedPreferences");
  }
}
