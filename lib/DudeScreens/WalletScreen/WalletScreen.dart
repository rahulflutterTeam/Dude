// lib/screens/wallet_screen.dart

import 'dart:ui';
import 'package:dude/Analytics/firebase_purchase_events.dart';
import 'package:dude/Analytics/meta_app_events.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/WalletScreen/AdBannerVM/AdBannerVM.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/confirmPaymentModel.dart';
import 'package:dude/DudeScreens/WalletScreen/animated_offer_border.dart';
import 'package:dude/DudeScreens/WalletScreen/coin_checkout_session.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/foundation.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
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

class _WalletScreenState extends State<WalletScreen> {
  late Razorpay _razorpay;
  final CFPaymentGatewayService _cashfree = CFPaymentGatewayService();
  final CoinCheckoutSession _checkoutSession = CoinCheckoutSession();
  String? _selectedPackageId;
  bool _isBannerSelected = false;
  int _pendingPurchaseAmount = 0;
  int _pendingPurchaseCoins = 0;
  String _pendingOrderId = '';
  String _pendingGatewayOrderId = '';
  bool _purchaseEventLogged = false;
  final Set<String> _confirmingOrderIds = <String>{};

  bool get _isCheckoutBusy => _checkoutSession.isActive;

  void _endCheckoutSession() {
    _checkoutSession.end();
    if (mounted) setState(() {});
  }

  int _packageAmountInRupees(PaymentPackage package) {
    return int.parse(
      package.offerAmount.toString() == '0'
          ? package.amount.toString()
          : package.offerAmount.toString(),
    );
  }

  String _continueButtonLabel({
    required PaymentPackage? selectedPackage,
    required dynamic selectedBanner,
  }) {
    if (_isCheckoutBusy) return 'Please wait...';
    return 'Buy Now';
  }

  @override
  void initState() {
    super.initState();

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
    _razorpay.clear();
    super.dispose();
  }

  /// Razorpay checkout
  void _openCheckout(PaymentPackage package) {
    final amountInRupees = _packageAmountInRupees(package);
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
    MetaAppEvents.viewCoinPackage(
      coins: banner.purchaseCoins,
      amount: banner.amount,
    );
    FirebasePurchaseEvents.view(banner.purchaseCoins, banner.amount);
    setState(() {
      _isBannerSelected = true;
      _selectedPackageId = null;
    });
  }

