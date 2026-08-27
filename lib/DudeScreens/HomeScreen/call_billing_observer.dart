import 'dart:async';

import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CallBillingObserver extends StatefulWidget {
  const CallBillingObserver({super.key, required this.child});

  final Widget child;

  @override
  State<CallBillingObserver> createState() => _CallBillingObserverState();
}

class _CallBillingObserverState extends State<CallBillingObserver>
    with WidgetsBindingObserver {
  StreamSubscription<Map<String, dynamic>>? _endSubscription;
  StreamSubscription<Map<String, dynamic>>? _minuteSubscription;
  final Set<String> _processedCallKeys = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final callService = CallService();
    _endSubscription = callService.onCallEnded.listen(_handleBillingEvent);
    _minuteSubscription =
        callService.onCallMinuteCharge.listen(_handleBillingEvent);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flush minute charges + ensure out-of-coins ends still report when
    // Android backgrounds / kills the UI timer.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final callService = CallService();
      if (!callService.isCallActive || !callService.wasCallReallyConnected) {
        return;
      }
      callService.flushPendingMinuteCharges();
      if (callService.remainingCallSeconds <= 0) {
        callService.endCall(endReason: 'out_of_coins');
      }
    }
  }

  Future<void> _handleBillingEvent(Map<String, dynamic> callData) async {
    if (!mounted) return;

    final staffId = callData['staffId']?.toString() ?? '';
    final callID = callData['callID']?.toString();
    final spent = (callData['spent'] as num?)?.toInt() ?? 0;
    final durationSeconds = (callData['durationSeconds'] as num?)?.toInt() ?? 0;
    final isVideo = callData['isVideoCall'] == true;
    final incremental = callData['incremental'] == true;
    final alreadyBilled = callData['alreadyBilled'] == true;
    final outOfCoins = callData['outOfCoins'] == true;
    final billedSeconds = (callData['billedSeconds'] as num?)?.toInt();
    final totalDurationSeconds =
        (callData['totalDurationSeconds'] as num?)?.toInt();

    if (outOfCoins && mounted) {
      Utils.snackBar('Call ended — out of coins.');
    }

    if (alreadyBilled || staffId.isEmpty || spent <= 0 || durationSeconds <= 0) {
      if (alreadyBilled) {
        debugPrint('End event already covered by minute charges: $callData');
        // Still refresh balances so staff/user wallets catch up after video.
        final userVM = context.read<UserViewModel>();
        await userVM.fetchUserDetails();
      } else {
        debugPrint('Skipping invalid billing event: $callData');
      }
      return;
    }

    final billedKey = billedSeconds?.toString() ?? '';
    final eventKey = callID?.isNotEmpty == true
        ? (incremental
              ? '$callID-min-$billedKey-$spent'
              : '$callID-end-$durationSeconds-$spent')
        : '$staffId-$durationSeconds-$spent-${incremental ? 'm' : 'e'}';
    if (!_processedCallKeys.add(eventKey)) {
      debugPrint('Skipping duplicate billing event: $eventKey');
      return;
    }

    final userVM = context.read<UserViewModel>();
    if (userVM.currentUser == null) {
      await userVM.fetchUserDetails();
    }

    final currentBalance = userVM.currentUser?.coinBalance ?? 0;
    final newBalance = (currentBalance - spent).clamp(0, currentBalance);

    debugPrint(
      'Billing ${incremental ? 'minute' : 'end'} $eventKey: '
      '$currentBalance -> $newBalance, spent: $spent, duration: ${durationSeconds}s '
      'video=$isVideo',
    );

    final success = await userVM.updateUserCoinBalance(
      newBalance,
      staffId,
      spent,
      durationSeconds.toString(),
      isVideo ? 'video' : 'audio',
      callID,
      incremental,
      billedSeconds,
      incremental ? null : totalDurationSeconds,
    );

    if (success || userVM.lastBalanceUpdateQueued) {
      // Only mark confirmed when the API accepted the charge (not queued-only),
      // so a failed video minute cannot wipe the end settlement.
      if (success) {
        CallService().confirmServerBilling(
          spentCoins: spent,
          durationSeconds: durationSeconds,
          callID: callID,
        );
      }
      if (!incremental) {
        await userVM.fetchUserDetails();
      }
    } else if (incremental) {
      // Keep hangup settlement able to cover this minute.
      CallService().revokeEmittedBilling(
        spentCoins: spent,
        durationSeconds: durationSeconds,
      );
      _processedCallKeys.remove(eventKey);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endSubscription?.cancel();
    _minuteSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
