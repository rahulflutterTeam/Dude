// lib/DudeScreens/WalletScreen/Model/AdBannerModel.dart

class AdBannerModel {
  final bool status;
  final String message;
  final AdBannerData? data;

  AdBannerModel({required this.status, required this.message, this.data});

  factory AdBannerModel.fromJson(Map<String, dynamic> json) {
    return AdBannerModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AdBannerData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data?.toJson()};
  }
}

class AdBannerData {
  final String id;
  final String bannerKey;
  final String image;
  final int amount;
  final String coin;
  final String coins;

  AdBannerData({
    required this.id,
    required this.bannerKey,
    required this.image,
    required this.amount,
    required this.coin,
    required this.coins,
  });

  int get purchaseCoins {
    final backendCoins = int.tryParse(coins);
    if (backendCoins != null) return backendCoins;
    return int.tryParse(coin) ?? 0;
  }

  factory AdBannerData.fromJson(Map<String, dynamic> json) {
    return AdBannerData(
      id: json['_id'] ?? '',
      bannerKey: json['bannerKey'] ?? '',
      image: json['image'] ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      coin: json['coin']?.toString() ?? '',
      coins: json['coins']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'bannerKey': bannerKey,
      'image': image,
      'amount': amount,
      'coin': coin,
      'coins': coins,
    };
  }
}
