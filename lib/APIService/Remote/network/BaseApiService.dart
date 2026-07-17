abstract class BaseApiService {
  // final String baseUrl = "https://bondingbackend.onrender.com/api/v1/";
  final String baseUrl = "https://api.dudee.online/api/v1/";
  // final String baseUrl = "http://192.168.1.43:7000/api/v1/";

  final String baseUrlV2 = "";

  Future<dynamic> getResponse(String url);

  Future<dynamic> postResponse(String url, {Map<String, dynamic>? body});

  Future<dynamic> postResponseV2(String url, {Map<String, dynamic>? body});
}
