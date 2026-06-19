// lib/DudeScreens/WalletScreen/Model/PaymentStructureModel.dart
class PaymentStructureResponse {
  final bool status;
  final String message;
  final List<PaymentPackage> data;

  PaymentStructureResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PaymentStructureResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStructureResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((item) => PaymentPackage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentPackage {
  final String id;
  final String coin;
  final int amount;
  final String offerAmount;
  final String offerStatus;
  final String createdAt;
  final String updatedAt;
  final int v;
  final String image;

  PaymentPackage({
    required this.id,
    required this.coin,
    required this.amount,
    required this.offerAmount,
    required this.offerStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.image,
  });

  factory PaymentPackage.fromJson(Map<String, dynamic> json) {
    return PaymentPackage(
      id: json['_id'] as String,
      coin: json['coin'] as String,
      amount: json['amount'] as int,
      offerAmount: json['offerAmount'] as String,
      offerStatus: json['offerStatus'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      v: json['__v'] as int,
      image: json['image'] as String,
    );
  }
}
