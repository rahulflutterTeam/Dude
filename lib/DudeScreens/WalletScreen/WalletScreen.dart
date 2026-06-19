// lib/screens/wallet_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/WalletScreen/AdBannerVM/AdBannerVM.dart';
import 'package:dude/DudeScreens/WalletScreen/phonepe.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/confirmPaymentModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  late Razorpay _razorpay;
  final CFPaymentGatewayService _cashfree = CFPaymentGatewayService();
  String? _selectedPackageId;
  String? _pressedPackageId;
  bool _isBannerSelected = false;
  bool _isStartingCheckout = false;
  Timer? _checkoutLoaderFallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _cashfree.setCallback(_handleCashfreeVerify, _handleCashfreeError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().fetchPaymentStructure();
      context.read<AdBannerViewModel>().fetchAdBanner();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkoutLoaderFallbackTimer?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isStartingCheckout) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCheckoutLoader();
    }
  }

  /// Razorpay checkout
  void _openCheckout(PaymentPackage package) {
    final amountInRupees = int.parse(
      package.offerAmount.toString() == "0"
          ? package.amount.toString()
          : package.offerAmount.toString(),
    );
    final coins = int.parse(package.coin);

    _openCheckoutForValues(
      amountInRupees: amountInRupees,
      coins: coins,
      description: '${package.coin} Coins Package',
    );
  }

  void _openBannerCheckout(AdBannerViewModel bannerVM) {
    final banner = bannerVM.bannerData;
    if (banner == null) return;

    if (banner.amount <= 0 || banner.purchaseCoins <= 0) {
      Utils.snackBarErrorMessage("Invalid offer package");
      return;
    }

    _openCheckoutForValues(
      amountInRupees: banner.amount,
      coins: banner.purchaseCoins,
      description: '${banner.purchaseCoins} Coins Offer',
    );
  }

  void _selectBannerOffer(AdBannerViewModel bannerVM) {
    final banner = bannerVM.bannerData;
    if (banner == null) return;

    if (banner.amount <= 0 || banner.purchaseCoins <= 0) {
      Utils.snackBarErrorMessage("Invalid offer package");
      return;
    }

    if (kDebugMode) {
      print(
        "Banner selected: ${banner.bannerKey}, amount: ${banner.amount}, coins: ${banner.coins}",
      );
    }
    HapticFeedback.selectionClick();
    setState(() {
      _isBannerSelected = true;
      _selectedPackageId = null;
      _pressedPackageId = null;
    });
  }

  Future<void> _openCheckoutForValues({
    required int amountInRupees,
    required int coins,
    required String description,
  }) async {
    if (_isStartingCheckout) return;

    setState(() => _isStartingCheckout = true);

    final vm = context.read<WalletViewModel>();
    final userVM = context.read<UserViewModel>();
    final phoneNumber = userVM.currentUser?.phone ?? "";

    var checkoutLaunched = false;

    try {
      final gatewayKey = await vm.fetchPaymentGatewayKey();

      if (!mounted) return;
      if (gatewayKey == null) return;

      final response = await vm.placeCoinOrder(
        amountInRupees: amountInRupees,
        currency: 'INR',
        coins: coins,
      );
      if (!mounted || response?.data == null) return;

      final activeProvider = gatewayKey.provider.toLowerCase();
      final gatewayOrder =
          response!.gatewayOrder ?? response.data!.gatewayOrder;

      if (activeProvider == 'cashfree' ||
          response.data!.paymentProvider.toLowerCase() == 'cashfree' ||
          gatewayOrder?.provider.toLowerCase() == 'cashfree') {
        final orderId = _firstNonEmpty([
          gatewayOrder?.orderId,
          response.data!.cashfreeOrderId,
          response.data!.razorpayOrderId,
        ]);
        final paymentSessionId = _sanitizeCashfreeSessionId(
          _firstNonEmpty([
            gatewayOrder?.paymentSessionId,
            response.data!.cashfreePaymentSessionId,
          ]),
        );

        if (orderId.isEmpty || paymentSessionId.isEmpty) {
          Utils.snackBarErrorMessage("Cashfree payment session not available");
          return;
        }

        debugPrint(
          "Cashfree checkout orderId=$orderId sessionLength=${paymentSessionId.length}",
        );

        checkoutLaunched = _openCashfreeCheckout(
          orderId: orderId,
          paymentSessionId: paymentSessionId,
          mode: gatewayKey.mode,
        );
        if (checkoutLaunched) {
          _waitForCheckoutNavigation();
        }
        return;
      }

      if (activeProvider != 'razorpay') {
        Utils.snackBarErrorMessage("Payment gateway is not available");
        return;
      }

      final keyId = gatewayKey.keyId.trim();

      if (keyId.isEmpty) {
        Utils.snackBarErrorMessage("Payment gateway key not available");
        return;
      }

      final orderId = gatewayOrder?.orderId.isNotEmpty == true
          ? gatewayOrder!.orderId
          : response.data!.razorpayOrderId;

      var options = {
        'key': keyId,
        'amount': amountInRupees * 100,
        'name': 'Dude',
        'description': description,
        'order_id': orderId,
        'prefill': {'contact': phoneNumber, 'email': 'user@example.com'},
        'external': {
          'wallets': ['phonepe', 'googlepay', 'paytm', 'amazonpay'],
        },
        'theme': {'color': '#1e0f39'},
      };

      _razorpay.open(options);
      checkoutLaunched = true;
      _waitForCheckoutNavigation();
    } catch (e) {
      Utils.snackBarErrorMessage('Failed to start payment: $e');
    } finally {
      if (!checkoutLaunched) {
        _stopCheckoutLoader();
      }
    }
  }

  bool _openCashfreeCheckout({
    required String orderId,
    required String paymentSessionId,
    required String mode,
  }) {
    try {
      final environment = _cashfreeEnvironment(mode);
      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();
      final payment = CFWebCheckoutPaymentBuilder().setSession(session).build();
      _cashfree.doPayment(payment);
      return true;
    } on CFException catch (e) {
      Utils.snackBarErrorMessage(e.message);
      return false;
    } catch (e) {
      Utils.snackBarErrorMessage("Failed to open Cashfree payment: $e");
      return false;
    }
  }

  void _waitForCheckoutNavigation() {
    _checkoutLoaderFallbackTimer?.cancel();
    _checkoutLoaderFallbackTimer = Timer(
      const Duration(seconds: 6),
      _stopCheckoutLoader,
    );
  }

  void _stopCheckoutLoader() {
    _checkoutLoaderFallbackTimer?.cancel();
    _checkoutLoaderFallbackTimer = null;

    if (!mounted || !_isStartingCheckout) return;
    setState(() => _isStartingCheckout = false);
  }

  CFEnvironment _cashfreeEnvironment(String mode) {
    final normalized = mode.toLowerCase();
    if (normalized.contains('test') || normalized.contains('sandbox')) {
      return CFEnvironment.SANDBOX;
    }
    return CFEnvironment.PRODUCTION;
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  String _sanitizeCashfreeSessionId(String value) {
    var token = value.trim();
    token = token.replaceAll(RegExp(r'\s+'), '');

    final tokenParam = RegExp(r'[?&]token=([^&]+)').firstMatch(token);
    if (tokenParam != null) {
      return Uri.decodeComponent(tokenParam.group(1) ?? '');
    }

    return token;
  }

  void pay(PaymentPackage package) async {
    final userVM = context.read<UserViewModel>();
    final user = userVM.currentUser;

    final success = await PhonePeService.startPayment(
      context: context,
      amountInRupees: int.parse(package.amount.toString()),
      userId: user?.id.toString() ?? "guest",
      mobileNumber: user?.phone ?? "9999999999",
    );

    if (success && mounted) {
      await userVM.fetchUserDetails();
      Navigator.pop(context);
    }
  }

  /// Show Payment Options
  void _showPaymentOptions(PaymentPackage package) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1c122d),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Payment Method",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.payment, color: Color(0xFFe4f773)),
                title: const Text(
                  "Razorpay",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openCheckout(package);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _stopCheckoutLoader();
    final vm = context.read<WalletViewModel>();

    try {
      final confirmResponse = await vm.confirmPaymentAndCreditCoins(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      await _syncBalanceAfterPayment(confirmResponse);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment confirmation failed")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _stopCheckoutLoader();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? 'Unknown'}'),
      ),
    );
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _stopCheckoutLoader();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened external wallet: ${response.walletName}')),
    );
  }

  void _handleCashfreeVerify(String orderId) async {
    _stopCheckoutLoader();
    final vm = context.read<WalletViewModel>();

    try {
      final confirmResponse = await vm.confirmCashfreePaymentAndCreditCoins(
        orderId: orderId,
      );
      await _syncBalanceAfterPayment(confirmResponse);

      if (!mounted) return;
      if (confirmResponse != null) {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment confirmation failed")),
      );
    }
  }

  void _handleCashfreeError(CFErrorResponse errorResponse, String orderId) {
    _stopCheckoutLoader();
    final message = errorResponse.getMessage() ?? 'Unknown';
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Payment Failed: $message')));
  }

  Future<void> _syncBalanceAfterPayment(
    ConfirmPurchaseResponse? confirmResponse,
  ) async {
    final userVM = context.read<UserViewModel>();
    final confirmedBalance = _confirmedBalanceFrom(confirmResponse);

    if (confirmedBalance != null) {
      userVM.updateLocalCoinBalance(confirmedBalance);
    }

    await userVM.fetchUserDetails();

    if (confirmedBalance != null) {
      userVM.updateLocalCoinBalance(confirmedBalance);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.read<UserViewModel>().fetchUserDetails();
    });
  }

  int? _confirmedBalanceFrom(ConfirmPurchaseResponse? response) {
    final data = response?.data;
    if (data == null) return null;

    if (data.newCoinBalance > 0) return data.newCoinBalance;

    final currentBalance = context
        .read<UserViewModel>()
        .currentUser
        ?.coinBalance;
    if (currentBalance != null && data.creditedCoins > 0) {
      return currentBalance + data.creditedCoins;
    }

    return null;
  }

  PaymentPackage? _selectedPackageFrom(List<PaymentPackage> packages) {
    final selectedId = _selectedPackageId;
    if (selectedId == null) return null;

    for (final package in packages) {
      if (package.id == selectedId) return package;
    }
    return null;
  }

  Widget _buildBannerSection(AdBannerViewModel bannerVM) {
    if (bannerVM.isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (bannerVM.error != null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load banner',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => bannerVM.fetchAdBanner(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (bannerVM.hasBanner) {
      return AnimatedScale(
        scale: _isBannerSelected ? 1.02 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutBack,
        child: GestureDetector(
          onTap: () => _selectBannerOffer(bannerVM),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isBannerSelected ? Colors.white : Colors.transparent,
                width: _isBannerSelected ? 2 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isBannerSelected ? Colors.white : Colors.black)
                      .withOpacity(_isBannerSelected ? 0.22 : 0.2),
                  blurRadius: _isBannerSelected ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_isBannerSelected ? 10 : 12),
              child: Image.network(
                bannerVM.bannerImageUrl!,
                fit: BoxFit.fill,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.1),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load banner',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Image.asset(
      "assets/Images/offer.png",
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<WalletViewModel, UserViewModel, AdBannerViewModel>(
      builder: (context, vm, userVM, bannerVM, child) {
        final currentUser = userVM.currentUser;
        final selectedPackage = _selectedPackageFrom(vm.paymentPackages);
        final selectedBanner = _isBannerSelected && bannerVM.hasBanner
            ? bannerVM.bannerData
            : null;
        final hasSelectedOffer =
            selectedPackage != null || selectedBanner != null;
        final isCheckoutBusy = _isStartingCheckout;

        return Scaffold(
          backgroundColor: const Color(0xFF0E0A14),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40), // top
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e), // bottom
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Top bar - same alignment as your old code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2c1e4f,
                                      ), // Updated color
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppText(
                                  "Wallet",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2c1e4f), // Updated
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFe4f773),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    "assets/Images/dude2.png",
                                    height: 25,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${currentUser?.coinBalance ?? 0}.00",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dynamic Banner Section - same as old
                        AbsorbPointer(
                          absorbing: isCheckoutBusy,
                          child: _buildBannerSection(bannerVM),
                        ),

                        const SizedBox(height: 20),

                        // Payment packages grid - same structure
                        if (vm.isLoadingPackages)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (vm.packagesError != null)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    vm.packagesError!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: vm.fetchPaymentStructure,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                    ),
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (vm.paymentPackages.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                "No packages available",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: GridView.builder(
                              padding: EdgeInsets.only(
                                bottom: hasSelectedOffer ? 92 : 0,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 2,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: vm.paymentPackages.length,
                              itemBuilder: (context, index) {
                                final package = vm.paymentPackages[index];
                                final amount = int.parse(
                                  package.amount.toString(),
                                );
                                final hasDiscount =
                                    package.offerStatus == "true" &&
                                    package.offerAmount != "0";
                                final displayPrice = hasDiscount
                                    ? int.parse(package.offerAmount)
                                    : amount;
                                final originalPrice = hasDiscount
                                    ? amount
                                    : null;
                                final isSelected =
                                    _selectedPackageId == package.id;
                                final isPressed =
                                    _pressedPackageId == package.id;

                                return GestureDetector(
                                  onTapDown: isCheckoutBusy
                                      ? null
                                      : (_) => setState(
                                          () => _pressedPackageId = package.id,
                                        ),
                                  onTapCancel: isCheckoutBusy
                                      ? null
                                      : () => setState(
                                          () => _pressedPackageId = null,
                                        ),
                                  onTapUp: isCheckoutBusy
                                      ? null
                                      : (_) => setState(
                                          () => _pressedPackageId = null,
                                        ),
                                  onTap: isCheckoutBusy
                                      ? null
                                      : () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _selectedPackageId = package.id;
                                            _isBannerSelected = false;
                                          });
                                        },
                                  child: AnimatedScale(
                                    scale: isPressed
                                        ? 0.93
                                        : isSelected
                                        ? 1.03
                                        : 1,
                                    duration: Duration(
                                      milliseconds: isPressed ? 90 : 170,
                                    ),
                                    curve: isPressed
                                        ? Curves.easeOut
                                        : Curves.easeOutBack,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Column(
                                          children: [
                                            if (hasDiscount)
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF8e51d2),
                                                          Color(0xFFc450a7),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(12),
                                                      ),
                                                  border: isSelected
                                                      ? const Border(
                                                          top: BorderSide(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                          left: BorderSide(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                          right: BorderSide(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "FLAT ₹$displayPrice OFF",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              const SizedBox(height: 25),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              curve: Curves.easeOut,
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isPressed
                                                      ? const Color(0xFFe4f773)
                                                      : isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF2A1F38),
                                                  width: isPressed || isSelected
                                                      ? 2
                                                      : 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF1c122d),
                                                    Color(0xFF261247),
                                                  ],
                                                ),
                                                boxShadow:
                                                    isPressed || isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color:
                                                              (isPressed
                                                                      ? const Color(
                                                                          0xFFe4f773,
                                                                        )
                                                                      : Colors
                                                                            .white)
                                                                  .withOpacity(
                                                                    0.22,
                                                                  ),
                                                          blurRadius: isPressed
                                                              ? 18
                                                              : 14,
                                                          offset: Offset(
                                                            0,
                                                            isPressed ? 3 : 6,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Image.network(
                                                    package.image,
                                                    height: 40,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => Image.asset(
                                                          "assets/Images/coinglow.png",
                                                          height: 40,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Column(
                                                    children: [
                                                      Text(
                                                        package.coin,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      if (originalPrice != null)
                                                        Text(
                                                          "₹$originalPrice",
                                                          style: const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 11,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            decorationColor:
                                                                Colors.white,
                                                          ),
                                                        ),
                                                      if (originalPrice == null)
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                      Text(
                                                        "₹$displayPrice",
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: hasDiscount
                                                              ? const Color(
                                                                  0xFFd2ea46,
                                                                )
                                                              : Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    if (hasSelectedOffer)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: AnimatedSlide(
                            offset: Offset.zero,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 180),
                              child: GestureDetector(
                                onTap: isCheckoutBusy
                                    ? null
                                    : () {
                                        if (selectedPackage != null) {
                                          _openCheckout(selectedPackage);
                                          return;
                                        }
                                        _openBannerCheckout(bannerVM);
                                      },
                                child: Container(
                                  height: 58,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFe4f773),
                                        Color(0xFFaecc01),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFaecc01,
                                        ).withOpacity(0.38),
                                        blurRadius: 22,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: isCheckoutBusy
                                          ? const Row(
                                              key: ValueKey('checkout-loader'),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.4,
                                                        color: Colors.black,
                                                      ),
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  "Starting payment",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              selectedPackage != null
                                                  ? "Add ${selectedPackage.coin} coins"
                                                  : "Add ${selectedBanner?.purchaseCoins ?? 0} coins",
                                              key: const ValueKey(
                                                'checkout-label',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Loading overlay
                    if (vm.isLoading && !_isStartingCheckout)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
