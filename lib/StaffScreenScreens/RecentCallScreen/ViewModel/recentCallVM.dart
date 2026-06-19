//
//
// import 'package:flutter/cupertino.dart';
//
// class CallViewModel extends ChangeNotifier {
//   final CallRepository _callRepo; // or UserRepository if in same repo
//
//   CallViewModel(this._callRepo);
//
//   List<CallHistoryItem> _callHistory = [];
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   List<CallHistoryItem> get callHistory => _callHistory;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//
//   Future<void> fetchCallHistory() async {
//     _isLoading = true;
//     _errorMessage = null;
//     notifyListeners();
//
//     try {
//       final response = await _callRepo.getStaffCallHistory();
//       _callHistory = response.data ?? [];
//     } catch (e) {
//       _errorMessage = e.toString();
//       debugPrint("Call history error: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Optional: Refresh
//   Future<void> refresh() => fetchCallHistory();
// }