  Future<void> _openCheckoutForValues({
    required int amountInRupees,
    required int coins,
    required String description,
  }) async {
    if (!_checkoutSession.tryStart()) return;
    setState(() {});

    final vm = context.read<WalletViewModel>();
    final userVM = context.read<UserViewModel>();
    final phoneNumber = userVM.currentUser?.phone ?? "";

    var gatewayOpened = false;

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

      _pendingPurchaseAmount = amountInRupees;
      _pendingPurchaseCoins = coins;
      _pendingOrderId = response!.data!.id;
      _pendingGatewayOrderId = '';
      _purchaseEventLogged = false;
      MetaAppEvents.initiateCoinCheckout(
        coins: coins,
        amount: amountInRupees,
        orderId: _pendingOrderId,
      );
      FirebasePurchaseEvents.checkout(coins, amountInRupees, _pendingOrderId);

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
        _pendingGatewayOrderId = orderId;

        debugPrint(
          "Cashfree checkout orderId=$orderId sessionLength=${paymentSessionId.length}",
        );

        gatewayOpened = _openCashfreeCheckout(
          orderId: orderId,
          paymentSessionId: paymentSessionId,
          mode: gatewayKey.mode,
        );
        if (gatewayOpened) {
          _checkoutSession.markGatewayLaunched();
          if (mounted) setState(() {});
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
      if (orderId.isEmpty) {
        Utils.snackBarErrorMessage("Payment order is not available");
        return;
      }
      _pendingGatewayOrderId = orderId;

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
      gatewayOpened = true;
      _checkoutSession.markGatewayLaunched();
      if (mounted) setState(() {});
    } catch (e) {
      Utils.snackBarErrorMessage('Failed to start payment: $e');
    } finally {
      if (!gatewayOpened) {
        _endCheckoutSession();
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final vm = context.read<WalletViewModel>();
    final orderId = _firstNonEmpty([
      response.orderId,
      _pendingGatewayOrderId,
      _pendingOrderId,
    ]);
    if (orderId.isEmpty || !_confirmingOrderIds.add(orderId)) return;
    var confirmed = false;

    try {
      final confirmResponse = await vm.confirmPaymentAndCreditCoins(
        orderId: orderId,
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      if (confirmResponse?.status != true) return;
      confirmed = true;
      _logConfirmedPurchase(confirmResponse);
      await _syncBalanceAfterPayment(confirmResponse);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment confirmation failed")),
      );
    } finally {
      if (!confirmed) _confirmingOrderIds.remove(orderId);
      _endCheckoutSession();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _endCheckoutSession();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? 'Unknown'}'),
      ),
    );
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _endCheckoutSession();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened external wallet: ${response.walletName}')),
    );
  }

  void _handleCashfreeVerify(String orderId) async {
    final vm = context.read<WalletViewModel>();
    final resolvedOrderId = orderId.trim().isNotEmpty
        ? orderId.trim()
        : _pendingGatewayOrderId;
    if (resolvedOrderId.isEmpty || !_confirmingOrderIds.add(resolvedOrderId)) {
      return;
    }
    var confirmed = false;

    try {
      final confirmResponse = await vm.confirmCashfreePaymentAndCreditCoins(
        orderId: resolvedOrderId,
      );
      if (confirmResponse?.status != true) return;
      confirmed = true;
      _logConfirmedPurchase(confirmResponse);
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
    } finally {
      if (!confirmed) _confirmingOrderIds.remove(resolvedOrderId);
      _endCheckoutSession();
    }
  }

  void _handleCashfreeError(CFErrorResponse errorResponse, String orderId) {
    _endCheckoutSession();
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

  void _logConfirmedPurchase(ConfirmPurchaseResponse? response) {
    if (response == null ||
        !response.status ||
        _purchaseEventLogged ||
        _pendingPurchaseAmount <= 0)
      return;
    _purchaseEventLogged = true;
    final credited = response.data?.creditedCoins ?? 0;
    final creditedCoins = credited > 0 ? credited : _pendingPurchaseCoins;
    final orderId = response.data?.orderId ?? _pendingOrderId;
    FirebasePurchaseEvents.purchase(
      creditedCoins,
      _pendingPurchaseAmount,
      orderId,
    );
    MetaAppEvents.purchaseCoins(
      coins: creditedCoins,
      amount: _pendingPurchaseAmount,
      orderId: orderId,
    );
  }

  PaymentPackage? _selectedPackageFrom(List<PaymentPackage> packages) {
    final selectedId = _selectedPackageId;
    if (selectedId == null) return null;

    for (final package in packages) {
      if (package.id == selectedId) return package;
    }
    return null;
  }

  Widget _buildTopBar(int balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: DudeTheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DudeTheme.border.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: DudeTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Add Coins',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: DudeTheme.accentDim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DudeTheme.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: Transform.scale(
                      scale: 1.4,
                      child: Image.asset(
                        'assets/Images/dudecoin.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$balance',
                  style: const TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: DudeTheme.textMuted.withValues(alpha: 0.95),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageStrip({
    required List<PaymentPackage> packages,
    required bool isCheckoutBusy,
  }) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final package = packages[index];
          final isSelected = _selectedPackageId == package.id;
          final amount = int.parse(package.amount.toString());
          final hasDiscount =
              package.offerStatus == 'true' && package.offerAmount != '0';
          final displayPrice = hasDiscount
              ? int.parse(package.offerAmount)
              : amount;
          final packageCoins = int.tryParse(package.coin) ?? 0;
          final talkTimeMinutes = packageCoins ~/ 20;

          return GestureDetector(
            onTap: isCheckoutBusy
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedPackageId = package.id;
                      _isBannerSelected = false;
                    });
                  },
            child: _wrapOfferBorder(
              enabled: hasDiscount,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 104,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? DudeTheme.premiumAccentGradient
                      : LinearGradient(
                          colors: [
                            DudeTheme.surface.withValues(alpha: 0.95),
                            DudeTheme.surfaceRaised.withValues(alpha: 0.85),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? DudeTheme.accent
                        : DudeTheme.border.withValues(alpha: 0.7),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? DudeTheme.accentGlowShadow(blur: 14, spread: -6)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DudeTheme.textOnAccent.withValues(alpha: 0.2)
                              : DudeTheme.accentDim,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'OFFER',
                          style: TextStyle(
                            color: isSelected
                                ? DudeTheme.textOnAccent
                                : DudeTheme.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Image.network(
                      package.image,
                      height: 32,
                      errorBuilder: (_, __, ___) =>
                          Image.asset('assets/Images/dudecoin.jpg', height: 32),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.coin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? DudeTheme.textOnAccent
                            : DudeTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$displayPrice',
                      style: TextStyle(
                        color: isSelected
                            ? DudeTheme.textOnAccent.withValues(alpha: 0.9)
                            : DudeTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      talkTimeMinutes > 0
                          ? '$talkTimeMinutes ${talkTimeMinutes == 1 ? 'min' : 'mins'} talktime'
                          : 'Under 1 min talktime',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? DudeTheme.textOnAccent.withValues(alpha: 0.85)
                            : DudeTheme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageGrid({
    required List<PaymentPackage> packages,
    required bool isCheckoutBusy,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.56,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        final isSelected = _selectedPackageId == package.id;
        final amount = int.tryParse(package.amount.toString()) ?? 0;
        final hasDiscount =
            package.offerStatus == 'true' && package.offerAmount != '0';
        final displayPrice = hasDiscount
            ? int.tryParse(package.offerAmount) ?? amount
            : amount;
        final coins = int.tryParse(package.coin) ?? 0;
        final talkTimeMinutes = coins ~/ 20;

        final label = hasDiscount
            ? 'SAVE ₹${(amount - displayPrice).clamp(0, amount)}'
            : index == 7
            ? 'BEST SELLER'
            : 'VALUE PACK';

        return GestureDetector(
          onTap: isCheckoutBusy
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  FirebasePurchaseEvents.view(coins, displayPrice);
                  MetaAppEvents.viewCoinPackage(
                    coins: coins,
                    amount: displayPrice,
                  );
                  setState(() {
                    _selectedPackageId = package.id;
                    _isBannerSelected = false;
                  });
                },
          child: AnimatedScale(
            scale: isSelected ? 1.025 : 1,
            duration: const Duration(milliseconds: 180),
            child: Container(
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? DudeTheme.accentBright : DudeTheme.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? DudeTheme.accentGlowShadow(blur: 18, spread: -5)
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DudeTheme.accent
                          : DudeTheme.accentDim,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? DudeTheme.textOnAccent
                            : DudeTheme.accentBright,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    package.coin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DudeTheme.accentBright,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Image.network(
                        package.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/Images/dudecoin.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DudeTheme.accentBright,
                          DudeTheme.accent,
                          DudeTheme.accentDeep,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DudeTheme.accentDeep.withValues(alpha: 0.55),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            '₹$amount',
                            style: TextStyle(
                              color: DudeTheme.textOnAccent.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: DudeTheme.textOnAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '₹$displayPrice',
                          style: const TextStyle(
                            color: DudeTheme.textOnAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Text(
                      talkTimeMinutes > 0
                          ? 'Talktime $talkTimeMinutes ${talkTimeMinutes == 1 ? 'min' : 'mins'}'
                          : 'Talktime under 1 min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: DudeTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionSummary({
    required PaymentPackage? selectedPackage,
    required dynamic selectedBanner,
  }) {
    if (selectedPackage == null && selectedBanner == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PremiumGlassCard(
          padding: const EdgeInsets.all(24),
          radius: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_rounded,
                color: DudeTheme.textSubtle.withValues(alpha: 0.8),
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'Swipe to pick a pack',
                style: TextStyle(
                  color: DudeTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your selection and price will show here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DudeTheme.textMuted.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final coins = selectedPackage != null
        ? selectedPackage.coin
        : '${selectedBanner?.purchaseCoins ?? 0}';
    final amount = selectedPackage != null
        ? int.parse(selectedPackage.amount.toString())
        : selectedBanner?.amount as int? ?? 0;
    final hasDiscount =
        selectedPackage != null &&
        selectedPackage.offerStatus == 'true' &&
        selectedPackage.offerAmount != '0';
    final displayPrice = selectedPackage != null
        ? (hasDiscount ? int.parse(selectedPackage.offerAmount) : amount)
        : amount;
    final image = selectedPackage?.image;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumGlassCard(
        glow: true,
        padding: const EdgeInsets.all(20),
        radius: 22,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Image.network(
                image,
                height: 72,
                errorBuilder: (_, __, ___) =>
                    Image.asset('assets/Images/dudecoin.jpg', height: 72),
              )
            else
              Image.asset('assets/Images/dudecoin.jpg', height: 72),
            const SizedBox(height: 14),
            Text(
              '$coins coins',
              style: const TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedPackage != null
                  ? 'Coin pack selected'
                  : 'Special offer selected',
              style: TextStyle(
                color: DudeTheme.textMuted.withValues(alpha: 0.95),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount) ...[
                  Text(
                    '₹$amount',
                    style: TextStyle(
                      color: DudeTheme.textSubtle.withValues(alpha: 0.85),
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '₹$displayPrice',
                  style: const TextStyle(
                    color: DudeTheme.accent,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (hasDiscount) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DudeTheme.accentDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'You save ₹${amount - displayPrice}',
                  style: const TextStyle(
                    color: DudeTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _wrapOfferBorder({required bool enabled, required Widget child}) {
    if (!enabled) return child;
    return AnimatedOfferBorder(
      borderRadius: 18,
      borderWidth: 2.5,
      child: child,
    );
  }

  Widget _buildCoinRateInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: DudeTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DudeTheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _coinRateTile(
                    icon: Icons.call_rounded,
                    iconColor: DudeTheme.accent,
                    coins: '20 coins',
                    label: '1 min audio call',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: DudeTheme.border.withValues(alpha: 0.6),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _coinRateTile(
                    icon: Icons.videocam_rounded,
                    iconColor: DudeTheme.accentBright,
                    coins: '60 coins',
                    label: '1 min video call',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: DudeTheme.border.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: DudeTheme.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '100% secure payments',
                  style: TextStyle(
                    color: DudeTheme.textMuted.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinRateTile({
    required IconData icon,
    required Color iconColor,
    required String coins,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                coins,
                style: const TextStyle(
                  color: DudeTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: DudeTheme.textMuted.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBlockingOverlay() {
    if (!_checkoutSession.blockInteraction) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: AbsorbPointer(
        child: AnimatedOpacity(
          opacity: _checkoutSession.showBlockingLoader ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Container(
            color: DudeTheme.background.withValues(alpha: 0.72),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: DudeTheme.accent,
                  ),
                ),
                if (_checkoutSession.showBlockingLoader) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Opening secure payment...',
                    style: TextStyle(
                      color: DudeTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection(AdBannerViewModel bannerVM) {
    if (bannerVM.isLoading) {
      return PremiumGlassCard(
        padding: EdgeInsets.zero,
        radius: 18,
        child: SizedBox(
          height: 110,
          child: Center(
            child: CircularProgressIndicator(
              color: DudeTheme.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (bannerVM.error != null) {
      return PremiumGlassCard(
        padding: const EdgeInsets.all(16),
        radius: 18,
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: DudeTheme.danger,
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              'Could not load offer',
              style: TextStyle(color: DudeTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => bannerVM.fetchAdBanner(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DudeTheme.accentDim,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DudeTheme.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: DudeTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (bannerVM.hasBanner) {
      return GestureDetector(
        onTap: () => _selectBannerOffer(bannerVM),
        child: AnimatedOfferBorder(
          borderRadius: 18,
          borderWidth: 2.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isBannerSelected
                    ? DudeTheme.accent
                    : DudeTheme.border.withValues(alpha: 0.5),
                width: _isBannerSelected ? 2 : 1,
              ),
              boxShadow: _isBannerSelected
                  ? DudeTheme.accentGlowShadow(blur: 16, spread: -6)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_isBannerSelected ? 16 : 17),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Image.network(
                      bannerVM.bannerImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: DudeTheme.surface,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: DudeTheme.accent,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: DudeTheme.surface,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: DudeTheme.textSubtle,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isBannerSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: DudeTheme.premiumAccentGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            color: DudeTheme.textOnAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/Images/offer.png',
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCheckoutBar({
    required bool isCheckoutBusy,
    required bool hasSelection,
    required String continueLabel,
    required PaymentPackage? selectedPackage,
    required dynamic selectedBanner,
    required AdBannerViewModel bannerVM,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Secure payment via Razorpay & Cashfree',
              style: TextStyle(
                color: DudeTheme.textSubtle.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: !hasSelection || isCheckoutBusy
                  ? null
                  : () {
                      if (selectedPackage != null) {
                        _openCheckout(selectedPackage);
                        return;
                      }
                      _openBannerCheckout(bannerVM);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 54,
                decoration: BoxDecoration(
                  gradient: hasSelection
                      ? DudeTheme.premiumAccentGradient
                      : LinearGradient(
                          colors: [DudeTheme.surfaceRaised, DudeTheme.surface],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasSelection
                        ? DudeTheme.accent.withValues(alpha: 0.5)
                        : DudeTheme.border,
                  ),
                  boxShadow: hasSelection
                      ? DudeTheme.accentGlowShadow(blur: 16, spread: -6)
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isCheckoutBusy
                        ? const Row(
                            key: ValueKey('checkout-loader'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: DudeTheme.textOnAccent,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Starting payment…',
                                style: TextStyle(
                                  color: DudeTheme.textOnAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            hasSelection
                                ? continueLabel
                                : 'Select a pack to continue',
                            key: const ValueKey('checkout-label'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hasSelection
                                  ? DudeTheme.textOnAccent
                                  : DudeTheme.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _packageDisplayPrice(PaymentPackage package) {
    final amount = int.parse(package.amount.toString());
    final hasDiscount =
        package.offerStatus == 'true' && package.offerAmount != '0';
    return hasDiscount ? int.parse(package.offerAmount) : amount;
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
        final isCheckoutBusy = _isCheckoutBusy;
        final continueLabel = _continueButtonLabel(
          selectedPackage: selectedPackage,
          selectedBanner: selectedBanner,
        );

        return PopScope(
          canPop: !_isCheckoutBusy,
          child: Scaffold(
            backgroundColor: DudeTheme.background,
            body: PremiumAmbientBackground(
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(currentUser?.coinBalance ?? 0),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AbsorbPointer(
                            absorbing: isCheckoutBusy,
                            child: _buildBannerSection(bannerVM),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (vm.isLoadingPackages)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DudeTheme.accent,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (vm.packagesError != null)
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_outlined,
                                      color: DudeTheme.textSubtle,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      vm.packagesError!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: DudeTheme.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: vm.fetchPaymentStructure,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              DudeTheme.premiumAccentGradient,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: const Text(
                                          'Retry',
                                          style: TextStyle(
                                            color: DudeTheme.textOnAccent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else if (vm.paymentPackages.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'No packages available',
                                style: TextStyle(color: DudeTheme.textMuted),
                              ),
                            ),
                          )
                        else ...[
                          _buildSectionHeader(
                            title: 'Gold Shop',
                            subtitle:
                                'Choose the best value pack for your calls',
                          ),
                          Expanded(
                            child: _buildPackageGrid(
                              packages: vm.paymentPackages,
                              isCheckoutBusy: isCheckoutBusy,
                            ),
                          ),
                        ],
                        if (hasSelectedOffer)
                          _buildCheckoutBar(
                            isCheckoutBusy: isCheckoutBusy,
                            hasSelection: hasSelectedOffer,
                            continueLabel: continueLabel,
                            selectedPackage: selectedPackage,
                            selectedBanner: selectedBanner,
                            bannerVM: bannerVM,
                          ),
                      ],
                    ),
                    _buildCheckoutBlockingOverlay(),
                    if (vm.isLoading && !_isCheckoutBusy)
                      Container(
                        color: DudeTheme.background.withValues(alpha: 0.55),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: DudeTheme.accent,
                            strokeWidth: 2,
                          ),
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
