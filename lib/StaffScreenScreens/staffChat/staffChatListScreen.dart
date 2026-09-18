// lib/StaffScreens/StaffChatListScreen.dart

import 'dart:async';
import 'dart:ui';

import 'package:dude/DudeScreens/Chat/backend_chat_service.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:dude/Reusable_Widgets/dude_cached_image.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/staffChat/staffChatDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffChatListScreen extends StatefulWidget {
  final bool backPage;
  const StaffChatListScreen({super.key, required this.backPage});

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> {
  bool isSearchActive = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  List<BackendChatConversation> _conversations = [];
  BackendChatUnsubscribe? _unsubscribeNewMessage;
  Timer? _conversationRefreshDebounce;
  Timer? _relativeTimeTicker;

  @override
  void initState() {
    super.initState();
    _startRelativeTimeTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final staffVM = Provider.of<StaffViewModel>(context, listen: false);
      if (staffVM.currentStaff == null) {
        await staffVM.fetchStaffDetails();
      }
      final staff = staffVM.currentStaff;
      if (staff == null) throw Exception('Staff profile not found');

      await BackendChatService.instance.registerSocket(staff.memberID);
      _subscribeToConversationUpdates();
      final conversations = await BackendChatService.instance.getConversations(
        staffMode: true,
      );

      if (mounted) {
        setState(() {
          _conversations = conversations;
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
      _initializeChat(showLoader: false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    widget.backPage
                        ? GestureDetector(
                            onTap: () => bondNavigator.backPage(context),
                            child: _buildBackButton(),
                          )
                        : GestureDetector(
                            onTap: () => bondNavigator.newPageRemoveUntil(
                              context,
                              page: const StaffBottomBar(index: 0),
                            ),
                            child: _buildBackButton(),
                          ),

                    const SizedBox(width: 16),

                    if (!isSearchActive)
                      Text("Chats", style: TextStyle(
                          color: DudeTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () =>
                          setState(() => isSearchActive = !isSearchActive),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DudeTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: DudeTheme.border),
                        ),
                        child: Icon(
                          isSearchActive ? Icons.close : Icons.search,
                          color: DudeTheme.textPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isSearchActive)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: DudeTheme.cardGradient,
                          border: Border.all(
                            color: DudeTheme.border.withOpacity(0.5),
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(
                            () => _searchQuery = value.trim().toLowerCase(),
                          ),
                          style: TextStyle(color: DudeTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Search chats...',
                            hintStyle: TextStyle(
                              color: DudeTheme.textMuted,
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: DudeTheme.textMuted,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: _isLoading
                    ? _buildConnectingView()
                    : _errorMessage != null
                    ? _buildErrorView()
                    : _buildConversationList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: DudeTheme.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: DudeTheme.border),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Icon(
        Icons.arrow_back,
        color: DudeTheme.textPrimary,
        size: 26,
      ),
    );
  }

  Widget _buildConnectingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: DudeTheme.accent),
          SizedBox(height: 20),
          Text(
            "Connecting to chat...",
            style: TextStyle(color: DudeTheme.textMuted, fontSize: 16),
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
            Icons.error_outline,
            color: DudeTheme.danger,
            size: 56,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'Unable to load chats',
              style: TextStyle(color: DudeTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: DudeTheme.accent,
              foregroundColor: DudeTheme.textOnAccent,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    final items = _conversations
        .where((item) => item.peerName.toLowerCase().contains(_searchQuery))
        .toList();
    if (items.isEmpty) return _buildEmptyChatView();

    return RefreshIndicator(
      onRefresh: () => _initializeChat(showLoader: false),
      color: DudeTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: PremiumAnimations.scrollPhysics,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final conversation = items[index];
          return PremiumStaggerItem(
            index: index.clamp(0, 12),
            child: _StaffConversationTile(
              conversation: conversation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => staffChatDetailScreen(
                      conversationID: conversation.id,
                      peerMemberID: conversation.peerMemberId,
                      name: conversation.peerName,
                    ),
                  ),
                ).then((_) {
                  if (mounted) _initializeChat(showLoader: false);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 90,
            color: DudeTheme.textPrimary.withOpacity(0.15),
          ),
          const SizedBox(height: 20),
          Text("No chats yet", style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: DudeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "When users message you, they will appear here",
            style: TextStyle(color: DudeTheme.textSubtle, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StaffConversationTile extends StatelessWidget {
  final BackendChatConversation conversation;
  final VoidCallback onTap;

  const _StaffConversationTile({
    required this.conversation,
    required this.onTap,
  });

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
                : DudeCachedImage.provider(conversation.peerImage),
            child: conversation.peerImage.isEmpty
                ? Text(
                    conversation.peerName.isEmpty
                        ? 'C'
                        : conversation.peerName.characters.first,
                    style: TextStyle(color: DudeTheme.textPrimary),
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
                  style: TextStyle(
                    color: DudeTheme.textPrimary,
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
                  style: TextStyle(
                    color: DudeTheme.textMuted,
                    fontSize: 13,
                  ),
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
                    style: TextStyle(
                      color: DudeTheme.textSubtle,
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
                      style: TextStyle(
                        color: DudeTheme.textOnAccent,
                        fontSize: 12,
                      ),
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
