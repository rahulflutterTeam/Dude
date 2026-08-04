// Updated AuthService

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyPhone = 'user_phone';
  static const String _keyIsOnline = 'staff_is_online';
  static const String _keyCallType = 'staff_call_type';
  static const String _keyPendingDemoCallUser = 'pending_demo_call_user';
  static const String _keyPendingDemoCallBrand = 'pending_demo_call_brand';
  static const String _keyDemoCallBrand = 'demo_call_brand';

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
    return token != null && token.isNotEmpty;
  }

  /// Queues the one-time welcome call returned by the user OTP API.
  /// Staff authentication never calls this method.
  static Future<void> saveNewUserDemoCall({
    required bool newUser,
    required String userId,
    required String appName,
  }) async {
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    // Keep the brand for the recurring low-balance call as well as the
    // original one-time new-user flow.
    await prefs.setString(_keyDemoCallBrand, appName);
    if (!newUser) return;

    await prefs.setString(_keyPendingDemoCallUser, userId);
    await prefs.setString(_keyPendingDemoCallBrand, appName);
  }

  static Future<String> getDemoCallBrand() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDemoCallBrand) ??
        prefs.getString(_keyPendingDemoCallBrand) ??
        '0';
  }

  /// Atomically consumes the pending call before it is displayed, ensuring it
  /// cannot be shown twice even if the app is closed from the call screen.
  static Future<({String userId, String appName})?>
  takeNewUserDemoCall() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyPendingDemoCallUser);
    if (userId == null || userId.isEmpty) return null;

    final loggedInUserId = prefs.getString(_keyUserId);
    if (loggedInUserId != userId) {
      await prefs.remove(_keyPendingDemoCallUser);
      await prefs.remove(_keyPendingDemoCallBrand);
      return null;
    }

    final appName = prefs.getString(_keyPendingDemoCallBrand) ?? '0';
    await prefs.remove(_keyPendingDemoCallUser);
    await prefs.remove(_keyPendingDemoCallBrand);
    return (userId: userId, appName: appName);
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
    await prefs.remove(_keyPendingDemoCallUser);
    await prefs.remove(_keyPendingDemoCallBrand);
    await prefs.remove(_keyDemoCallBrand);

    // Clear any other app-specific data
    await prefs.remove('staff_data');
    await prefs.remove('staff_profile');
    await prefs.remove('isLoggedIn');

    // Optional: Clear all preferences (use with caution)
    // await prefs.clear();

    print("✅ All auth data cleared from SharedPreferences");
  }
}
