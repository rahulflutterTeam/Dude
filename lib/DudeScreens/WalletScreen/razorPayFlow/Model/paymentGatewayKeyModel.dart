class PaymentGatewayKeyResponse {
  final bool status;
  final String message;
  final PaymentGatewayKeyData? data;

  const PaymentGatewayKeyResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PaymentGatewayKeyResponse.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayKeyResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? PaymentGatewayKeyData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaymentGatewayKeyData {
  final String provider;
  final String keyId;
  final String mode;
  final String accountName;
  final String paymentGatewayId;
  final String source;

  const PaymentGatewayKeyData({
    required this.provider,
    required this.keyId,
    required this.mode,
    required this.accountName,
    required this.paymentGatewayId,
    required this.source,
  });

  factory PaymentGatewayKeyData.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayKeyData(
      provider: json['provider']?.toString() ?? '',
      keyId: json['keyId']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      paymentGatewayId: json['paymentGatewayId']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}
