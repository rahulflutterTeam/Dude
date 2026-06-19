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
import 'package:dude/Reusable_Widgets/ReviewDialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  final socketService = SocketService();
  bool _isInitialized = false;
  late final AnimationController _coinPulseController;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _coinPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
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
                  Color(0xFF2A173A),
                  Color(0xFF1B1028),
                  Color(0xFF120A1B),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD9F155).withOpacity(0.30),
              ),
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
                  "assets/Images/heartcoin.png",
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
                          color: Color(0xFFD9F155),
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
                    color: Color(0xFFCEC6DA),
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
                    color: const Color(0xFF2B1C3D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD9F155).withOpacity(0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFD9F155),
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
                      backgroundColor: const Color(0xFFD9F155),
                      foregroundColor: Colors.black,
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
    var filteredList = staffVM.allStaffList;

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
            socketService.requestStaffList();
          }
        });
      } catch (e, stackTrace) {
        debugPrint("❌ [HOMESCREEN] Failed to setup socket: $e");
        debugPrint("❌ [HOMESCREEN] Stack trace: $stackTrace");
      }

      // debugPrint("👥 [HOMESCREEN] Step 5: Fetching initial staff list...");
      await staffVM.fetchStaffDetails();
      // debugPrint(
      //   "✅ [HOMESCREEN] Initial staff list loaded: ${staffVM.staffList.length}",
      // );

      setState(() {
        _isInitialized = true;
      });

      await _maybeShowWelcomeBonusPopup(user);

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
      final userVM = context.read<UserViewModel>();
      if (userVM.currentUser != null) {
        final staffID = userVM.currentUser!.memberID;
        if (!socketService.isConnected) {
          socketService.connectStaff(staffID);
        }

        Future.delayed(const Duration(seconds: 1), () {
          if (socketService.isConnected) {
            socketService.requestStaffList();
          }
        });
      }

      _addRoomStateListener();
    }
  }

  @override
  void dispose() {
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
    _coinPulseController.dispose();

    _staffVM?.disposeListeners();

    super.dispose();
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
                  Color(0xFF12151c), // middle
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e), // bottom
                ],
              ),
            ),
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
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                (currentUser?.image != null &&
                                    currentUser!.image!.isNotEmpty)
                                ? NetworkImage(currentUser.image!)
                                : const AssetImage("assets/Images/men.png")
                                      as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Greeting
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Hello,",
                              style: TextStyle(
                                color: Color(0xFFB0A8C0),
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
                          child: AnimatedBuilder(
                            animation: _coinPulseController,
                            builder: (context, child) {
                              final shimmerProgress =
                                  (_coinPulseController.value * 2.2) - 0.6;
                              final shimmerX =
                                  (-110.0 + (shimmerProgress * 170));
                              final shimmerY = (-42.0 + (shimmerProgress * 54));
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF342057),
                                      Color(0xFF2C1E4F),
                                      Color(0xFF24173D),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE8FF72),
                                    width: 1.2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFD9F155),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Image.asset(
                                            "assets/Images/heartcoin.png",
                                            height: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${currentUser?.coinBalance ?? 0}.00",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Transform.translate(
                                            offset: Offset(shimmerX, shimmerY),
                                            child: Transform.rotate(
                                              angle: 0.78,
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  width: 92,
                                                  height: 170,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                      colors: [
                                                        Colors.white
                                                            .withOpacity(0),
                                                        Colors.white
                                                            .withOpacity(0.08),
                                                        Colors.white
                                                            .withOpacity(0.22),
                                                        Colors.white
                                                            .withOpacity(0.40),
                                                        Colors.white
                                                            .withOpacity(0.22),
                                                        Colors.white
                                                            .withOpacity(0.08),
                                                        Colors.white
                                                            .withOpacity(0),
                                                      ],
                                                    ),
                                                  ),
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
                            },
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
                        color: const Color(0xFF1C1426),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2E2040),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name, age, language, city...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF6B5F7A),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF6B5F7A),
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF6B5F7A),
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
                                          colors: [
                                            Color(0xFFd9f155),
                                            Color(0xFFd9f155),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : const Color(0xFF1C1426),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : const Color(0xFF2E2040),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    language,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : const Color(0xFFB0A8C0),
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
                                      backgroundColor: Colors.purple,
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
                                              socketService.requestStaffList();
                                            }
                                          },
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
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
                            backgroundColor: Colors.purple,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                return _staffProfileCard(staff);
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => _staffProfileCardShimmer(),
      ),
    );
  }

  Widget _staffProfileCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0XFF1c122d), Color(0XFF1c122d), Color(0XFF251347)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A1F38), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(
                width: 70,
                height: 70,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 120, height: 16, radius: 5),
                      const SizedBox(height: 10),
                      _shimmerBox(width: 170, height: 13, radius: 5),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: _shimmerBox(width: 76, height: 28, radius: 6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: double.infinity, height: 14, radius: 5),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: _shimmerBox(
                    width: double.infinity,
                    height: 14,
                    radius: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                _shimmerBox(width: 78, height: 28, radius: 10),
                const SizedBox(width: 8),
                _shimmerBox(width: 92, height: 28, radius: 10),
                const SizedBox(width: 8),
                _shimmerBox(width: 68, height: 28, radius: 10),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
            child: Row(
              children: [
                Expanded(child: _shimmerBox(height: 50, radius: 8)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(height: 50, radius: 8)),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
        color: const Color(0xFF2A1F38),
        borderRadius: borderRadius ?? BorderRadius.circular(radius),
      ),
    );
  }

  Widget _staffProfileCard(StaffDataProfile staff) {
    // print("callType ::::::::${staff.callType}");
    // print("isBusy:::::::::${staff.isBusy}");

    final age = staff.age;
    // print("???$age");

    // Status badge colours
    Color statusColor;
    String statusText;

    if (staff.isBusy) {
      statusColor = const Color(0xFFE8A020);
      statusText = "Busy";
    } else if (staff.isOnline) {
      statusColor = const Color(0xFF7dff63);
      statusText = "Online";
    } else {
      statusColor = const Color(0xFFFF3B30);
      statusText = "Offline";
    }

    final String callType = (staff.callType?.toLowerCase().trim() ?? 'both');
    final bool showAudio = callType == 'audio' || callType == 'both';
    final bool showVideo = callType == 'video' || callType == 'both';
    final bool isEnabled = staff.isOnline && !staff.isBusy;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0XFF1c122d),
            Color(0XFF1c122d),
            Color(0XFF1c122d),
            Color(0XFF251347),
            Color(0XFF251347),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A1F38), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: avatar + name/age/location + status badge ────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                  ),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                  ),
                  child: (staff.image != null && staff.image!.isNotEmpty)
                      ? Image.network(
                          staff.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            "assets/Images/women.png",
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          "assets/Images/women.png",
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + age + location
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name ?? "Staff",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (age != null) 'Age : $age',
                          if ((staff.language ?? '').isNotEmpty)
                            staff.language!,
                          if ((staff.city ?? '').isNotEmpty) staff.city!,
                        ].join(' | '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Bio text ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              staff.bio.toString() == ""
                  ? "Not here to waste time - impress me"
                  : staff.bio.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // ── Interest tags ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: staff.areaOfInterest
                    .map(
                      (interest) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _Tag(interest.title),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Call buttons ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 10),
            child: _buildCallButtons(
              staff: staff,
              showAudio: showAudio,
              showVideo: showVideo,
              isEnabled: isEnabled,
            ),
          ),
          const SizedBox(height: 8),
        ],
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
  }) {
    if (showAudio && !showVideo) {
      return Row(
        children: [
          Expanded(
            child: _customCallButton(
              label: "Audio Call",
              coinText: "20",
              min: "/min",
              pricePerMin: 20,
              isVideoCall: false,
              targetUserID: staff.memberID,
              targetUserName: staff.name ?? "Staff",
              targetStaffId: staff.id,
              isEnabled: isEnabled,
              fillWidth: true,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              if (mounted) {
                _openPageClearingSearch(
                  ChatDetailScreen(
                    conversationID: staff.memberID,
                    peerMemberID: staff.memberID,
                    name: staff.name ?? "Staff",
                    staffId: staff.id,
                  ),
                );
              }
            },
            child: Container(
              height: 50,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0XFF3f353f),
                    Color(0XFF453e3b),
                    Color(0XFF3f353f),
                  ],
                ),
                color: const Color(0xFF373031),

                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFd2ea46), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AppText("Chat Now", fontWeight: FontWeight.w700),
                    // SizedBox(width: 10),
                    SvgPicture.asset(
                      "assets/Images/chatactive.svg",
                      height: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (showVideo && !showAudio) {
      return Row(
        children: [
          Expanded(
            child: _customCallButton(
              label: "Video Call",
              coinText: "60",
              min: "/min",
              pricePerMin: 60,
              isVideoCall: true,
              targetUserID: staff.memberID,
              targetUserName: staff.name ?? "Staff",
              targetStaffId: staff.id,
              isEnabled: isEnabled,
              fillWidth: true,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              if (mounted) {
                _openPageClearingSearch(
                  ChatDetailScreen(
                    conversationID: staff.memberID,
                    peerMemberID: staff.memberID,
                    name: staff.name ?? "Staff",
                    staffId: staff.id,
                  ),
                );
              }
            },
            child: Container(
              height: 50,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0XFF3f353f),
                    Color(0XFF453e3b),
                    Color(0XFF3f353f),
                  ],
                ),
                color: const Color(0xFF373031),

                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFd2ea46), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AppText("Chat Now", fontWeight: FontWeight.w700),
                    // SizedBox(width: 10),
                    SvgPicture.asset(
                      "assets/Images/chatactive.svg",
                      height: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Both
    return Row(
      children: [
        Expanded(
          child: _customCallButton(
            label: "20/min",
            coinText: "20",
            min: "/min",
            pricePerMin: 20,
            isVideoCall: false,
            targetUserID: staff.memberID,
            targetUserName: staff.name ?? "Staff",
            targetStaffId: staff.id,
            isEnabled: isEnabled,
            fillWidth: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _customCallButton(
            label: "20/min",
            coinText: "60",
            min: "/min",
            pricePerMin: 60,
            isVideoCall: true,
            targetUserID: staff.memberID,
            targetUserName: staff.name ?? "Staff",
            targetStaffId: staff.id,
            isEnabled: isEnabled,
            fillWidth: false,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            if (mounted) {
              _openPageClearingSearch(
                ChatDetailScreen(
                  conversationID: staff.memberID,
                  peerMemberID: staff.memberID,
                  name: staff.name ?? "Staff",
                  staffId: staff.id,
                ),
              );
            }
          },
          child: Container(
            height: 50,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0XFF3f353f),
                  Color(0XFF453e3b),
                  Color(0XFF3f353f),
                ],
              ),
              color: const Color(0xFF373031),

              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFd2ea46), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // AppText("Chat Now", fontWeight: FontWeight.w700),
                  // SizedBox(width: 10),
                  SvgPicture.asset("assets/Images/chatactive.svg", height: 25),
                ],
              ),
            ),
          ),
        ),
      ],
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
    required bool fillWidth,
  }) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final currentUser = userVM.currentUser;
        final balance = currentUser?.coinBalance ?? 0;

        if (pricePerMin <= 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: isEnabled
              ? () async {
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
                        resourceID: "pair_ever",
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

                        // 2. Give Zego time to clean up and trigger onCallEnd
                        await Future.delayed(
                          const Duration(milliseconds: 1200),
                        );

                        // 3. Trigger our end logic
                        final callData = CallService().endCall();

                        if (callData != null) {
                          debugPrint("✅ endCall() executed from timer");
                        }
                      } catch (e) {
                        debugPrint("❌ Error during timer end: $e");
                        // Fallback
                        CallService().endCall();
                      }
                    },
                  );
                }
              : null,
          child: Container(
            height: 50,
            width: fillWidth ? double.infinity : null,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0XFF3f353f),
                  Color(0XFF433b3a),
                  Color(0XFF3f353f),
                ],
              ),
              color: isEnabled
                  ? const Color(0xFF373031)
                  : const Color(0xFF373031).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEnabled
                    ? const Color(0xFFd2ea46)
                    : const Color(0xFF2A1F38),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset(
                    "assets/Images/heartcoin.png",
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => Icon(
                      isVideoCall
                          ? Icons.videocam_rounded
                          : Icons.phone_rounded,
                      color: isEnabled
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF4A3A5A),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  coinText,
                  style: TextStyle(
                    color: isEnabled
                        ? const Color(0xFFd7ef51)
                        : const Color(0xFFd7ef51).withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  min,
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Center(
                  child: Image.asset(
                    isVideoCall
                        ? "assets/Images/video.png"
                        : "assets/Images/call.png",
                    width: 30,
                    height: 30,
                    errorBuilder: (_, __, ___) => Icon(
                      isVideoCall
                          ? Icons.videocam_rounded
                          : Icons.phone_rounded,
                      color: isEnabled
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF4A3A5A),
                      size: 18,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// INTEREST TAG
// ─────────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF48228a), // Purple
            Color(0xFF7b3aed), // Lime Green (your accent color)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF211733), // Purple
              Color(0xFF2b1d45), // Lime Green (your accent color)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
