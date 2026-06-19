import 'package:dude/DudeScreens/Chat/backend_chat_service.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class staffChatDetailScreen extends StatefulWidget {
  final String conversationID;
  final String peerMemberID;
  final String name;

  const staffChatDetailScreen({
    super.key,
    required this.conversationID,
    this.peerMemberID = '',
    required this.name,
  });

  @override
  State<staffChatDetailScreen> createState() => _staffChatDetailScreenState();
}

class _staffChatDetailScreenState extends State<staffChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  String _conversationId = '';
  String _myMemberId = '';
  bool _isChatLoading = true;
  bool _isSending = false;
  List<BackendChatMessage> _messages = [];
  BackendChatUnsubscribe? _unsubscribeNewMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackendChat();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _unsubscribeNewMessage?.call();
    super.dispose();
  }

  Future<void> _initializeBackendChat() async {
    if (!mounted) return;

    final staffVM = context.read<StaffViewModel>();
    if (staffVM.currentStaff == null) {
      await staffVM.fetchStaffDetails();
    }

    final staff = staffVM.currentStaff;
    if (staff == null || staff.memberID.isEmpty) return;
    _myMemberId = staff.memberID;

    if (widget.peerMemberID.isNotEmpty &&
        widget.conversationID != widget.peerMemberID) {
      _conversationId = widget.conversationID;
    } else {
      final conversation = await BackendChatService.instance.createConversation(
        userMemberID: widget.peerMemberID.isNotEmpty
            ? widget.peerMemberID
            : widget.conversationID,
        staffMode: true,
      );
      _conversationId = conversation.id.isNotEmpty
          ? conversation.id
          : widget.conversationID;
    }

    await BackendChatService.instance.joinSocket(
      actorId: staff.memberID,
      conversationId: _conversationId,
      userId: widget.peerMemberID.isNotEmpty
          ? widget.peerMemberID
          : widget.conversationID,
    );
    _unsubscribeNewMessage?.call();
    _unsubscribeNewMessage = BackendChatService.instance.onNewMessage(
      _handleIncomingMessage,
    );

    final messages = await BackendChatService.instance.getMessages(
      _conversationId,
    );
    await BackendChatService.instance.markRead(_conversationId);

    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isChatLoading = false;
    });
    _scrollToBottom();
  }

  void _handleIncomingMessage(BackendChatMessage message) {
    if (!mounted) return;
    if (message.conversationId.isNotEmpty &&
        message.conversationId != _conversationId) {
      return;
    }
    if (_messages.any((item) => item.id.isNotEmpty && item.id == message.id)) {
      return;
    }
    final localIndex = _messages.indexWhere(
      (item) =>
          item.id.startsWith('local-') &&
          item.message == message.message &&
          message.isMine(true, _myMemberId),
    );
    setState(() {
      if (localIndex == -1) {
        _messages.add(message);
      } else {
        _messages[localIndex] = message;
      }
    });
    BackendChatService.instance.markRead(_conversationId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  // BLOCK URLS & PHONE NUMBERS
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // IMPROVED BLOCK: URLs, Phone, Full Instagram Links (Not usernames)
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // STRONGER BLOCK: URLs, Phone, Instagram-style Usernames, etc.
  // ─────────────────────────────────────────────────────────────
  bool _containsBlockedContent(String text) {
    if (text.trim().isEmpty) return false;

    final lower = text.toLowerCase().trim();

    // 1. URLs & Domain Links
    if (lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('www.') ||
        RegExp(
          r'\b[a-zA-Z0-9-]+\.(com|in|net|org|co|io|me|biz|xyz)\b',
        ).hasMatch(text)) {
      return true;
    }

    // 2. ANY DIGIT (Even single number like 1, 2, 123, etc.)
    if (RegExp(r'\d').hasMatch(text)) {
      return true;
    }

    // 3. Social Media & Promotion
    if (lower.contains('instagram') ||
        lower.contains('insta') ||
        lower.contains('whatsapp') ||
        lower.contains('follow') ||
        RegExp(r'@\w{2,}').hasMatch(text) || // @username
        lower.contains('gram_') ||
        lower.contains('onlyfans')) {
      return true;
    }

    // 4. Excessive Special Characters
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]{4,}').hasMatch(text)) {
      return true;
    }

    return false;
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_isChatLoading || _conversationId.isEmpty || _isSending) {
      return;
    }

    if (_containsBlockedContent(text)) {
      Utils.snackBarErrorMessage(
        "Links, phone numbers, Instagram IDs & promotional content not allowed",
      );
      return;
    }

    final optimistic = BackendChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: _conversationId,
      message: text,
      messageType: 'text',
      senderType: 'staff',
      senderId: _myMemberId,
      createdAt: DateTime.now(),
    );

    _textController.clear();
    setState(() {
      _isSending = true;
      _messages.add(optimistic);
    });
    _scrollToBottom();

    try {
      await BackendChatService.instance.sendMessageSocket(
        _conversationId,
        text,
        notificationData: _chatNotificationData(text),
      );
    } catch (e) {
      try {
        final saved = await BackendChatService.instance.sendMessageRest(
          _conversationId,
          text,
        );
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere(
              (item) => item.id == optimistic.id,
            );
            if (index != -1) _messages[index] = saved;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _messages.removeWhere((item) => item.id == optimistic.id),
          );
          Utils.snackBarErrorMessage("Failed to send message");
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Map<String, dynamic> _chatNotificationData(String text) {
    final staff = context.read<StaffViewModel>().currentStaff;
    final senderName = staff?.name.trim().isNotEmpty == true
        ? staff!.name.trim()
        : 'Staff';
    final receiverId = widget.peerMemberID.isNotEmpty
        ? widget.peerMemberID
        : widget.conversationID;

    return {
      'senderId': _myMemberId,
      'senderMemberID': _myMemberId,
      'senderRole': 'staff',
      'senderType': 'staff',
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverMemberID': receiverId,
      'receiverRole': 'user',
      'receiverType': 'user',
      'staffMemberID': _myMemberId,
      'userMemberID': receiverId,
      'screen': 'chat',
      'type': 'chat',
      'title': senderName,
      'body': text,
      'notification': {'title': senderName, 'body': text},
      'data': {
        'screen': 'chat',
        'conversationId': _conversationId,
        'conversationID': _conversationId,
        'senderId': _myMemberId,
        'senderUserID': _myMemberId,
        'senderName': senderName,
        'staffMemberID': _myMemberId,
        'receiverRole': 'user',
        'isStaff': false,
      },
    };
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          "No messages yet",
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.isMine(true, _myMemberId);
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFFB86AF6) : const Color(0xFF2A1F38),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
            ),
            child: Text(
              message.message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        );
      },
    );
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
              // Top Bar (same as before)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F38),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF3A2A4A),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFB86AF6),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7DFF63),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Active now",
                                style: TextStyle(
                                  color: Color(0xFF7DFF63),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: !_isChatLoading
                    ? _buildMessageList()
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB86AF6),
                        ),
                      ),
              ),

              // Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1426),
                  border: Border(
                    top: BorderSide(color: Color(0xFF2E2040), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F38),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF3A2A4A)),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: TextStyle(color: Color(0xFF6B5F7A)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFB86AF6), Color(0xFF7B4DFF)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
