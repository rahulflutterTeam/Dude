import 'dart:async';

import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CallBillingObserver extends StatefulWidget {
  const CallBillingObserver({super.key, required this.child});

  final Widget child;

  @override
  State<CallBillingObserver> createState() => _CallBillingObserverState();
}

class _CallBillingObserverState extends State<CallBillingObserver> {
  StreamSubscription<Map<String, dynamic>>? _subscription;
  final Set<String> _processedCallKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _subscription = CallService().onCallEnded.listen(_handleCallEnded);
  }

  Future<void> _handleCallEnded(Map<String, dynamic> callData) async {
    if (!mounted) return;

    final staffId = callData['staffId']?.toString() ?? '';
    final callID = callData['callID']?.toString();
    final spent = (callData['spent'] as num?)?.toInt() ?? 0;
    final durationSeconds = (callData['durationSeconds'] as num?)?.toInt() ?? 0;
    final isVideo = callData['isVideoCall'] == true;

    if (staffId.isEmpty || spent <= 0 || durationSeconds <= 0) {
      debugPrint("Skipping invalid billing event: $callData");
      return;
    }

    final eventKey = callID?.isNotEmpty == true
        ? callID!
        : '$staffId-$durationSeconds-$spent';
    if (!_processedCallKeys.add(eventKey)) {
      debugPrint("Skipping duplicate billing event: $eventKey");
      return;
    }

    final userVM = context.read<UserViewModel>();
    if (userVM.currentUser == null) {
      await userVM.fetchUserDetails();
    }

    final currentBalance = userVM.currentUser?.coinBalance ?? 0;
    final newBalance = (currentBalance - spent).clamp(0, currentBalance);

    debugPrint(
      "Billing call $eventKey: $currentBalance -> $newBalance, spent: $spent, duration: ${durationSeconds}s",
    );

    final success = await userVM.updateUserCoinBalance(
      newBalance,
      staffId,
      spent,
      durationSeconds.toString(),
      isVideo ? "video" : "audio",
      callID,
    );

    if (success) {
      userVM.updateLocalCoinBalance(newBalance);
      await userVM.fetchUserDetails();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
