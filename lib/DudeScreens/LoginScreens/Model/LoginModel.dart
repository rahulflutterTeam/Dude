// lib/models/signup_response.dart
class SignupResponse {
  final bool status;
  final String message;
  final DateTime? otpExpiresTime;
  final String? otp; // only for dev/testing — remove in production!

  SignupResponse({
    required this.status,
    required this.message,
    this.otpExpiresTime,
    this.otp,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      otpExpiresTime: json['otpExpiresTime'] != null
          ? DateTime.parse(json['otpExpiresTime'])
          : null,
      otp: json['otp']?.toString(),
    );
  }

  // Optional: for debugging only
  @override
  String toString() {
    return 'SignupResponse(status: $status, message: $message, expires: $otpExpiresTime, otp: $otp)';
  }
}
