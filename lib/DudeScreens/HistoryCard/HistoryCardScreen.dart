// lib/DudeScreens/HistoryScreen/HistoryScreen.dart

import 'dart:async';
import 'dart:ui';

import 'package:dude/DudeScreens/Chat/ChatDetailScreen.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/DudeScreens/ProfileScreen/ProfileScreen.dart';
import 'package:dude/DudeScreens/WalletScreen/WalletScreen.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/shimmer_loader.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  final CallService _callService = CallService();
  final socketService = SocketService();
  bool _isInitialized = false;
  bool _isSocketInitialized = false;

  // ─── Search ─────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // For listening to room state changes
  VoidCallback? _roomStateListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CallService().onCallEnded.listen((callData) {
      if (!mounted) return;

      final userVM = context.read<UserViewModel>();

      final spent = callData['spent'] as int;
      final durationSeconds = callData['durationSeconds'] as int;
      final staffId = callData['staffId'] as String;
      final isVideo = callData['isVideoCall'] as bool;
      final callID = callData['callID']?.toString();

      final currentBalance = userVM.currentUser?.coinBalance ?? 0;
      final newBalance = currentBalance - spent;

      debugPrint("💳 Updating balance: $currentBalance → $newBalance");

      userVM
          .updateUserCoinBalance(
            newBalance,
            staffId,
            spent,
            durationSeconds.toString(),
            isVideo ? "video" : "audio",
            callID,
          )
          .then((_) {
            userVM.updateLocalCoinBalance(newBalance);
          });
    });

    _addCallEventListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
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

  void _onRoomStateChanged(ZegoUIKitRoomState state) {
    debugPrint("📞 HistoryScreen: Room state changed → ${state.reason}");
    _callService.updateRoomState(
      state.reason == ZegoRoomStateChangedReason.Logined,
    );

    if (state.reason == ZegoRoomStateChangedReason.Logout) {
      debugPrint("📞 HistoryScreen: Room logout detected");
      CallService().endCall();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    if (_roomStateListener != null) {
      final roomStateNotifier = ZegoUIKit().getRoomStateStream();
      roomStateNotifier?.removeListener(_roomStateListener!);
    }

    _searchController.dispose();
    _debounce?.cancel();
    _callService.cancelCallTimer();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    if (_isInitialized) return;

    try {
      final userVM = context.read<UserViewModel>();

      if (userVM.currentUser == null) {
        await userVM.fetchUserDetails();
      }

      final user = userVM.currentUser;
      if (user == null) return;

      debugPrint("HistoryScreen: User fetched → memberID: ${user.memberID}");

      await _initializeSocketConnection();

      setState(() {
        _isInitialized = true;
      });
    } catch (e, stackTrace) {
      debugPrint("Error initializing HistoryScreen: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  Future<void> _initializeSocketConnection() async {
    final staffVM = context.read<StaffViewModel>();

    if (staffVM.staffList.isEmpty) {
      await staffVM.fetchStaffDetails();
    }

    if (staffVM.staffList.isNotEmpty && !_isSocketInitialized) {
      final staffID = staffVM.staffList.first.memberID;

      debugPrint("🔌 HistoryScreen: Connecting socket as staff → $staffID");

      socketService.connectStaff(staffID);

      socketService.listenStaffList((data) {
        debugPrint("📡 HistoryScreen: Real-time staff list update received");
        if (mounted) {
          staffVM.updateStaffPresence(data);
        }
      });

      setState(() {
        _isSocketInitialized = true;
      });
    }
  }

  void _handleCallEnd(String staffId, bool isVideoCall) {
    if (!_callService.isCallActive) return;

    final callStartTime = _callService.callStartTime;
    if (callStartTime == null) {
      _callService.resetCall();
      return;
    }

    final now = DateTime.now();
    final durationSeconds = now.difference(callStartTime).inSeconds;

    if (!_callService.wasCallReallyConnected) {
      _callService.resetCall();
      return;
    }

    _callService.cancelCallTimer();

    final spent = CallService.calculateSpentCoins(
      durationSeconds: durationSeconds,
      pricePerMin: _callService.currentCallPricePerMin ?? 0,
    );

    final userVM = context.read<UserViewModel>();
    final currentBalance = userVM.currentUser?.coinBalance ?? 0;
    final newBalance = currentBalance - spent;

    debugPrint(
      "💳 Updating balance: $currentBalance → $newBalance (spent: $spent)",
    );

    userVM
        .updateUserCoinBalance(
          newBalance,
          staffId,
          spent,
          durationSeconds.toString(),
          isVideoCall ? "video" : "audio",
          _callService.currentCallID,
        )
        .then((_) {
          userVM.updateLocalCoinBalance(newBalance);
        })
        .catchError((error) {
          debugPrint("❌ Failed to update balance: $error");
        });

    _callService.resetCall();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final staffVM = context.read<StaffViewModel>();
      if (staffVM.staffList.isNotEmpty) {
        final staffID = staffVM.staffList.first.memberID;
        socketService.connectStaff(staffID);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel, StaffViewModel>(
      builder: (context, userVM, staffVM, child) {
        final currentUser = userVM.currentUser;

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
                  Color(0xFF241b40),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Header ─────────────────────────────────────
                  _buildHeader(currentUser),

                  const SizedBox(height: 20),

                  // ── Search Bar ─────────────────────────────────
                  _buildSearchField(),

                  const SizedBox(height: 16),

                  // ── Staff List ─────────────────────────────────
                  Expanded(child: _buildStaffList(staffVM, userVM)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(UserProfile? currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo or Title (you can change if needed)
          SvgPicture.asset("assets/Images/dude.svg", height: 45),

          const Spacer(),

          // Coin Balance
          GestureDetector(
            onTap: () =>
                bondNavigator.newPage(context, page: const WalletScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2c1e4f),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFe4f773), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9F155),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.black,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset("assets/Images/paircoin.png", height: 18),
                  const SizedBox(width: 6),
                  Text(
                    "${currentUser?.coinBalance ?? 0}.00",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Profile Avatar
          GestureDetector(
            onTap: () => bondNavigator.newPage(
              context,
              page: const ProfileScreen(backPage: true),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage:
                  (currentUser?.image != null && currentUser!.image!.isNotEmpty)
                  ? NetworkImage(currentUser.image!)
                  : const AssetImage("assets/Images/men.png") as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1426),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2E2040), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by name, call topics...',
            hintStyle: const TextStyle(color: Color(0xFF6B5F7A), fontSize: 14),
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
                      _searchController.clear();
                      context.read<StaffViewModel>().updateSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 400), () {
              context.read<StaffViewModel>().updateSearchQuery(value);
            });
          },
        ),
      ),
    );
  }

  Widget _buildStaffList(StaffViewModel staffVM, UserViewModel userVM) {
    if (!_isInitialized ||
        (staffVM.isFetchingStaff && staffVM.staffList.isEmpty)) {
      return _buildHistoryCardShimmerList();
    }

    if (staffVM.staffFetchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await staffVM.fetchStaffDetails();
                if (!_isSocketInitialized) await _initializeSocketConnection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0XFFbcd71c),
              ),
              child: Text("Retry", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (staffVM.staffList.isEmpty) {
      return Center(
        child: Text(
          staffVM.searchQuery.isEmpty
              ? "No history available"
              : "No results found",
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          staffVM.fetchStaffDetails(),
          userVM.fetchUserDetails(),
        ]);
        if (!_isSocketInitialized) await _initializeSocketConnection();
      },
      color: Colors.white,
      backgroundColor: Colors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: staffVM.staffList.length,
        itemBuilder: (context, index) {
          final staff = staffVM.staffList[index];
          return _buildProfileCard(staff, userVM);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Updated Profile Card - Matching HomeScreen Style
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHistoryCardShimmerList() {
    return ShimmerLoader(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => _historyCardShimmer(),
      ),
    );
  }

  Widget _historyCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0XFF1c122d), Color(0XFF1c122e), Color(0XFF261247)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A1F38), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _shimmerBox(
                width: 70,
                height: 70,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(16),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: _shimmerBox(width: 13, height: 13, radius: 7),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 13, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 130, height: 16, radius: 5),
                  const SizedBox(height: 10),
                  _shimmerBox(width: 78, height: 13, radius: 5),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
            child: _shimmerBox(width: 112, height: 40, radius: 8),
          ),
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

  Widget _buildProfileCard(StaffDataProfile staff, UserViewModel userVM) {
    final age = _calculateAge(staff.dob ?? '');

    Color statusColor;
    String statusText;

    if (staff.isBusy) {
      statusColor = const Color(0xFFE8A020);
      statusText = "On Call";
    } else if (staff.isOnline) {
      statusColor = const Color(0xFF7dff63);
      statusText = "Online";
    } else {
      statusColor = const Color(0xFFFF3B30);
      statusText = "Offline";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0XFF1c122d),
            Color(0XFF1c122e),
            Color(0XFF1c122e),
            Color(0XFF261247),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A1F38), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(16),
                            topLeft: Radius.circular(16),
                          ),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(16),
                            topLeft: Radius.circular(16),
                          ),
                          child:
                              (staff.image != null && staff.image!.isNotEmpty)
                              ? Image.network(staff.image!, fit: BoxFit.cover)
                              : Image.asset(
                                  "assets/Images/women.png",
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Name + Age
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${staff.name ?? 'Unknown'}, ${age ?? '23'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tamil",
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

              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  top: 12,
                ),
                child: GestureDetector(
                  onTap: () async {
                    if (mounted) {
                      bondNavigator.newPage(
                        context,
                        page: ChatDetailScreen(
                          conversationID: staff.memberID,
                          peerMemberID: staff.memberID,
                          name: staff.name ?? "Staff",
                          staffId: staff.id,
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 40,

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
                      border: Border.all(
                        color: const Color(0xFFd2ea46),

                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText("Chat Now", fontWeight: FontWeight.w700),
                          SizedBox(width: 10),
                          SvgPicture.asset(
                            "assets/Images/chatactive.svg",
                            height: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // Status Badge
          //           Container(
          //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          //             decoration: BoxDecoration(
          //               color: statusColor.withOpacity(0.15),
          //               borderRadius: BorderRadius.circular(6),
          //               border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
          //             ),
          //             child: Row(
          //               mainAxisSize: MainAxisSize.min,
          //               children: [
          //                 Container(
          //                   width: 7,
          //                   height: 7,
          //                   decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          //                 ),
          //                 const SizedBox(width: 5),
          //                 Text(
          //                   statusText,
          //                   style: TextStyle(
          //                     color: statusColor,
          //                     fontSize: 12,
          //                     fontWeight: FontWeight.w600,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),

          // Call Buttons + Chat
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required String text,
    required int pricePerMin,
    required bool isVideoCall,
    required String targetUserID,
    required String targetUserName,
    required String targetStaffId,
  }) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final balance = userVM.currentUser?.coinBalance ?? 0;
        final isEnabled = balance >= pricePerMin;

        return GestureDetector(
          onTap: () {},
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0XFF3f353f),
                  Color(0XFF433b3a),
                  Color(0XFF3f353f),
                ],
              ),
              color: const Color(0xFF373031),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A1F38), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isVideoCall
                      ? "assets/Images/videoicon.svg"
                      : "assets/Images/callicon.svg",
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => Icon(
                    isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                    color: const Color(0xFF4A3A5A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: Color(0xFFd7ef51).withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int? _calculateAge(String dob) {
    if (dob.isEmpty || dob == 'null') return null;
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();

      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTEREST TAG (Updated to match HomeScreen style)
// ─────────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;

  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2a1e42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF723fc9), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
