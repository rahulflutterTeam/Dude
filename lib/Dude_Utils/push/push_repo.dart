import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/APIService/Remote/network/NetworkApiService.dart';

class PushRepo {
  PushRepo({NetworkApiService? api}) : _api = api ?? NetworkApiService();
  final NetworkApiService _api;

  Future<void> registerDeviceToken({
    required String memberId,
    required String role,
    required String platform,
    required String token,
  }) async {
    await _api.postResponseV3(
      ApiEndPoints().pushRegisterToken,
      body: {
        'memberID': memberId,
        'role': role,
        'platform': platform,
        'token': token,
      },
    );
  }
}
