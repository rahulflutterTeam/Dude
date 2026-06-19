// lib/DudeScreens/WalletScreen/ViewModel/AdBannerViewModel.dart

import 'package:dude/DudeScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:dude/DudeScreens/WalletScreen/AdModel/Model.dart';
import 'package:flutter/foundation.dart';

class AdBannerViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  AdBannerData? _bannerData;
  bool _isLoading = false;
  String? _error;

  AdBannerViewModel(this._userRepository);

  // Getters
  AdBannerData? get bannerData => _bannerData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get bannerImageUrl => _bannerData?.image;
  bool get hasBanner => _bannerData != null && _bannerData!.image.isNotEmpty;

  // Fetch ad banner
  Future<void> fetchAdBanner() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _userRepository.getAdBanner();

      if (response.status && response.data != null) {
        _bannerData = response.data;
        if (kDebugMode) {
          print(
            "✅ Ad banner loaded: ${_bannerData?.bannerKey} - ${_bannerData?.image}",
          );
        }
      } else {
        _error = response.message;
        if (kDebugMode) {
          print("❌ Failed to load ad banner: ${response.message}");
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print("❌ Error fetching ad banner: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear banner data
  void clearBanner() {
    _bannerData = null;
    _error = null;
    notifyListeners();
  }
}
