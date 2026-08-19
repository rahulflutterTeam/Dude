import 'package:dude/DudeScreens/Chat/backend_chat_service.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationID;
  final String peerMemberID;
  final String name;
  final String staffId;
  final String? imageUrl;

  const ChatDetailScreen({
    super.key,
    required this.conversationID,
    this.peerMemberID = '',
    required this.name,
    required this.staffId,
    this.imageUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  String _conversationId = '';
  String _myMemberId = '';
  String _peerImageUrl = '';
  bool _isChatLoading = true;
  bool _isSending = false;
  List<BackendChatMessage> _messages = [];
  BackendChatUnsubscribe? _unsubscribeNewMessage;

  @override
  void initState() {
    super.initState();
    _peerImageUrl = widget.imageUrl?.trim() ?? '';
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

  String _resolveStaffImage() {
    final passed = _peerImageUrl.trim();
    if (passed.isNotEmpty) return passed;

    final widgetImage = widget.imageUrl?.trim() ?? '';
    if (widgetImage.isNotEmpty) return widgetImage;

    try {
      final staffVM = context.read<StaffViewModel>();
      final memberId = widget.peerMemberID.isNotEmpty
          ? widget.peerMemberID
          : widget.conversationID;
      for (final staff in staffVM.allStaffList) {
        final matchId =
            widget.staffId.isNotEmpty && staff.id == widget.staffId;
        final matchMember =
            memberId.isNotEmpty && staff.memberID == memberId;
        if (matchId || matchMember) {
          final image = staff.image?.trim() ?? '';
          if (image.isNotEmpty) return image;
        }
      }
    } catch (_) {}
    return '';
  }

  Future<void> _initializeBackendChat() async {
    if (!mounted) return;

    final userVM = context.read<UserViewModel>();
    if (userVM.currentUser == null) {
      await userVM.fetchUserDetails();
    }

    final user = userVM.currentUser;
    if (user == null || user.memberID.isEmpty) return;
    _myMemberId = user.memberID;

    final conversation = await BackendChatService.instance.createConversation(
      staffId: widget.staffId,
      staffMemberID: widget.peerMemberID.isNotEmpty
          ? widget.peerMemberID
          : widget.conversationID,
      staffMode: false,
    );
    _conversationId = conversation.id.isNotEmpty
        ? conversation.id
        : widget.conversationID;
    if (conversation.peerImage.trim().isNotEmpty) {
      _peerImageUrl = conversation.peerImage.trim();
    }

    await BackendChatService.instance.joinSocket(
      actorId: user.memberID,
      conversationId: _conversationId,
      staffId: widget.staffId.isNotEmpty ? widget.staffId : widget.peerMemberID,
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
          message.isMine(false, _myMemberId),
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

  /// Socket may have already saved + pushed the message even when ACK fails.
  Future<bool> _waitForOptimisticSync(String optimisticId) async {
    for (var i = 0; i < 10; i++) {
      if (!mounted) return false;
      if (!_messages.any((item) => item.id == optimisticId)) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return mounted && !_messages.any((item) => item.id == optimisticId);
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

  bool _containsBlockedContent(String text) {
    if (text.trim().isEmpty) return false;

    final lower = text.toLowerCase().trim();

    if (lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('www.') ||
        RegExp(
          r'\b[a-zA-Z0-9-]+\.(com|in|net|org|co|io|me|biz|xyz)\b',
        ).hasMatch(text)) {
      return true;
    }

    if (RegExp(r'\d').hasMatch(text)) {
      return true;
    }

    if (lower.contains('instagram') ||
        lower.contains('insta') ||
        lower.contains('whatsapp') ||
        lower.contains('follow') ||
        RegExp(r'@\w{2,}').hasMatch(text) ||
        lower.contains('gram_') ||
        lower.contains('onlyfans')) {
      return true;
    }

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
        'Links, phone numbers, Instagram IDs & promotional content not allowed',
      );
      return;
    }

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final staffVM = Provider.of<StaffViewModel>(context, listen: false);
    final messageCost = staffVM
        .messageAmount(fallback: 8)
        .round()
        .clamp(1, 999);
    final balance = userVM.currentUser?.coinBalance ?? 0;

    if (balance < messageCost) {
      Utils.snackBarErrorMessage(
        'Insufficient balance! Need $messageCost coins to send a message.',
      );
      return;
    }

    final previousBalance = balance;
    final newBalance = balance - messageCost;
    userVM.updateLocalCoinBalance(newBalance);

    final optimistic = BackendChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: _conversationId,
      message: text,
      messageType: 'text',
      senderType: 'user',
      senderId: _myMemberId,
      createdAt: DateTime.now(),
    );

    _textController.clear();
    setState(() {
      _isSending = true;
      _messages.add(optimistic);
    });
    _scrollToBottom();

    var delivered = false;
    try {
      final saved = await BackendChatService.instance.sendMessageSocket(
        _conversationId,
        text,
        notificationData: _chatNotificationData(text),
      );
      delivered = true;
      if (saved != null && mounted) {
        setState(() {
          final index = _messages.indexWhere(
            (item) => item.id == optimistic.id,
          );
          if (index != -1) _messages[index] = saved;
        });
      }
    } catch (e) {
      // Socket often already saved the message + emitted chat_new_message,
      // but failed to ACK. Wait briefly before REST so we don't double-save.
      delivered = await _waitForOptimisticSync(optimistic.id);
      if (!delivered) {
        try {
          final saved = await BackendChatService.instance.sendMessageRest(
            _conversationId,
            text,
          );
          delivered = true;
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
            Utils.snackBarErrorMessage('Failed to send message');
          }
        }
      }
    } finally {
      if (delivered) {
        final charged = await userVM.updateUserCoinBalance(
          newBalance,
          widget.staffId,
          messageCost,
          '0',
          'chat',
          optimistic.id,
        );
        if (!charged && !userVM.lastBalanceUpdateQueued) {
          userVM.updateLocalCoinBalance(previousBalance);
          if (mounted) {
            Utils.snackBarErrorMessage(
              'Message sent, but charging failed. Balance restored.',
            );
          }
        }
      } else {
        userVM.updateLocalCoinBalance(previousBalance);
      }
      if (mounted) setState(() => _isSending = false);
    }
  }

  Map<String, dynamic> _chatNotificationData(String text) {
    final user = context.read<UserViewModel>().currentUser;
    final senderName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'User';
    final receiverId = widget.peerMemberID.isNotEmpty
        ? widget.peerMemberID
        : widget.staffId;

    return {
      'senderId': _myMemberId,
      'senderMemberID': _myMemberId,
      'senderRole': 'user',
      'senderType': 'user',
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverMemberID': receiverId,
      'receiverRole': 'staff',
      'receiverType': 'staff',
      'staffId': widget.staffId,
      'staffMemberID': receiverId,
      'userMemberID': _myMemberId,
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
        'staffId': widget.staffId,
        'staffMemberID': receiverId,
        'receiverRole': 'staff',
        'isStaff': true,
      },
    };
  }

  Widget _buildStaffAvatar() {
    final imageUrl = _resolveStaffImage();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: DudeTheme.accent.withValues(alpha: 0.55),
          width: 1.4,
        ),
        boxShadow: DudeTheme.accentGlowShadow(blur: 10, spread: -4),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/Images/women.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset('assets/Images/women.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: TextStyle(
            color: DudeTheme.textSubtle.withValues(alpha: 0.9),
            fontSize: 15,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: PremiumAnimations.scrollPhysics,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.isMine(false, _myMemberId);
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: isMine ? DudeTheme.premiumAccentGradient : null,
              color: isMine ? null : DudeTheme.surfaceRaised,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 5),
                bottomRight: Radius.circular(isMine ? 5 : 18),
              ),
              border: isMine
                  ? null
                  : Border.all(
                      color: DudeTheme.border.withValues(alpha: 0.4),
                    ),
              boxShadow: isMine
                  ? DudeTheme.accentGlowShadow(blur: 10, spread: -5)
                  : null,
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isMine ? DudeTheme.textOnAccent : DudeTheme.textPrimary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        );
      },
    );
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
                padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        bondNavigator.backPage(context);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: DudeTheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: DudeTheme.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: DudeTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStaffAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DudeTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: DudeTheme.online,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Active now',
                                style: TextStyle(
                                  color: DudeTheme.online,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
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
              Container(
                height: 1,
                color: DudeTheme.border.withValues(alpha: 0.3),
              ),
              Expanded(
                child: !_isChatLoading
                    ? _buildMessageList()
                    : const Center(
                        child: CircularProgressIndicator(
                          color: DudeTheme.accent,
                          strokeWidth: 2.4,
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                decoration: BoxDecoration(
                  color: DudeTheme.surface.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: DudeTheme.border.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DudeTheme.background.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: DudeTheme.border.withValues(alpha: 0.55),
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            color: DudeTheme.textPrimary,
                            fontSize: 15.5,
                          ),
                          cursorColor: DudeTheme.accent,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: DudeTheme.textSubtle),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _sendMessage();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: DudeTheme.premiumAccentGradient,
                          boxShadow: DudeTheme.accentGlowShadow(
                            blur: 12,
                            spread: -3,
                          ),
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: DudeTheme.textOnAccent,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: DudeTheme.textOnAccent,
                                size: 22,
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
