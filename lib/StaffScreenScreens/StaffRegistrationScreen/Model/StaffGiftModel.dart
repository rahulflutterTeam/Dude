class StaffGiftsResponse {
  final bool status;
  final String message;
  final List<StaffGiftItem> data;

  StaffGiftsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory StaffGiftsResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List?;
    List<StaffGiftItem> giftList = list != null
        ? list
              .map((i) => StaffGiftItem.fromJson(i as Map<String, dynamic>))
              .toList()
        : [];
    return StaffGiftsResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: giftList,
    );
  }
}

class StaffGiftItem {
  final String id;
  final String giftName;
  final String giftImage;
  final int coins;
  final String senderName;
  final String senderImage;
  final DateTime createdAt;

  StaffGiftItem({
    required this.id,
    required this.giftName,
    required this.giftImage,
    required this.coins,
    required this.senderName,
    required this.senderImage,
    required this.createdAt,
  });

  factory StaffGiftItem.fromJson(Map<String, dynamic> json) {
    // 1. Gift details parsing: might be nested under 'gift' or at top level
    String gName = '';
    String gImage = '';
    int gCoins = 0;

    if (json['gift'] is Map) {
      final giftMap = json['gift'] as Map<String, dynamic>;
      gName =
          giftMap['name']?.toString() ?? giftMap['giftName']?.toString() ?? '';
      gImage =
          giftMap['image']?.toString() ??
          giftMap['giftImage']?.toString() ??
          giftMap['icon']?.toString() ??
          '';
      gCoins =
          (giftMap['coin'] as num?)?.toInt() ??
          (giftMap['coins'] as num?)?.toInt() ??
          0;
    } else {
      gName = json['giftName']?.toString() ?? json['name']?.toString() ?? '';
      gImage =
          json['giftImage']?.toString() ??
          json['image']?.toString() ??
          json['icon']?.toString() ??
          '';
      gCoins =
          (json['coin'] as num?)?.toInt() ??
          (json['coins'] as num?)?.toInt() ??
          (json['amount'] as num?)?.toInt() ??
          0;
    }

    // 2. Sender details parsing: might be nested under 'fromUser' or 'user' or at top level
    String sName = 'User';
    String sImage = '';

    if (json['fromUser'] is Map) {
      final userMap = json['fromUser'] as Map<String, dynamic>;
      sName =
          userMap['name']?.toString() ??
          userMap['userName']?.toString() ??
          'User';
      sImage =
          userMap['image']?.toString() ?? userMap['avatar']?.toString() ?? '';
    } else if (json['user'] is Map) {
      final userMap = json['user'] as Map<String, dynamic>;
      sName =
          userMap['name']?.toString() ??
          userMap['userName']?.toString() ??
          'User';
      sImage =
          userMap['image']?.toString() ?? userMap['avatar']?.toString() ?? '';
    } else {
      sName =
          json['senderName']?.toString() ??
          json['userName']?.toString() ??
          json['from']?.toString() ??
          'User';
      sImage =
          json['senderImage']?.toString() ??
          json['userImage']?.toString() ??
          '';
    }

    return StaffGiftItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      giftName: gName.isNotEmpty ? gName : 'Gift',
      giftImage: gImage,
      coins: gCoins,
      senderName: sName.isNotEmpty ? sName : 'User',
      senderImage: sImage,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
