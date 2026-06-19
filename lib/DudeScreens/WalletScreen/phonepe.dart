// lib/DudeScreens/WalletScreen/phonepe.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class PhonePeService {
  static const String _merchantId = "M23XUP3CZ7NE4";
  static const String _clientId = "M23XUP3CZ7NE4_2603161042";
  static const String _clientSecret =
      "M2U1MGQyNWUtMzViNS00ZjdmLWIwNjctZjM3NWZiNmFkMzlj";
  static const String _clientVersion = "1";
  static const String _environment = "SANDBOX";
  static const String _flowId = "defaultflow";
  static const bool _enableLogs = true;
  static const String _baseUrl =
      "https://api-preprod.phonepe.com/apis/pg-sandbox";

  static String? _accessToken;
  static int _tokenExpiry = 0;

  static Future<void> init() async {
    await PhonePePaymentSdk.init(
      _environment,
      _merchantId,
      _flowId,
      _enableLogs,
    );
  }

  static Future<String> _getAccessToken() async {
    if (_accessToken != null &&
        DateTime.now().millisecondsSinceEpoch < _tokenExpiry) {
      debugPrint("▶ PhonePe: using cached token");
      return _accessToken!;
    }

    debugPrint("▶ PhonePe: fetching new OAuth token...");
    final response = await http.post(
      Uri.parse("$_baseUrl/v1/oauth/token"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "client_id": _clientId,
        "client_secret": _clientSecret,
        "client_version": _clientVersion,
        "grant_type": "client_credentials",
      },
    );

    debugPrint(
      "▶ PhonePe: token response ${response.statusCode} = ${response.body}",
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Token fetch failed ${response.statusCode}: ${response.body}",
      );
    }

    final data = jsonDecode(response.body);
    _accessToken = data["access_token"] as String;
    final expiresIn = (data["expires_in"] as int? ?? 3600);
    _tokenExpiry =
        DateTime.now().millisecondsSinceEpoch + (expiresIn - 60) * 1000;

    debugPrint("▶ PhonePe: token OK, expires in ${expiresIn}s");
    return _accessToken!;
  }

  static Future<Map<String, String>> _createOrder({
    required String merchantOrderId,
    required int amountInPaise,
  }) async {
    final token = await _getAccessToken();

    final requestBody = {
      "merchantOrderId": merchantOrderId,
      "amount": amountInPaise,
      "expireAfter": 1200,
      "paymentFlow": {
        "type": "PG_CHECKOUT",
        "merchantUrls": {"redirectUrl": "https://webhook.site/your-dummy-url"},
      },
    };

    debugPrint("▶ PhonePe: creating order — $requestBody");

    final response = await http.post(
      Uri.parse("$_baseUrl/checkout/v2/pay"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "O-Bearer $token",
      },
      body: jsonEncode(requestBody),
    );

    debugPrint(
      "▶ PhonePe: create order ${response.statusCode} = ${response.body}",
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Create order failed ${response.statusCode}: ${response.body}",
      );
    }

    final data = jsonDecode(response.body);

    // Print every field so we know exactly what PhonePe returns
    debugPrint("▶ PhonePe: response keys = ${data.keys.toList()}");
    data.forEach((k, v) => debugPrint("▶ PhonePe:   $k = $v"));

    final String orderId = data["orderId"] as String;

    String sdkToken = "";
    if (data["token"] != null) {
      sdkToken = data["token"] as String;
      debugPrint("▶ PhonePe: token from 'token' field");
    } else if (data["redirectUrl"] != null) {
      final uri = Uri.parse(data["redirectUrl"] as String);
      sdkToken =
          uri.queryParameters["token"] ?? (data["redirectUrl"] as String);
      debugPrint("▶ PhonePe: token extracted from redirectUrl");
    } else {
      debugPrint("▶ PhonePe: ⚠️ no token found in response!");
    }

    return {
      "orderId": orderId,
      "token": sdkToken,
      "redirectUrl": data["redirectUrl"] as String,
    };
  }

  static Future<bool> startPayment({
    required BuildContext context,
    required int amountInRupees,
    required String userId,
    required String mobileNumber,
  }) async {
    try {
      debugPrint("▶ PhonePe: startPayment ₹$amountInRupees");

      final merchantOrderId =
          "MO${const Uuid().v4().replaceAll('-', '').substring(0, 18)}";

      final order = await _createOrder(
        merchantOrderId: merchantOrderId,
        amountInPaise: amountInRupees * 100,
      );

      final String orderId = order["orderId"]!;
      final String redirectUrl =
          order["redirectUrl"]!; // ← use full redirectUrl directly

      debugPrint("▶ PhonePe: opening redirectUrl = $redirectUrl");

      // Open PhonePe UAT web payment page directly in browser
      final uri = Uri.parse(redirectUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack(context, "Could not open payment page");
        return false;
      }

      // Since web flow has no callback, show pending message
      _showSnack(
        context,
        "Complete payment in browser, then return here.",
        success: true,
      );
      return true;
    } on Exception catch (e) {
      debugPrint("▶ PhonePe ERROR: $e");
      _showSnack(context, "PhonePe error: $e");
      return false;
    }
  }

  static void _showSnack(
    BuildContext context,
    String msg, {
    bool success = false,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
