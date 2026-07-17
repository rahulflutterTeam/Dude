import 'dart:async';

import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/confirmPaymentModel.dart';
import 'package:dude/DudeScreens/WalletScreen/coin_checkout_session.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class InCallAddCoinSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InCallAddCoinSheetBody(),
    );
  }
}

class _InCallAddCoinSheetBody extends StatefulWidget {
  const _InCallAddCoinSheetBody();

  @override
  State<_InCallAddCoinSheetBody> createState() => _InCallAddCoinSheetBodyState();
}

class _InCallAddCoinSheetBodyState extends State<_InCallAddCoinSheetBody> {
  late Razorpay _razorpay;
  final CFPaymentGatewayService _cashfree = CFPaymentGatewayService();
  final CoinCheckoutSession _checkoutSession = CoinCheckoutSession();
  int _pendingPackageCoins = 0;

  bool get _isCheckoutBusy => _checkoutSession.isActive;

  void _endCheckoutSession() {
    _checkoutSession.end();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _cashfree.setCallback(_handleCashfreeVerify, _handleCashfreeError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WalletViewModel>().fetchPaymentStructure();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _buyPackage(PaymentPackage package) async {
    final amountInRupees = int.parse(
      package.offerAmount.toString() == '0'
          ? package.amount.toString()
          : package.offerAmount.toString(),
    );
    final coins = int.tryParse(package.coin) ?? 0;
    if (coins <= 0) {
      Utils.snackBarErrorMessage('Invalid coin package');
      return;
    }

    _pendingPackageCoins = coins;
    await _openCheckout(
      amountInRupees: amountInRupees,
      coins: coins,
      description: '${package.coin} Coins Package',
    );
  }

  Future<void> _openCheckout({
    required int amountInRupees,
    required int coins,
    required String description,
  }) async {
    if (!_checkoutSession.tryStart()) return;
    setState(() {});

    final vm = context.read<WalletViewModel>();
    final userVM = context.read<UserViewModel>();
    final phoneNumber = userVM.currentUser?.phone ?? '';
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
          Utils.snackBarErrorMessage('Cashfree payment session not available');
          return;
        }

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
        Utils.snackBarErrorMessage('Payment gateway is not available');
        return;
      }

      final keyId = gatewayKey.keyId.trim();
      if (keyId.isEmpty) {
        Utils.snackBarErrorMessage('Payment gateway key not available');
        return;
      }

      final orderId = gatewayOrder?.orderId.isNotEmpty == true
          ? gatewayOrder!.orderId
          : response.data!.razorpayOrderId;

      _razorpay.open({
        'key': keyId,
        'amount': amountInRupees * 100,
        'name': 'PairEver',
        'description': description,
        'order_id': orderId,
        'prefill': {'contact': phoneNumber, 'email': 'user@example.com'},
        'external': {
          'wallets': ['phonepe', 'googlepay', 'paytm', 'amazonpay'],
        },
        'theme': {'color': '#1e0f39'},
      });
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
      Utils.snackBarErrorMessage('Failed to open Cashfree payment: $e');
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
    _endCheckoutSession();
    final vm = context.read<WalletViewModel>();

    try {
      final confirmResponse = await vm.confirmPaymentAndCreditCoins(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      await _applyTopUp(confirmResponse);
    } catch (_) {
      if (!mounted) return;
      Utils.snackBarErrorMessage('Payment confirmation failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _endCheckoutSession();
    Utils.snackBarErrorMessage(
      'Payment failed: ${response.message ?? 'Unknown'}',
    );
  }

  void _handleCashfreeVerify(String orderId) async {
    _endCheckoutSession();
    final vm = context.read<WalletViewModel>();

    try {
      final confirmResponse = await vm.confirmCashfreePaymentAndCreditCoins(
        orderId: orderId,
      );
      await _applyTopUp(confirmResponse);
    } catch (_) {
      if (!mounted) return;
      Utils.snackBarErrorMessage('Payment confirmation failed');
    }
  }

  void _handleCashfreeError(CFErrorResponse errorResponse, String orderId) {
    _endCheckoutSession();
    Utils.snackBarErrorMessage(
      'Payment failed: ${errorResponse.getMessage() ?? 'Unknown'}',
    );
  }

  Future<void> _applyTopUp(ConfirmPurchaseResponse? confirmResponse) async {
    if (!mounted) return;
    if (confirmResponse == null || !confirmResponse.status) return;

    final userVM = context.read<UserViewModel>();
    final creditedCoins = _creditedCoinsFrom(confirmResponse);
    final newBalance = _confirmedBalanceFrom(confirmResponse, userVM);

    if (newBalance != null) {
      userVM.updateLocalCoinBalance(newBalance);
    }

    final coinsToApply = creditedCoins > 0 ? creditedCoins : _pendingPackageCoins;
    if (coinsToApply > 0) {
      CallService().extendCallWithAddedCoins(coinsToApply);
    }

    await userVM.fetchUserDetails();

    if (!mounted) return;
    Navigator.of(context).pop();

    final addedMinutes = CallService.secondsForCoinAmount(
      coinsToApply,
      CallService().currentCallPricePerMin ?? 0,
    );
    final mins = addedMinutes ~/ 60;
    final secs = addedMinutes % 60;
    final timeLabel = mins > 0
        ? '${mins}m ${secs.toString().padLeft(2, '0')}s'
        : '${secs}s';

    Utils.snackBar(
      coinsToApply > 0
          ? '$coinsToApply coins added! +$timeLabel call time'
          : 'Coins added successfully',
    );
  }

  int _creditedCoinsFrom(ConfirmPurchaseResponse response) {
    final credited = response.data?.creditedCoins ?? 0;
    if (credited > 0) return credited;
    return _pendingPackageCoins;
  }

  int? _confirmedBalanceFrom(
    ConfirmPurchaseResponse response,
    UserViewModel userVM,
  ) {
    final data = response.data;
    if (data == null) return null;
    if (data.newCoinBalance > 0) return data.newCoinBalance;

    final currentBalance = userVM.currentUser?.coinBalance;
    if (currentBalance != null && data.creditedCoins > 0) {
      return currentBalance + data.creditedCoins;
    }
    return null;
  }

  String _formatAddedTime(int coins, int pricePerMin) {
    final seconds = CallService.secondsForCoinAmount(coins, pricePerMin);
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins <= 0) return '+${secs}s';
    return '+${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final pricePerMin = CallService().currentCallPricePerMin ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Stack(
        children: [
          Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1426),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Color(0xFFD2EA46), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Stay on call — time extends instantly',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isCheckoutBusy
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Consumer<WalletViewModel>(
                  builder: (context, vm, _) {
                    if (vm.isLoading && vm.paymentPackages.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFD2EA46),
                          ),
                        ),
                      );
                    }

                    final packages = vm.paymentPackages;
                    if (packages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No packages available',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: vm.fetchPaymentStructure,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: packages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final package = packages[index];
                        final coins = int.tryParse(package.coin) ?? 0;
                        final amount = package.offerAmount.toString() == '0'
                            ? package.amount
                            : int.tryParse(package.offerAmount) ??
                                  package.amount;
                        final extraTime = pricePerMin > 0
                            ? _formatAddedTime(coins, pricePerMin)
                            : '';

                        return Material(
                          color: const Color(0xFF2A1F38),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isCheckoutBusy
                                ? null
                                : () => _buyPackage(package),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/Images/paircoin.png',
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.monetization_on,
                                      color: Color(0xFFD2EA46),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$coins Coins',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (extraTime.isNotEmpty)
                                          Text(
                                            '$extraTime call time',
                                            style: const TextStyle(
                                              color: Color(0xFFD2EA46),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹$amount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (_isCheckoutBusy) ...[
                                    const SizedBox(width: 10),
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFD2EA46),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
          if (_checkoutSession.blockInteraction)
            Positioned.fill(
              child: AbsorbPointer(
                child: AnimatedOpacity(
                  opacity: _checkoutSession.showBlockingLoader ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFFD2EA46),
                          ),
                        ),
                        if (_checkoutSession.showBlockingLoader) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Opening secure payment...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
