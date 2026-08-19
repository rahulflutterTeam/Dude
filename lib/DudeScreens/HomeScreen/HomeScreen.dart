// lib/DudeScreens/HomeScreen/HomeScreen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dude/DudeScreens/Chat/ChatDetailScreen.dart';
import 'package:dude/DudeScreens/HomeScreen/AppUpdateService.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/callServic.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/DudeScreens/ProfileScreen/ProfileScreen.dart';
import 'package:dude/DudeScreens/WalletScreen/WalletScreen.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Dude_Utils/navigation/route_observer.dart';
import 'package:dude/Reusable_Widgets/ActivePopupService.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/Reusable_Widgets/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/push/local_notifications.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/ReviewDialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware, SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  final socketService = SocketService();
  bool _isInitialized = false;
  StreamSubscription<Map<String, dynamic>>? _callEndedSubscription;

  // ─── Search ─────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  StaffViewModel? _staffVM;

  // ─── Language Filter ────────────────────────────────────────────────────
  String _selectedLanguage = 'All';
  List<String> _availableLanguages = ['All'];

  // For listening to room state changes
  VoidCallback? _roomStateListener;

  // Track if we've requested staff list
  bool _staffListRequested = false;
  bool _activePopupShown = false;
  late final Function(dynamic) _waveSocketHandler;

  /// True while the bottom-nav Home tab is selected (IndexedStack keeps us alive).
  bool _isHomeTabVisible = true;
  bool _isRefreshingVisible = false;
  DateTime? _lastVisibleRefreshAt;
  String? _startingCallButtonKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveSocketHandler = _onStaffWave;
    socketService.listenWave(_waveSocketHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _clearSearchFilter();
      }
    });
    AppUpdateService.checkForUpdate(context);

    _callEndedSubscription = CallService().onCallEnded.listen((callData) async {
      if (!mounted) return;

      print("🔄 Call ended listener triggered");

      final userVM = context.read<UserViewModel>();

      final spent = callData['spent'] as int;
      final durationSeconds = callData['durationSeconds'] as int;
      final staffId = callData['staffId'] as String;
      final isVideo = callData['isVideoCall'] as bool;
      final callID = callData['callID']?.toString();

      final currentBalance = userVM.currentUser?.coinBalance ?? 0;
      final newBalance = currentBalance - spent;

      debugPrint(
        "💳 Updating balance: $currentBalance → $newBalance | Duration: ${durationSeconds}s",
      );

      try {
        final success = await userVM.updateUserCoinBalance(
          newBalance,
          staffId,
          spent,
          durationSeconds.toString(),
          isVideo ? "video" : "audio",
          callID,
        );

        if (success == true) {
          userVM.updateLocalCoinBalance(newBalance);
          await userVM.fetchUserDetails();

          debugPrint("✅ Balance updated successfully");

          // Show review dialog only if user is back on HomeScreen
          if (ModalRoute.of(context)?.isCurrent == true && mounted) {
            if (isVideo) {
              await Future.delayed(const Duration(milliseconds: 800));
            }
            if (mounted) {
              await showStaffReviewDialog(context, staffId);
            }
          }
        } else {
          debugPrint("⚠️ updateUserCoinBalance returned false");
        }
      } catch (e, stack) {
        debugPrint("❌ Balance API failed: $e");
        debugPrint("Stack: $stack");
      }
    });
    _addCallEventListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  /// Called by bottom nav when the Home tab is shown or hidden.
  void setHomeTabVisible(bool visible) {
    _isHomeTabVisible = visible;
  }

  /// Refresh user + staff discovery when Home becomes visible again
  /// (tab return or pop back), matching PairEver remount behavior.
  Future<void> refreshOnVisible() async {
    if (!mounted || !_isHomeTabVisible || !_isInitialized) return;
    if (_isRefreshingVisible) return;

    final now = DateTime.now();
    if (_lastVisibleRefreshAt != null &&
        now.difference(_lastVisibleRefreshAt!) < const Duration(seconds: 2)) {
      return;
    }

    _isRefreshingVisible = true;
    _lastVisibleRefreshAt = now;

    try {
      final userVM = context.read<UserViewModel>();
      final staffVM = context.read<StaffViewModel>();

      await userVM.fetchUserDetails();
      if (!mounted || !_isHomeTabVisible) return;

      final user = userVM.currentUser;
      if (user == null) return;

      staffVM.setStaffListRequestContext(
        userId: user.id.isNotEmpty ? user.id : null,
        userMemberID: user.memberID,
      );

      if (!socketService.isConnected) {
        socketService.connectStaff(user.memberID);
        await Future.delayed(const Duration(milliseconds: 400));
      }

      await staffVM.fetchStaffDetails();
      if (!mounted || !_isHomeTabVisible) return;

      if (socketService.isConnected) {
        _requestStaffListForCurrentUser();
        staffVM.refreshStaffListViaSocket();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ [HOMESCREEN] refreshOnVisible failed: $e');
    } finally {
      _isRefreshingVisible = false;
    }
  }

  @override
  void didPopNext() {
    // A pushed route (Wallet/Profile/etc.) was popped while Home is still mounted.
    if (_isHomeTabVisible) {
      unawaited(refreshOnVisible());
    }
  }

  void _clearSearchFilter() {
    _debounce?.cancel();
    _debounce = null;

    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      if (mounted) {
        setState(() {});
      }
    }

    final staffVM = _staffVM;
    if (staffVM == null) return;

    if (staffVM.searchQuery.isNotEmpty) {
      staffVM.updateSearchQuery('');
    }
  }

  void _openPageClearingSearch(Widget page) {
    _clearSearchFilter();
    bondNavigator.newPage(context, page: page);
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _staffVM?.updateSearchQuery('');
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _staffVM?.updateSearchQuery(value);
    });
  }

  void _requestStaffListForCurrentUser() {
    final user = context.read<UserViewModel>().currentUser;
    if (user == null) return;

    final staffVM = context.read<StaffViewModel>();
    staffVM.setStaffListRequestContext(
      userId: user.id.isNotEmpty ? user.id : null,
      userMemberID: user.memberID,
    );
    socketService.requestStaffList(
      userId: user.id.isNotEmpty ? user.id : null,
      userMemberID: user.memberID,
    );
  }

  void _addCallEventListeners() {
    final roomStateNotifier = ZegoUIKit().getRoomStateStream();
    if (roomStateNotifier != null) {
      _roomStateListener = () {
        _onRoomStateChanged(roomStateNotifier.value);
      };
      roomStateNotifier.addListener(_roomStateListener!);
    }
  }

  void _addRoomStateListener() {
    if (_roomStateListener != null) {
      final oldNotifier = ZegoUIKit().getRoomStateStream();
      oldNotifier?.removeListener(_roomStateListener!);
    }

    final roomStateNotifier = ZegoUIKit().getRoomStateStream();
    if (roomStateNotifier != null) {
      _roomStateListener = () {
        _onRoomStateChanged(roomStateNotifier.value);
      };
      roomStateNotifier.addListener(_roomStateListener!);
    }
  }

  void _onRoomStateChanged(ZegoUIKitRoomState state) {
    debugPrint("📞 HomeScreen: Room state changed → ${state.reason}");
    _callService.updateRoomState(
      state.reason == ZegoRoomStateChangedReason.Logined,
    );

    if (state.reason == ZegoRoomStateChangedReason.Logout) {
      debugPrint("📞 HomeScreen: Room logout detected");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _staffVM = context.read<StaffViewModel>();
    _addRoomStateListener();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  // Extract unique languages from staff list - called without setState
  void _updateAvailableLanguages(List<StaffDataProfile> staffList) {
    Set<String> languages = {'All'};
    for (var staff in staffList) {
      if (staff.language != null && staff.language!.isNotEmpty) {
        languages.add(staff.language!);
      }
    }

    final newLanguages = languages.toList();

    // Only update if languages have changed
    if (newLanguages.length != _availableLanguages.length ||
        !_listEquals(newLanguages, _availableLanguages)) {
      setState(() {
        _availableLanguages = newLanguages;
      });
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _maybeShowWelcomeBonusPopup(UserProfile user) async {
    if (!mounted || user.memberID.isEmpty || user.isFirstLogin != 0) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final displayName = user.name?.trim().isNotEmpty == true
            ? user.name!.trim()
            : 'there';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF252A35),
                  DudeTheme.surface,
                  DudeTheme.background,
                ],
              ),
              border: Border.all(color: DudeTheme.accent.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/Images/dudecoin.jpg",
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 18),
                const Text(
                  "Welcome Bonus",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "+20 ",
                        style: TextStyle(
                          color: DudeTheme.accentCoral,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: "Coins",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Hi $displayName, your first visit deserves a little sparkle.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DudeTheme.textMuted,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: DudeTheme.surfaceRaised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DudeTheme.accent.withOpacity(0.24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: DudeTheme.accentCoral,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "One-time reward for your first login",
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DudeTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final userVM = context.read<UserViewModel>();
                      final success = await userVM.updateIsFirstLogin();
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: const Text(
                      "Awesome",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Filter staff based on selected language and search query
  List<StaffDataProfile> _getFilteredStaff(StaffViewModel staffVM) {
    // Only show staff who are currently online (logged-out/offline are hidden).
    var filteredList = staffVM.allStaffList
        .where((staff) => staff.isOnline)
        .toList();

    // Apply language filter
    if (_selectedLanguage != 'All') {
      filteredList = filteredList.where((staff) {
        return staff.language == _selectedLanguage;
      }).toList();
    }

    // Apply search filter
    if (staffVM.searchQuery.isNotEmpty) {
      filteredList = filteredList.where((staff) {
        final query = staffVM.searchQuery.toLowerCase();
        final name = staff.name.toLowerCase();
        final age = staff.age?.toString() ?? '';
        final language = staff.language?.toLowerCase() ?? '';
        final city = staff.city?.toLowerCase() ?? '';
        return name.contains(query) ||
            age.contains(query) ||
            language.contains(query) ||
            city.contains(query);
      }).toList();
    }

    return filteredList;
  }

  Future<void> _initializeScreen() async {
    if (_isInitialized) {
      return;
    }

    try {
      // debugPrint("📱 [HOMESCREEN] Step 1: Fetching user details...");
      final userVM = context.read<UserViewModel>();
      final staffVM = context.read<StaffViewModel>();
      await userVM.fetchUserDetails();

      final user = userVM.currentUser;
      if (user == null) {
        debugPrint("❌ [HOMESCREEN] User is null, cannot proceed");
        return;
      }

      // debugPrint(
      //   "✅ [HOMESCREEN] User fetched → memberID: ${user.memberID}, name: ${user.name}",
      // );

      // debugPrint("🔌 [HOMESCREEN] Step 3: Connecting socket...");

      final staffID = user.memberID;
      staffVM.setStaffListRequestContext(
        userId: user.id.isNotEmpty ? user.id : null,
        userMemberID: user.memberID,
      );
      // debugPrint("🔌 [HOMESCREEN] Using user ID for socket: $staffID");

      try {
        socketService.connectStaff(staffID);
        // debugPrint("✅ [HOMESCREEN] socketService.connectStaff called");

        await Future.delayed(const Duration(milliseconds: 500));

        Future.delayed(const Duration(seconds: 1), () {
          if (socketService.isConnected && mounted && !_staffListRequested) {
            // debugPrint(
            //   "📤 [HOMESCREEN] Requesting initial staff list via socket...",
            // );
            _staffListRequested = true;
            _requestStaffListForCurrentUser();
          }
        });
      } catch (e, stackTrace) {
        debugPrint("❌ [HOMESCREEN] Failed to setup socket: $e");
        debugPrint("❌ [HOMESCREEN] Stack trace: $stackTrace");
      }

      // debugPrint("👥 [HOMESCREEN] Step 5: Fetching initial staff list...");
      await staffVM.fetchStaffDetails();
      // Load fee config for chat/call pricing from backend when available.
      unawaited(staffVM.fetchFeeManagement());
      // debugPrint(
      //   "✅ [HOMESCREEN] Initial staff list loaded: ${staffVM.staffList.length}",
      // );

      setState(() {
        _isInitialized = true;
      });

      await _maybeShowWelcomeBonusPopup(user);
      await _maybeShowActivePopup();

      // debugPrint("✅ [HOMESCREEN] _initializeScreen completed successfully");
    } catch (e, stackTrace) {
      debugPrint("❌ [HOMESCREEN] CRITICAL ERROR in _initializeScreen");
      debugPrint("❌ [HOMESCREEN] Error: $e");
      debugPrint("❌ [HOMESCREEN] Stack trace: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to initialize: ${e.toString().split('\n').first}",
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                  _staffListRequested = false;
                });
                _initializeScreen();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _maybeShowActivePopup() async {
    if (_activePopupShown || !mounted) return;
    _activePopupShown = true;
    await ActivePopupService.showActivePopupsForRole(context, role: 'user');
  }

  ZegoUIKitPrebuiltCallEvents _buildZegoCallEvents() {
    return ZegoUIKitPrebuiltCallEvents(
      onCallEnd: (event, defaultAction) {
        debugPrint("📞 onCallEnd triggered → ${event.reason}");
        defaultAction();
        _callService.endCall();
      },
      user: ZegoCallUserEvents(
        onLeave: (user) {
          debugPrint("📞 Remote user left → ${user.id}");
          ZegoUIKit().leaveRoom();
          _callService.endCall();
        },
      ),
      room: ZegoCallRoomEvents(
        onStateChanged: (state) {
          debugPrint("📞 Room state changed → ${state.reason}");
          if (state.reason == ZegoRoomStateChangedReason.Logined) {
            _callService.updateRoomState(true);
          }
          if (state.reason == ZegoRoomStateChangedReason.Logout) {
            _callService.endCall();
          }
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isHomeTabVisible) {
        unawaited(refreshOnVisible());
      } else {
        final userVM = context.read<UserViewModel>();
        if (userVM.currentUser != null) {
          final staffID = userVM.currentUser!.memberID;
          if (!socketService.isConnected) {
            socketService.connectStaff(staffID);
          }
        }
      }

      _addRoomStateListener();
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);

    if (_roomStateListener != null) {
      final roomStateNotifier = ZegoUIKit().getRoomStateStream();
      roomStateNotifier?.removeListener(_roomStateListener!);
    }

    _clearSearchFilter();
    _searchController.dispose();
    _debounce?.cancel();
    _callEndedSubscription?.cancel();
    _callService.cancelCallTimer();

    socketService.removeWaveListener(_waveSocketHandler);
    _staffVM?.disposeListeners();

    super.dispose();
  }

  void _onStaffWave(dynamic data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final title = map['title']?.toString() ??
        map['staffName']?.toString() ??
        'Someone is online';
    final body = map['body']?.toString() ??
        'They are waiting for you. Tap to connect.';
    unawaited(
      LocalNotifications.instance.showWave(
        title: title,
        body: body,
        payload: jsonEncode(map),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel, StaffViewModel>(
      builder: (context, userVM, staffVM, child) {
        final currentUser = userVM.currentUser;

        // Update available languages when staff list changes
        // Use WidgetsBinding to avoid calling setState during build
        if (staffVM.staffList.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateAvailableLanguages(staffVM.staffList);
            }
          });
        }

        // Get filtered staff list
        final filteredStaff = _getFilteredStaff(staffVM);

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Header: greeting + coin balance ───────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // User avatar
                        GestureDetector(
                          onTap: () => _openPageClearingSearch(
                            const ProfileScreen(backPage: true),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Image(
                                image:
                                    (currentUser?.image != null &&
                                        currentUser!.image!.isNotEmpty)
                                    ? NetworkImage(currentUser.image!)
                                    : const AssetImage("assets/Images/men.png")
                                          as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Greeting
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome,",
                              style: TextStyle(
                                color: DudeTheme.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              currentUser?.name ?? "User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Coin balance
                        GestureDetector(
                          onTap: () =>
                              _openPageClearingSearch(const WalletScreen()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1A1A1A),
                                  DudeTheme.surfaceRaised,
                                  DudeTheme.surface,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DudeTheme.accent.withOpacity(0.7),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _DudeCoinIcon(size: 28),
                                const SizedBox(width: 6),
                                Text(
                                  "${currentUser?.coinBalance ?? 0}.00",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    gradient: DudeTheme.premiumAccentGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: DudeTheme.textOnAccent,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Search bar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: DudeTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DudeTheme.border, width: 1),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: const TextStyle(
                            color: DudeTheme.textMuted,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: DudeTheme.textMuted,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: DudeTheme.textMuted,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _clearSearchFilter();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Language Filter Row ─────────────────────────────────
                  if (_availableLanguages.length > 1) ...[
                    SizedBox(
                      height: 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _availableLanguages.length,
                        itemBuilder: (context, index) {
                          final language = _availableLanguages[index];
                          final isSelected = _selectedLanguage == language;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = language;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [Colors.white, Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : DudeTheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : DudeTheme.border,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    language,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : DudeTheme.textMuted,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Staff List ─────────────────────────────────────────
                  Expanded(
                    child: !_isInitialized
                        ? _buildProfileCardShimmerList()
                        : staffVM.allStaffList.isEmpty &&
                              staffVM.isFetchingStaff
                        ? _buildProfileCardShimmerList()
                        : filteredStaff.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.no_accounts,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedLanguage != 'All'
                                      ? "No Matches available in $_selectedLanguage"
                                      : "No Matches available",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (staffVM.staffFetchError != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    staffVM.staffFetchError!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (_selectedLanguage != 'All')
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedLanguage = 'All';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DudeTheme.accent,
                                    ),
                                    child: const Text("Show All Staff"),
                                  ),
                                if (_selectedLanguage == 'All' &&
                                    staffVM.staffFetchError != null)
                                  ElevatedButton(
                                    onPressed: () {
                                      final userVM = context
                                          .read<UserViewModel>();
                                      if (userVM.currentUser != null) {
                                        socketService.connectStaff(
                                          userVM.currentUser!.memberID,
                                        );
                                        Future.delayed(
                                          const Duration(seconds: 1),
                                          () {
                                            if (socketService.isConnected) {
                                              _requestStaffListForCurrentUser();
                                            }
                                          },
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DudeTheme.accent,
                                    ),
                                    child: const Text("Retry Connection"),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              staffVM.refreshStaffListViaSocket();
                            },
                            color: Colors.white,
                            backgroundColor: DudeTheme.accent,
                            child: ListView.builder(
                              physics: PremiumAnimations.scrollPhysics,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _staffListCard(filteredStaff[index]),
                                );
                              },
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

  // ─────────────────────────────────────────────────────────────────────────
  // STAFF PROFILE CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProfileCardShimmerList() {
    return ShimmerLoader(
      baseColor: const Color(0xFF2A111A),
      highlightColor: const Color(0xFF6A263B),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _staffListCardShimmer(),
        ),
      ),
    );
  }

  Widget _staffListCardShimmer() {
    return Container(
      height: 208,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: DudeTheme.surface.withValues(alpha: 0.9),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _shimmerBox(width: 64, height: 64, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(width: 120, height: 16, radius: 4),
                    const SizedBox(height: 8),
                    _shimmerBox(width: 150, height: 10, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _shimmerBox(width: double.infinity, height: 40, radius: 14),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    double? width,
    required double height,
    double radius = 8,
    BorderRadiusGeometry? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DudeTheme.surfaceRaised,
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
      ),
    );
  }

  Widget _staffListCard(StaffDataProfile staff) {
    final age = staff.age;

    Color statusColor;
    String statusText;
    if (staff.isBusy) {
      statusColor = DudeTheme.warning;
      statusText = 'Busy';
    } else if (staff.isOnline) {
      statusColor = DudeTheme.success;
      statusText = 'Online';
    } else {
      statusColor = DudeTheme.textSubtle;
      statusText = 'Offline';
    }

    final callType = (staff.callType?.toLowerCase().trim() ?? 'both');
    final showAudio = callType == 'audio' || callType == 'both';
    final showVideo = callType == 'video' || callType == 'both';
    final isEnabled = staff.isOnline && !staff.isBusy;
    final isLive = staff.isOnline && !staff.isBusy;

    final bio = staff.bio?.toString().trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DudeTheme.surfaceRaised, DudeTheme.surface],
        ),
        border: Border.all(
          color: isLive
              ? DudeTheme.accent.withValues(alpha: 0.5)
              : DudeTheme.border.withValues(alpha: 0.4),
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? DudeTheme.accent.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: isLive ? 26 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _superHaloAvatar(staff, isLive: isLive, statusColor: statusColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _staffNameLabel(staff.name ?? 'Staff', highlight: isLive),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _statusPill(statusText, statusColor),
                        if (age != null) _glassChip('$age yrs'),
                        if ((staff.language ?? '').isNotEmpty)
                          _glassChip(staff.language!),
                        if ((staff.city ?? '').isNotEmpty)
                          _glassChip(staff.city!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ],
          if (staff.areaOfInterest.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final i in staff.areaOfInterest)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Tag(i.title, compact: true),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: DudeTheme.border.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          _buildCallButtons(
            staff: staff,
            showAudio: showAudio,
            showVideo: showVideo,
            isEnabled: isEnabled,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _staffNameLabel(String name, {required bool highlight}) {
    final style = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.35,
      height: 1.1,
      color: highlight ? Colors.white : Colors.white,
    );

    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }

  Widget _glassChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DudeTheme.textMid,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _superHaloAvatar(
    StaffDataProfile staff, {
    required bool isLive,
    Color? statusColor,
  }) {
    const outer = 72.0;
    const inner = 64.0;
    final dotColor = statusColor ?? DudeTheme.textSubtle;

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(2.6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: inner,
                height: inner,
                child: _staffHeroImage(staff),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: DudeTheme.surfaceRaised, width: 2.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffHeroImage(StaffDataProfile staff) {
    final image = (staff.image != null && staff.image!.isNotEmpty)
        ? Image.network(
            staff.image!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/Images/women.png', fit: BoxFit.cover),
          )
        : Image.asset('assets/Images/women.png', fit: BoxFit.cover);

    return image;
  }

  Widget _statusPill(String text, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALL BUTTONS ROW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCallButtons({
    required StaffDataProfile staff,
    required bool showAudio,
    required bool showVideo,
    required bool isEnabled,
    bool compact = false,
  }) {
    final gap = compact ? 6.0 : 12.0;
    final chatSize = compact ? 40.0 : 50.0;
    final audioKey = '${staff.id}|audio';
    final videoKey = '${staff.id}|video';

    if (showAudio && !showVideo) {
      return Row(
        children: [
          Expanded(
            child: _customCallButton(
              label: 'Audio Call',
              coinText: '20',
              min: '/min',
              pricePerMin: 20,
              isVideoCall: false,
              targetUserID: staff.memberID,
              targetUserName: staff.name ?? 'Staff',
              targetStaffId: staff.id,
              isEnabled: isEnabled,
              buttonKey: audioKey,
              fillWidth: true,
              compact: compact,
            ),
          ),
          SizedBox(width: gap),
          _chatImageButton(staff, size: chatSize),
        ],
      );
    }

    if (showVideo && !showAudio) {
      return Row(
        children: [
          Expanded(
            child: _customCallButton(
              label: 'Video Call',
              coinText: '60',
              min: '/min',
              pricePerMin: 60,
              isVideoCall: true,
              targetUserID: staff.memberID,
              targetUserName: staff.name ?? 'Staff',
              targetStaffId: staff.id,
              isEnabled: isEnabled,
              buttonKey: videoKey,
              fillWidth: true,
              compact: compact,
            ),
          ),
          SizedBox(width: gap),
          _chatImageButton(staff, size: chatSize),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _customCallButton(
            label: compact ? 'Audio Call' : '20/min',
            coinText: '20',
            min: '/min',
            pricePerMin: 20,
            isVideoCall: false,
            targetUserID: staff.memberID,
            targetUserName: staff.name ?? 'Staff',
            targetStaffId: staff.id,
            isEnabled: isEnabled,
            buttonKey: audioKey,
            fillWidth: false,
            compact: compact,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _customCallButton(
            label: compact ? 'Video Call' : '60/min',
            coinText: '60',
            min: '/min',
            pricePerMin: 60,
            isVideoCall: true,
            targetUserID: staff.memberID,
            targetUserName: staff.name ?? 'Staff',
            targetStaffId: staff.id,
            isEnabled: isEnabled,
            buttonKey: videoKey,
            fillWidth: false,
            compact: compact,
          ),
        ),
        SizedBox(width: gap),
        _chatImageButton(staff, size: chatSize),
      ],
    );
  }

  Widget _chatImageButton(StaffDataProfile staff, {required double size}) {
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        _openPageClearingSearch(
          ChatDetailScreen(
            conversationID: staff.memberID,
            peerMemberID: staff.memberID,
            name: staff.name ?? 'Staff',
            staffId: staff.id,
            imageUrl: staff.image,
          ),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/Images/chatdude.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INDIVIDUAL CALL BUTTON
  // ─────────────────────────────────────────────────────────────────────────

  Widget _customCallButton({
    required String label,
    required String coinText,
    required String min,
    required int pricePerMin,
    required bool isVideoCall,
    required String targetUserID,
    required String targetUserName,
    required String targetStaffId,
    required bool isEnabled,
    required String buttonKey,
    required bool fillWidth,
    bool compact = false,
  }) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final currentUser = userVM.currentUser;
        final balance = currentUser?.coinBalance ?? 0;
        final isStartingThisCall = _startingCallButtonKey == buttonKey;
        final canStartCall = isEnabled && _startingCallButtonKey == null;

        if (pricePerMin <= 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: canStartCall
              ? () async {
                  if (mounted) {
                    setState(() {
                      _startingCallButtonKey = buttonKey;
                    });
                  }
                  try {
                    final statuses = await [
                      Permission.microphone,
                      if (isVideoCall) Permission.camera,
                    ].request();

                    if (!statuses[Permission.microphone]!.isGranted ||
                        (isVideoCall &&
                            !statuses[Permission.camera]!.isGranted)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Permissions required")),
                      );
                      return;
                    }

                    if (balance < pricePerMin) {
                      _openPageClearingSearch(const WalletScreen());
                      return;
                    }

                    final maxMinutes = balance ~/ pricePerMin;
                    final maxSeconds = maxMinutes > 20
                        ? 20 * 60
                        : maxMinutes * 60;

                    if (currentUser == null || currentUser.memberID.isEmpty) {
                      Utils.snackBarErrorMessage("User details not available");
                      return;
                    }

                    try {
                      await ZegoCallService().ensureInitializedForCaller(
                        avatarUrl: currentUser.image ?? "",
                        userId: currentUser.memberID,
                        userName: currentUser.name ?? "User",
                        events: _buildZegoCallEvents(),
                      );
                    } catch (e, stackTrace) {
                      debugPrint("❌ [CALL] Failed to initialize Zego: $e");
                      debugPrint("❌ [CALL] Stack trace: $stackTrace");
                      Utils.snackBarErrorMessage(
                        "Unable to start call. Please try again.",
                      );
                      return;
                    }

                    final callType = isVideoCall ? "video" : "audio";
                    final callID =
                        "pe_${currentUser.memberID}_${targetStaffId}_${callType}_${pricePerMin}_${balance}_${maxSeconds}_${DateTime.now().millisecondsSinceEpoch}";

                    final success = await ZegoUIKitPrebuiltCallInvitationService()
                        .send(
                          resourceID: "dude_push",
                          invitees: [
                            ZegoCallUser.fromUIKit(
                              ZegoUIKitUser(
                                id: targetUserID,
                                name: targetUserName,
                              ),
                            ),
                          ],
                          isVideoCall: isVideoCall,
                          callID: callID,
                          customData: jsonEncode({
                            "user_id": currentUser.memberID,
                            "staff_id": targetStaffId,
                            "price_per_min": pricePerMin,
                            "call_type": callType,
                            "coin_balance": balance,
                            "max_seconds": maxSeconds,
                          }),
                          timeoutSeconds: 60,
                        );

                    if (!success) {
                      Utils.snackBarErrorMessage("Something went wrong");
                      return;
                    }

                    _callService.resetCall();
                    _callService.startCall(
                      callID: callID,
                      targetUserID: targetUserID,
                      staffId: targetStaffId,
                      pricePerMin: pricePerMin,
                      isVideoCall: isVideoCall,
                      initialCoinBalance: balance,
                      maxCallSeconds: maxSeconds,
                    );

                    debugPrint(
                      "Call invitation sent → tracking started | Target: $targetUserID | "
                      "Staff ID: $targetStaffId | Price: $pricePerMin/min | Max: $maxSeconds sec",
                    );

                    _callService.startCallTimer(
                      Duration(seconds: maxSeconds),
                      () async {
                        if (!_callService.isCallActive || !mounted) return;
                        debugPrint("⏰ TIME LIMIT REACHED - Ending call properly");

                        try {
                          await ZegoUIKitPrebuiltCallController().hangUp(context);
                          await Future.delayed(
                            const Duration(milliseconds: 1200),
                          );
                          final callData = CallService().endCall();
                          if (callData != null) {
                            debugPrint("✅ endCall() executed from timer");
                          }
                        } catch (e) {
                          debugPrint("❌ Error during timer end: $e");
                          CallService().endCall();
                        }
                      },
                    );
                  } finally {
                    if (mounted && _startingCallButtonKey == buttonKey) {
                      setState(() {
                        _startingCallButtonKey = null;
                      });
                    }
                  }
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                height: compact ? 46 : 48,
                width: fillWidth ? double.infinity : null,
                decoration: BoxDecoration(
                  gradient: isEnabled
                      ? DudeTheme.callButtonGradient
                      : LinearGradient(
                          colors: [DudeTheme.surface, DudeTheme.surfaceRaised],
                        ),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  border: Border.all(
                    color: isEnabled
                        ? DudeTheme.accent.withValues(alpha: 0.35)
                        : DudeTheme.border,
                  ),
                  boxShadow: isEnabled && !compact
                      ? DudeTheme.accentGlowShadow(blur: 12, spread: -6)
                      : null,
                ),
                child: isStartingThisCall
                    ? Center(
                        child: SizedBox(
                          width: compact ? 18 : 20,
                          height: compact ? 18 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isEnabled
                                  ? DudeTheme.textOnAccent
                                  : DudeTheme.textMuted,
                            ),
                          ),
                        ),
                      )
                    : compact
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                isEnabled
                                    ? DudeTheme.textOnAccent
                                    : DudeTheme.textMuted,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                isVideoCall
                                    ? 'assets/Images/video.png'
                                    : 'assets/Images/call.png',
                                width: 30,
                                height: 30,
                                errorBuilder: (_, __, ___) => Icon(
                                  isVideoCall
                                      ? Icons.videocam_rounded
                                      : Icons.phone_rounded,
                                  color: DudeTheme.textOnAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          _DudeCoinIcon(size: 20),
                          const SizedBox(width: 4),
                          Text(
                            coinText,
                            style: TextStyle(
                              color: isEnabled
                                  ? DudeTheme.textOnAccent
                                  : DudeTheme.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            min,
                            style: TextStyle(
                              color: isEnabled
                                  ? DudeTheme.textOnAccent
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Center(child: _DudeCoinIcon(size: 26)),
                          const SizedBox(width: 2),
                          Text(
                            coinText,
                            style: TextStyle(
                              color: isEnabled
                                  ? DudeTheme.textOnAccent
                                  : DudeTheme.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            min,
                            style: TextStyle(
                              color: isEnabled
                                  ? DudeTheme.textOnAccent
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Center(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                isEnabled
                                    ? DudeTheme.textOnAccent
                                    : DudeTheme.textMuted,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                isVideoCall
                                    ? 'assets/Images/video.png'
                                    : 'assets/Images/call.png',
                                width: 30,
                                height: 30,
                                errorBuilder: (_, __, ___) => Icon(
                                  isVideoCall
                                      ? Icons.videocam_rounded
                                      : Icons.phone_rounded,
                                  color: DudeTheme.textOnAccent,
                                  size: 18,
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTEREST TAG
// ─────────────────────────────────────────────────────────────────────────────

/// Brand currency icon — a gold "Dude" coin, drawn in code so no image asset is needed.
/// Custom-drawn call glyph (stylised handset), used instead of the stock Material icon.
class _CallGlyph extends StatelessWidget {
  final double size;
  final Color color;
  const _CallGlyph({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CallGlyphPainter(color),
    );
  }
}

class _CallGlyphPainter extends CustomPainter {
  final Color color;
  _CallGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.78);

    final earRadius = size.width * 0.2;
    final barLength = size.width * 0.66;
    final barThickness = size.height * 0.3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: barLength,
          height: barThickness,
        ),
        Radius.circular(barThickness / 2),
      ),
      paint,
    );
    canvas.drawCircle(Offset(-size.width * 0.32, 0), earRadius, paint);
    canvas.drawCircle(Offset(size.width * 0.32, 0), earRadius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CallGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom-drawn video-camera glyph, used instead of the stock Material icon.
class _VideoGlyph extends StatelessWidget {
  final double size;
  final Color color;
  const _VideoGlyph({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VideoGlyphPainter(color),
    );
  }
}

class _VideoGlyphPainter extends CustomPainter {
  final Color color;
  _VideoGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bodyWidth = size.width * 0.6;
    final bodyHeight = size.height * 0.56;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size.width - bodyWidth) / 2 - size.width * 0.08,
        (size.height - bodyHeight) / 2,
        bodyWidth,
        bodyHeight,
      ),
      Radius.circular(bodyHeight * 0.24),
    );
    canvas.drawRRect(bodyRect, paint);

    final tipX = bodyRect.right + size.width * 0.24;
    final path = Path()
      ..moveTo(bodyRect.right - 1, bodyRect.top + bodyHeight * 0.16)
      ..lineTo(tipX, size.height * 0.5 - bodyHeight * 0.3)
      ..lineTo(tipX, size.height * 0.5 + bodyHeight * 0.3)
      ..lineTo(bodyRect.right - 1, bodyRect.bottom - bodyHeight * 0.16)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VideoGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DudeCoinIcon extends StatelessWidget {
  final double size;
  const _DudeCoinIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Transform.scale(
          scale: 1.4,
          child: Image.asset(
            'assets/Images/dudecoin.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE9A8),
                    Color(0xFFF0B429),
                    Color(0xFFB8790C),
                  ],
                ),
              ),
              child: Text(
                'D',
                style: TextStyle(
                  color: const Color(0xFF6B4400),
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool compact;
  const _Tag(this.text, {this.compact = false});

  @override
  Widget build(BuildContext context) {
    const radius = 4.0;
    return CustomPaint(
      painter: _GradientBorderPainter(radius: radius, strokeWidth: 1.2),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 5 : 8,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;

  const _GradientBorderPainter({required this.radius, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [DudeTheme.accentBright, DudeTheme.accentDeep],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
}
