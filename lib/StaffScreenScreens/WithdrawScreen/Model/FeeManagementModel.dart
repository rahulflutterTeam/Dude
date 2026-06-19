class FeeManagementResponse {
  final bool status;
  final String message;
  final FeeManagementData? data;

  FeeManagementResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory FeeManagementResponse.fromJson(Map<String, dynamic> json) {
    return FeeManagementResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? FeeManagementData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FeeManagementData {
  static const String withdrawFee = 'withdraw_fee';
  static const String platformFee = 'platform_fee';
  static const String gst = 'gst';
  static const String audioCallAmount = 'audio_call_amount';
  static const String videoCallAmount = 'video_call_amount';
  static const String messageAmount = 'message_amount';

  final List<FeeManagementItem> fees;
  final List<FeeManagementItem> list;
  final Map<String, FeeManagementItem> config;
  final int requiredTypes;
  final int configuredFees;

  FeeManagementData({
    required this.fees,
    required this.list,
    required this.config,
    required this.requiredTypes,
    required this.configuredFees,
  });

  factory FeeManagementData.fromJson(Map<String, dynamic> json) {
    final configJson = json['config'];
    final config = <String, FeeManagementItem>{};

    if (configJson is Map<String, dynamic>) {
      configJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          config[key] = FeeManagementItem.fromJson(key, value);
        }
      });
    }

    return FeeManagementData(
      fees: _parseItems(json['fees']),
      list: _parseItems(json['list']),
      config: config,
      requiredTypes: _toInt(json['requiredTypes']),
      configuredFees: _toInt(json['configuredFees']),
    );
  }

  FeeManagementItem? get staffWithdrawalFee {
    return itemForKey(withdrawFee) ??
        _firstMatchingItem(['withdraw', 'payout']);
  }

  FeeManagementItem? itemForKey(String key) {
    final normalizedKey = _normalizeKey(key);
    final configItem = config[normalizedKey] ?? config[key];

    if (configItem != null) return configItem;

    for (final item in [...fees, ...list]) {
      if (item.matchesKey(normalizedKey)) {
        return item;
      }
    }

    return null;
  }

  double valueForKey(String key, {double fallback = 0}) {
    return itemForKey(key)?.configuredValue ?? fallback;
  }

  double feeForKey(String key, double baseAmount, {double fallback = 0}) {
    return itemForKey(key)?.feeFor(baseAmount) ?? fallback;
  }

  FeeManagementItem? _firstMatchingItem(List<String> parts) {
    final items = <FeeManagementItem>[...config.values, ...fees, ...list];
    for (final item in items) {
      final key = item.lookupKey;
      if (parts.any(key.contains)) {
        return item;
      }
    }

    return null;
  }

  static String _normalizeKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  static List<FeeManagementItem> _parseItems(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map<String, dynamic>>()
        .map((item) => FeeManagementItem.fromJson('', item))
        .toList();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FeeManagementItem {
  final String key;
  final double amount;
  final double value;
  final String unit;
  final String description;
  final String updatedAt;
  final String type;
  final String name;

  FeeManagementItem({
    required this.key,
    required this.amount,
    required this.value,
    required this.unit,
    required this.description,
    required this.updatedAt,
    required this.type,
    required this.name,
  });

  factory FeeManagementItem.fromJson(String key, Map<String, dynamic> json) {
    final amount = _toDouble(json['amount']);
    final value = _toDouble(json['value']);

    return FeeManagementItem(
      key: key.isNotEmpty
          ? key
          : json['key']?.toString() ?? json['feeKey']?.toString() ?? '',
      amount: amount,
      value: value,
      unit: json['unit']?.toString() ?? 'amount',
      description: json['description']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      type: json['type']?.toString() ?? json['feeType']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['title']?.toString() ??
          json['feeTypeLabel']?.toString() ??
          '',
    );
  }

  String get lookupKey => [
    key,
    type,
    name,
    description,
  ].join('_').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  bool matchesKey(String normalizedKey) {
    return lookupKey.split('_').join('_').contains(normalizedKey);
  }

  double feeFor(double baseAmount) {
    final feeValue = amount > 0 ? amount : value;

    if (isPercent) {
      return baseAmount * feeValue / 100;
    }

    return feeValue;
  }

  bool get isPercent {
    final normalizedUnit = unit.toLowerCase();
    return normalizedUnit.contains('percent') || normalizedUnit == '%';
  }

  double get configuredValue => amount > 0 ? amount : value;

  String get displayValue {
    final formattedValue = configuredValue == configuredValue.roundToDouble()
        ? configuredValue.toStringAsFixed(0)
        : configuredValue.toStringAsFixed(2);
    return isPercent ? '$formattedValue%' : '₹$formattedValue';
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
