abstract class BaseApiService {
  // demo
  // final String baseUrl = "https://api.ubitpro.exchange/api/v1/";
  // final String baseUrlV2 = "https://api.ubitpro.exchange/api/v2/";
  // final String bearPull = "https://exchangeapi.coincred.pro/appapi/v1/";
  // final String simpleEarn = "https://simpleearnapi.clarisco.com/webapi/v1/";
  // final String lanchpad = "https://exchangeapi.coincred.pro/appapi/v1/";
  // final String launchpadV2 = "https://exchangeapi.coincred.pro/appapi/v2/";
  // final String perpetualURL = "https://coincred-staging-perpetualapi.fibitpro.com/appapi/v1/";

  // live
  final String baseUrl = "https://api.ubitpro.exchange/appapi/v1/";
  final String baseUrlV2 = "https://api.ubitpro.exchange/appapi/v2/";
  final String bearPull = "https://api.ubitpro.exchange/appapi/v1/";
  final String simpleEarn = "https://simpleearnapi.ubitpro.exchange/appapi/v1/";
  final String lanchpad = "https://api.ubitpro.exchange/appapi/v1/";
  final String launchpadV2 = "https://api.ubitpro.exchange/appapi/v2/";
  final String perpetualURL =
      "https://perpetualapi.ubitpro.exchange/appapi/v1/";

  // live
  // final String baseUrl = "https://exchangeapi.coincred.pro/appapi/v1/";
  // final String baseUrlV2 = "https://exchangeapi.coincred.pro/appapi/v2/";
  // final String bearPull = "https://exchangeapi.coincred.pro/appapi/v1/";
  // final String simpleEarn = "https://simpleearnapi.clarisco.com/webapi/v1/";
  // final String lanchpad = "https://exchangeapi.coincred.pro/appapi/v1/";
  // final String launchpadV2 = "https://exchangeapi.coincred.pro/appapi/v2/";
  // final String perpetualURL = "https://perpetualapi.coincred.pro/appapi/v1/";

  Future<dynamic> getResponse(String url);
  Future<dynamic> postResponse(String url, {Map<String, dynamic>? body});
  Future<dynamic> postResponseV2(String url, {Map<String, dynamic>? body});
}
