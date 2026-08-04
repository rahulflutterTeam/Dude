import 'dart:async';

import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/DudeScreens/HomeScreen/in_call_add_coin_sheet.dart';
import 'package:dude/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CallBalanceOverlayData {
  const CallBalanceOverlayData({
    required this.initialBalance,
    required this.pricePerMin,
    required this.maxSeconds,
    this.syncedElapsedSeconds = 0,
  });

  const CallBalanceOverlayData.empty()
    : initialBalance = 0,
      pricePerMin = 0,
      maxSeconds = 0,
      syncedElapsedSeconds = 0;

  final int initialBalance;
  final int pricePerMin;
  final int maxSeconds;
  final int syncedElapsedSeconds;
}

class CallBalanceOverlay extends StatefulWidget {
  const CallBalanceOverlay.user({super.key})
    : initialBalance = null,
      pricePerMin = null,
      maxSeconds = null,
      dataListenable = null,
      showAddCoinButton = true,
      useCallService = true;

  const CallBalanceOverlay.static({
    super.key,
    required this.initialBalance,
    required this.pricePerMin,
    required this.maxSeconds,
    this.showAddCoinButton = false,
  }) : dataListenable = null,
       useCallService = false;

  const CallBalanceOverlay.listenable({
    super.key,
    required this.dataListenable,
    this.showAddCoinButton = false,
  }) : initialBalance = null,
       pricePerMin = null,
       maxSeconds = null,
       useCallService = false;

  final int? initialBalance;
  final int? pricePerMin;
  final int? maxSeconds;
  final ValueListenable<CallBalanceOverlayData>? dataListenable;
  final bool showAddCoinButton;
  final bool useCallService;

  @override
  State<CallBalanceOverlay> createState() => _CallBalanceOverlayState();
}

class _CallBalanceOverlayState extends State<CallBalanceOverlay> {
  final CallService _callService = CallService();
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.useCallService) {
      _callService.addListener(_handleCallServiceChanged);
    } else {
      widget.dataListenable?.addListener(_handleDataListenableChanged);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds++);
      });
    }
  }

  @override
  void dispose() {
    if (widget.useCallService) {
      _callService.removeListener(_handleCallServiceChanged);
    } else {
      widget.dataListenable?.removeListener(_handleDataListenableChanged);
    }
    _timer?.cancel();
    super.dispose();
  }

  void _handleDataListenableChanged() {
    final data = widget.dataListenable?.value;
    if (data == null || data.syncedElapsedSeconds <= 0) return;
    if (!mounted) return;
    setState(() {
      if (data.syncedElapsedSeconds > _elapsedSeconds) {
        _elapsedSeconds = data.syncedElapsedSeconds;
      }
    });
  }

  void _handleCallServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int initialBalance;
    final int pricePerMin;
    final int remainingSeconds;
    final int remainingBalance;

    if (widget.dataListenable != null) {
      return ValueListenableBuilder<CallBalanceOverlayData>(
        valueListenable: widget.dataListenable!,
        builder: (context, data, child) {
          return _buildOverlay(
            context: context,
            initialBalance: data.initialBalance,
            pricePerMin: data.pricePerMin,
            remainingSeconds: _remainingSeconds(
              maxSeconds: data.maxSeconds,
              elapsedSeconds: _elapsedSeconds,
            ),
            remainingBalance: _remainingBalance(
              initialBalance: data.initialBalance,
              pricePerMin: data.pricePerMin,
              elapsedSeconds: _elapsedSeconds,
            ),
          );
        },
      );
    } else if (widget.useCallService) {
      initialBalance = _callService.initialCoinBalance;
      pricePerMin = _callService.currentCallPricePerMin ?? 0;
      remainingSeconds = _callService.remainingCallSeconds;
      remainingBalance = _callService.estimatedRemainingBalance;
    } else {
      initialBalance = widget.initialBalance ?? 0;
      pricePerMin = widget.pricePerMin ?? 0;
      final maxSeconds = widget.maxSeconds ?? 0;
      remainingSeconds = _remainingSeconds(
        maxSeconds: maxSeconds,
        elapsedSeconds: _elapsedSeconds,
      );
      remainingBalance = _remainingBalance(
        initialBalance: initialBalance,
        pricePerMin: pricePerMin,
        elapsedSeconds: _elapsedSeconds,
      );
    }

    return _buildOverlay(
      context: context,
      initialBalance: initialBalance,
      pricePerMin: pricePerMin,
      remainingSeconds: remainingSeconds,
      remainingBalance: remainingBalance,
    );
  }

  int _remainingSeconds({
    required int maxSeconds,
    required int elapsedSeconds,
  }) {
    return (maxSeconds - elapsedSeconds).clamp(0, maxSeconds);
  }

  int _remainingBalance({
    required int initialBalance,
    required int pricePerMin,
    required int elapsedSeconds,
  }) {
    final spent = CallService.calculateSpentCoins(
      durationSeconds: elapsedSeconds,
      pricePerMin: pricePerMin,
    );
    return (initialBalance - spent).clamp(0, initialBalance);
  }

  Widget _buildOverlay({
    required BuildContext context,
    required int initialBalance,
    required int pricePerMin,
    required int remainingSeconds,
    required int remainingBalance,
  }) {
    if (initialBalance <= 0 && pricePerMin <= 0) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x9E000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD2EA46), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InfoPill(
                    icon: 'assets/Images/dudecoin.jpg',
                    label: '${remainingBalance.clamp(0, initialBalance)}',
                  ),
                  const SizedBox(width: 8),
                  _InfoPill(
                    icon: 'assets/Images/time.png',
                    label: _formatDuration(remainingSeconds),
                  ),
                  if (widget.showAddCoinButton) ...[
                    const SizedBox(width: 8),
                    _AddCoinButton(
                      onTap: () {
                        final sheetContext =
                            navigatorKey.currentContext ?? context;
                        InCallAddCoinSheet.show(sheetContext);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, height: 18, width: 18),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AddCoinButton extends StatelessWidget {
  const _AddCoinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFD2EA46),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Add Coin',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
