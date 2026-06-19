class ApiEndPoints {
  // bitbab
  final String baseUrl = "https://api.pair-ever.com/api/v1/";
  // final String baseUrl = "http://192.168.1.43:7000/api/v1/";
  final String webSocketUrl = "https://api.pair-ever.com";
  // final String webSocketUrl = "http://192.168.1.43:7000";
  // final String profileBaseUrl = "https://predictapi.unitythink.com";

  final String login = "auth/user/signup";
  final String verifyOtp = "auth/user/verify-otp";
  final String updateProfile = "auth/user/updateProfile";
  final String updateBioData = "auth/user/user-Bio-Data";
  final String updateAreaOfInterest = "auth/user/area-Of-Interest";
  final String updateLanguage = "auth/user/user-Language";
  final String getUserDetails = "auth/user/getUserDetails";
  final String updateIsFirstLogin = "auth/user/updateIsFirstLogin";
  final String userBalanceUpdate = "auth/user/userBalanceUpdate";
  final String userCallHistory = "auth/user/userCallHistory";
  final String placeOrder = "auth/user/placeOrder";
  final String confirmPurchase = "auth/user/confirmPurchase";
  final String getPaymentGatewayKey = "auth/user/getPaymentGatewayKey";
  final String userDepositHistory = "auth/user/userDepositHistory";

  final String getPaymentsStructure = "auth/user/getPaymentsStructure";
  final String deleteAccount = "auth/user/deleteAccount";

  final String getAdBanner = "auth/user/getAdBanner";

  final String referralDashboard = "auth/user/referral/dashboard";

  // Push notifications (promo/admin)
  // Backend should implement this endpoint to upsert device tokens.
  final String pushRegisterToken = "push/token/register";

  ////////////// Staff flow ///////////////

  final String staffRegister = "staff/staff-data";
  final String staffRegisterNew = "staff/staff-isLogin";
  final String staffVerifyOtp = "staff/verify-otps";
  final String staffIdVerify = "staff/staffIdVerify";
  final String updateStaffProfile = "staff/updateProfile";
  final String updateStaffAreaOfInterest = "staff/area-Of-Interest";

  final String getStaffDetails = "auth/user/getstaffDetails";

  final String getStaffSingleData = "staff/getstaffSingleData";

  final String staffCallHistory = "staff/staffCallHistory";

  final String addBankDetails = "staff/addBankDetails";

  final String getAllBankDetails = "staff/getAllBankDetails";
  final String deleteBankDetails = "staff/deleteBankDetails";

  final String staffWithdraw = "staff/staffWithdraw";

  final String staffWithdrawHistory = "staff/staffWithdrawHistory";

  final String staffCallStats = "staff/getStaffCallStats";

  final String staffWeeklyCallGraph = "staff/getWeeklyCallGraph";
  final String staffDeleteAccount = "staff/deleteAccount";

  final String staffCallStatusUpdate = "staff/staffCallStatusUpdatae";

  final String staffUpdateCallType = "staff/updateCallType";

  final String staffUpdateLanguage = "staff/staffLanguage";

  final String getStaffGifts = "auth/user/getStaffGifts";
  final String staffFeeManagement = "staff/getFeeManagement";
}
