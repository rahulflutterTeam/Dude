// lib/Services/AppUpdateService.dart
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static const String _lastDismissedVersionKey = 'last_dismissed_version';

  static Future<bool> checkForUpdate(
    BuildContext context, {
    bool showOptionalUpdate = true,
  }) async {
    try {
      final currentVersion = await _getAppVersion();
      print('Current App Version: $currentVersion');

      final response = await http.get(
        Uri.parse(
          "https://api.pair-ever.com/api/v1/auth/user/getAppUpdateConfig",
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (!context.mounted) return false;

      print('Update API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final appData = data['data'] ?? data;

        final latestVersion = appData['latest_version']?.toString();
        final forceUpdate = _asBool(appData['force_update']);
        final apkUrl = appData['apk_url'] ?? '';
        final maintenanceStatus = _asBool(appData['maintenance_status']);
        final maintenanceMessage =
            appData['maintenance_message']?.toString() ??
            'App is under maintenance. Please try again later.';

        print(
          'Latest Version: $latestVersion | Force Update: $forceUpdate | '
          'Maintenance: $maintenanceStatus',
        );

        if (maintenanceStatus) {
          _showMaintenanceDialog(context, maintenanceMessage);
          return true;
        }

        if (latestVersion != null &&
            _isUpdateAvailable(currentVersion, latestVersion)) {
          if (!forceUpdate && !showOptionalUpdate) return false;

          // Check if user already clicked "Later" for this version
          final prefs = await SharedPreferences.getInstance();
          if (!context.mounted) return false;
          final lastDismissed = prefs.getString(_lastDismissedVersionKey);

          if (!forceUpdate && lastDismissed == latestVersion) {
            print('User already dismissed this version');
            return false;
          }

          _showUpdateDialog(context, apkUrl, forceUpdate, latestVersion);
          return forceUpdate;
        }
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
    return false;
  }

  static Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase().trim() == 'true';
  }

  static bool _isUpdateAvailable(String current, String latest) {
    if (current.isEmpty || latest.isEmpty) return false;

    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return current != latest;
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String apkUrl,
    bool force,
    String latestVersion,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (context) => WillPopScope(
        onWillPop: () async => !force,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF241b40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update,
                  size: 60,
                  color: Color(0xFFaecc01),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Update Available!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "A new version is available.\nPlease update to continue using the Dude.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),

                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (apkUrl.isNotEmpty) {
                        await launchUrl(Uri.parse(apkUrl));
                      } else {
                        Utils.snackBarErrorMessage("Update link is empty");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFaecc01),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Update Now",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Later Button (Only if not force update)
                if (!force) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      // Save this version so it doesn't show again
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        _lastDismissedVersionKey,
                        latestVersion,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Later",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ],

                // Force Update Warning
                if (force) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "This is a mandatory update. You must update to continue.",
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showMaintenanceDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF241b40),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 60,
                  color: Color(0xFFaecc01),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Under Maintenance",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "You cannot access the app until maintenance is complete.",
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
