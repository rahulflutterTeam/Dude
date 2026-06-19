// lib/StaffScreens/StaffChatListScreen.dart

import 'dart:async';
import 'dart:ui';

import 'package:dude/DudeScreens/Chat/backend_chat_service.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF241b40),
              Color(0xFF1C1426),
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Back Button
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
                      const Text(
                        "Chats",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                    const Spacer(),

                    // Search Icon / Close
                    GestureDetector(
                      onTap: () =>
                          setState(() => isSearchActive = !isSearchActive),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(
                          isSearchActive ? Icons.close : Icons.search,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Field
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
                          color: const Color(0xFF1C1426),
                          border: Border.all(color: const Color(0xFF3A2A4A)),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(
                            () => _searchQuery = value.trim().toLowerCase(),
                          ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search chats...',
                            hintStyle: TextStyle(
                              color: Color(0xFF6B5F7A),
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFFB0A8C0),
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

              // Chat List
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
        color: const Color(0xFF2A1F38),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(8.0),
      child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
    );
  }

  Widget _buildConnectingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFB86AF6)),
          SizedBox(height: 20),
          Text(
            "Connecting to chat...",
            style: TextStyle(color: Colors.white70, fontSize: 16),
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
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'Unable to load chats',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeChat,
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
      color: const Color(0xFFB86AF6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final conversation = items[index];
          final timeLabel = HistoryTimeFormatter.timeAgo(
            conversation.lastMessageAt,
          );
          return ListTile(
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
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF3A2A4A),
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
            title: Text(
              conversation.peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              conversation.lastMessage.isEmpty
                  ? 'No messages yet'
                  : conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFB0A8C0), fontSize: 13),
            ),
            trailing: timeLabel.isEmpty && conversation.unreadCount == 0
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            color: Color(0xFFB0A8C0),
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
                            color: const Color(0xFFB86AF6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
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
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 20),
          const Text(
            "No chats yet",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "When users message you, they will appear here",
            style: TextStyle(color: Color(0xFFB0A8C0), fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
