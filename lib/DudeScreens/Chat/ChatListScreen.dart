// lib/DudeScreens/Chat/ChatListScreen.dart

import 'dart:async';
import 'dart:ui';

import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/Chat/ChatDetailScreen.dart';
import 'package:dude/DudeScreens/Chat/backend_chat_service.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  final bool backPage;
  const ChatListScreen({super.key, required this.backPage});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  bool isSearchActive = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showChatList = false;
  String _searchQuery = '';
  List<BackendChatConversation> _conversations = [];
  BackendChatUnsubscribe? _unsubscribeNewMessage;
  Timer? _conversationRefreshDebounce;
  Timer? _relativeTimeTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRelativeTimeTicker();
    _initializeScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyConnectionOnResume();
    }
  }

  // ✅ FIX 2: On resume, only reconnect if truly disconnected.
  //    Never reset _showChatList or call _initializeScreen() wholesale.
  Future<void> _verifyConnectionOnResume() async {
    await _loadConversations(showLoader: false);
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showChatList = false;
    });

    try {
      final userVM = Provider.of<UserViewModel>(context, listen: false);

      // Ensure user is loaded
      if (userVM.currentUser == null) {
        debugPrint("⏳ Fetching user details...");
        await userVM.fetchUserDetails();
      }

      final user = userVM.currentUser;
      if (user == null) {
        throw Exception("User not found");
      }

      await BackendChatService.instance.registerSocket(user.memberID);
      _subscribeToConversationUpdates();
      _conversations = await BackendChatService.instance.getConversations(
        staffMode: false,
      );

      if (mounted) {
        setState(() {
          _showChatList = true;
          _isLoading = false;
        });

        // debugPrint("✅ Ready to show chat list for: ${user.memberID}");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error: $e");
      debugPrint("Stack trace: $stackTrace");

      if (mounted) {
        setState(() {
          _errorMessage = e.toString().split('\n').first;
          _isLoading = false;
          _showChatList = false;
        });
      }
    }
  }

  Future<void> _retryConnection() async {
    await _initializeScreen();
  }

  Future<void> _loadConversations({bool showLoader = true}) async {
    if (!mounted) return;
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final conversations = await BackendChatService.instance.getConversations(
        staffMode: false,
      );
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _showChatList = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToConversationUpdates() {
    _unsubscribeNewMessage ??= BackendChatService.instance
        .onConversationChanged(() {
          _scheduleConversationRefresh();
        });
  }

  void _scheduleConversationRefresh() {
    _conversationRefreshDebounce?.cancel();
    _conversationRefreshDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadConversations(showLoader: false);
    });
  }

  void _startRelativeTimeTicker() {
    _relativeTimeTicker?.cancel();
    _relativeTimeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _conversationRefreshDebounce?.cancel();
    _relativeTimeTicker?.cancel();
    _unsubscribeNewMessage?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel, StaffViewModel>(
      builder: (context, userVM, staffVM, child) {
        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingView()
                        : _errorMessage != null
                        ? _buildErrorView()
                        : _showChatList
                        ? _buildChatList(userVM, staffVM)
                        : _buildConnectingView(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => bondNavigator.newPageRemoveUntil(
              context,
              page: MainBottomBar(),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(40),
              ),
              padding: const EdgeInsets.all(8.0),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          if (!isSearchActive) ...[
            const SizedBox(width: 15),
            AppText(
              "Chat",
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            const Spacer(),
          ],
          if (!isSearchActive)
            IconButton(
              onPressed: () => setState(() => isSearchActive = true),
              tooltip: 'Search chats',
              icon: const Icon(
                Icons.search_rounded,
                color: DudeTheme.textPrimary,
                size: 26,
              ),
            ),
          if (isSearchActive) ...[
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: DudeTheme.cardGradient,
                      border: Border.all(
                        color: DudeTheme.accent.withValues(alpha: 0.75),
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search by name',
                        hintStyle: TextStyle(
                          color: DudeTheme.textMuted,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: DudeTheme.textMuted,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                      onChanged: (value) => setState(
                        () => _searchQuery = value.trim().toLowerCase(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  isSearchActive = false;
                  _searchQuery = '';
                });
              },
              tooltip: 'Close search',
              icon: const Icon(
                Icons.close_rounded,
                color: DudeTheme.textPrimary,
                size: 26,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          AppText(
            "Loading...",
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          AppText(
            "Connecting to chat service...",
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          AppText(
            "Connection Failed",
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AppText(
              _errorMessage ?? "Unable to connect",
              fontSize: 15,
              color: Colors.white54,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: DudeTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(UserViewModel userVM, StaffViewModel staffVM) {
    final items = _conversations
        .where((item) => item.peerName.toLowerCase().contains(_searchQuery))
        .toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            AppText(
              "No chats yet",
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
            const SizedBox(height: 8),
            AppText(
              "Start a conversation with someone",
              fontSize: 15,
              color: Colors.white54,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadConversations(showLoader: false),
      color: DudeTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: PremiumAnimations.scrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final conversation = items[index];
          final staffId = conversation.peerId.isNotEmpty
              ? conversation.peerId
              : staffVM.getStaffIdByMemberId(conversation.peerMemberId) ??
                    conversation.peerMemberId;
          return PremiumStaggerItem(
            index: index.clamp(0, 12),
            child: _ConversationTile(
              conversation: conversation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      conversationID: conversation.id,
                      peerMemberID: conversation.peerMemberId,
                      name: conversation.peerName,
                      staffId: staffId,
                      imageUrl: conversation.peerImage,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _loadConversations(showLoader: false);
                });
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final BackendChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeLabel = HistoryTimeFormatter.timeAgo(conversation.lastMessageAt);

    return PremiumGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: DudeTheme.surfaceRaised,
            backgroundImage: conversation.peerImage.isEmpty
                ? null
                : NetworkImage(conversation.peerImage),
            child: conversation.peerImage.isEmpty
                ? Text(
                    conversation.peerName.isEmpty
                        ? 'C'
                        : conversation.peerName.characters.first,
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.peerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  conversation.lastMessage.isEmpty
                      ? 'No messages yet'
                      : conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (timeLabel.isNotEmpty || conversation.unreadCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeLabel.isNotEmpty)
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: DudeTheme.premiumAccentGradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: DudeTheme.accentGlowShadow(blur: 8),
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
