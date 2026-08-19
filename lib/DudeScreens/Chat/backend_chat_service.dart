import 'dart:async';
import 'dart:convert';

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:http/http.dart' as http;

typedef BackendChatMessageListener = void Function(BackendChatMessage message);
typedef BackendChatConversationListener = void Function();
typedef BackendChatUnsubscribe = void Function();

class BackendChatConversation {
  final String id;
  final String peerId;
  final String peerMemberId;
  final String peerName;
  final String peerImage;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const BackendChatConversation({
    required this.id,
    required this.peerId,
    required this.peerMemberId,
    required this.peerName,
    required this.peerImage,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory BackendChatConversation.fromJson(
    Map<String, dynamic> json, {
    required bool staffMode,
  }) {
    final peer =
        _asMap(staffMode ? json['user'] : json['staff']) ??
        _asMap(staffMode ? json['userSnapshot'] : json['staffSnapshot']) ??
        _asMap(staffMode ? json['userData'] : json['staffData']) ??
        const <String, dynamic>{};
    final last = _asMap(json['lastMessage']);

    return BackendChatConversation(
      id: _string(json['_id'] ?? json['id'] ?? json['conversationId']),
      peerId: _string(peer['_id'] ?? peer['id']),
      peerMemberId: _string(
        peer['memberID'] ?? peer['memberId'] ?? peer['member_id'],
      ),
      peerName: _string(
        peer['name'] ?? peer['userName'] ?? peer['staffName'],
      ).ifEmpty('Chat'),
      peerImage: _string(peer['image'] ?? peer['avatar'] ?? peer['avatarUrl']),
      lastMessage: _string(
        last?['message'] ??
            last?['text'] ??
            json['lastMessageText'] ??
            json['lastMessage'] ??
            '',
      ),
      lastMessageAt: _date(
        last?['createdAt'] ??
            last?['created_at'] ??
            json['lastMessageAt'] ??
            json['updatedAt'] ??
            json['createdAt'],
      ),
      unreadCount: _int(
        staffMode
            ? json['staffUnreadCount'] ??
                  json['unreadForStaff'] ??
                  json['unreadCount']
            : json['userUnreadCount'] ??
                  json['unreadForUser'] ??
                  json['unreadCount'],
      ),
    );
  }
}

class BackendChatMessage {
  final String id;
  final String conversationId;
  final String message;
  final String messageType;
  final String senderType;
  final String senderId;
  final DateTime? createdAt;

  const BackendChatMessage({
    required this.id,
    required this.conversationId,
    required this.message,
    required this.messageType,
    required this.senderType,
    required this.senderId,
    required this.createdAt,
  });

  factory BackendChatMessage.fromJson(Map<String, dynamic> json) {
    return BackendChatMessage(
      id: _string(json['_id'] ?? json['id'] ?? json['messageId']),
      conversationId: _string(json['conversationId'] ?? json['conversation']),
      message: _string(json['message'] ?? json['text'] ?? json['body']),
      messageType: _string(json['messageType'] ?? json['type']).ifEmpty('text'),
      senderType: _string(
        json['senderType'] ?? json['senderRole'] ?? json['from'],
      ),
      senderId: _string(
        json['senderId'] ?? json['sender'] ?? json['senderMemberID'],
      ),
      createdAt: _date(json['createdAt'] ?? json['created_at'] ?? json['time']),
    );
  }

  bool isMine(bool staffMode, String myMemberId) {
    final expectedType = staffMode ? 'staff' : 'user';
    if (senderType.toLowerCase() == expectedType) return true;
    return myMemberId.isNotEmpty && senderId == myMemberId;
  }
}

class BackendChatService {
  BackendChatService._();
  static final BackendChatService instance = BackendChatService._();

  final SocketService _socketService = SocketService();
  final Set<BackendChatMessageListener> _newMessageListeners = {};
  final Set<BackendChatConversationListener> _conversationListeners = {};
  bool _newMessageSocketBound = false;
  bool _conversationSocketBound = false;

  static const List<String> _newMessageEvents = [
    'chat_new_message',
    'new_message',
    'newMessage',
    'message_received',
    'messageReceived',
    'receive_message',
    'receiveMessage',
    'chat_message',
    'chatMessage',
    'conversation_message',
    'conversationMessage',
  ];
  static const List<String> _conversationEvents = [
    'chat_conversation_updated',
    'chatConversationUpdated',
    'conversation_updated',
    'conversationUpdated',
    'conversation_update',
    'conversationUpdate',
    'chat_list_update',
    'chatListUpdate',
  ];

  Future<BackendChatConversation> createConversation({
    String? staffId,
    String? staffMemberID,
    String? userId,
    String? userMemberID,
    required bool staffMode,
  }) async {
    final body = <String, dynamic>{
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      if (staffMemberID != null && staffMemberID.isNotEmpty)
        'staffMemberID': staffMemberID,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (userMemberID != null && userMemberID.isNotEmpty)
        'userMemberID': userMemberID,
    };
    final json = await _request('POST', 'chat/conversation', body: body);
    return BackendChatConversation.fromJson(
      _extractMap(json),
      staffMode: staffMode,
    );
  }

  Future<List<BackendChatConversation>> getConversations({
    required bool staffMode,
  }) async {
    final json = await _request('GET', 'chat/conversation');
    return _extractList(json)
        .whereType<Map>()
        .map(
          (item) => BackendChatConversation.fromJson(
            Map<String, dynamic>.from(item),
            staffMode: staffMode,
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<BackendChatMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 30,
  }) async {
    final json = await _request(
      'GET',
      'chat/conversation/$conversationId/messages?page=$page&limit=$limit',
    );
    final messages = _extractList(json)
        .whereType<Map>()
        .map(
          (item) =>
              BackendChatMessage.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    messages.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });
    return dedupeMessages(messages);
  }

  /// Collapses accidental double-saves (same sender + text within a few seconds).
  static List<BackendChatMessage> dedupeMessages(
    List<BackendChatMessage> messages, {
    Duration window = const Duration(seconds: 8),
  }) {
    if (messages.length < 2) return messages;

    final seenIds = <String>{};
    final result = <BackendChatMessage>[];

    for (final message in messages) {
      if (message.id.isNotEmpty && !seenIds.add(message.id)) continue;

      final duplicateIndex = result.indexWhere((existing) {
        if (existing.message != message.message) return false;
        final sameSender =
            (existing.senderId.isNotEmpty && message.senderId.isNotEmpty)
            ? existing.senderId == message.senderId
            : existing.senderType.toLowerCase() ==
                  message.senderType.toLowerCase();
        if (!sameSender) return false;
        final left = existing.createdAt;
        final right = message.createdAt;
        if (left == null || right == null) return true;
        return left.difference(right).abs() <= window;
      });

      if (duplicateIndex != -1) {
        final existing = result[duplicateIndex];
        // Prefer a real server id over a local placeholder.
        if (existing.id.startsWith('local-') &&
            message.id.isNotEmpty &&
            !message.id.startsWith('local-')) {
          result[duplicateIndex] = message;
        }
        continue;
      }

      result.add(message);
    }

    return result;
  }

  Future<BackendChatMessage> sendMessageRest(
    String conversationId,
    String message, {
    String messageType = 'text',
  }) async {
    final json = await _request(
      'POST',
      'chat/conversation/$conversationId/messages',
      body: {'message': message, 'messageType': messageType},
    );
    return BackendChatMessage.fromJson(_extractMap(json));
  }

  Future<void> markRead(String conversationId) async {
    await _request('POST', 'chat/conversation/$conversationId/read');
  }

  Future<void> registerSocket(String actorId) async {
    final token = await _token();
    await _socketService.ensureConnected(actorId);
    _newMessageSocketBound = false;
    if (_newMessageListeners.isNotEmpty) _bindNewMessageSocketEvents();
    _conversationSocketBound = false;
    if (_conversationListeners.isNotEmpty) _bindConversationSocketEvents();
    final emitted = _socketService.emit('chat_register', {
      if (token.isNotEmpty) 'token': token,
      'actorId': actorId,
    });
    if (!emitted) throw Exception('Socket is not connected');
  }

  Future<void> joinSocket({
    required String actorId,
    String? conversationId,
    String? staffId,
    String? userId,
  }) async {
    final token = await _token();
    await _socketService.ensureConnected(actorId);
    _newMessageSocketBound = false;
    if (_newMessageListeners.isNotEmpty) _bindNewMessageSocketEvents();
    _conversationSocketBound = false;
    if (_conversationListeners.isNotEmpty) _bindConversationSocketEvents();
    final emitted = _socketService.emit('chat_join', {
      if (token.isNotEmpty) 'token': token,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversationId': conversationId,
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    });
    if (!emitted) throw Exception('Socket is not connected');
  }

  Future<BackendChatMessage?> sendMessageSocket(
    String conversationId,
    String message, {
    Map<String, dynamic>? notificationData,
  }) async {
    final token = await _token();
    final payload = {
      if (token.isNotEmpty) 'token': token,
      'conversationId': conversationId,
      'message': message,
      'messageType': 'text',
      if (notificationData != null) ...notificationData,
    };
    final acknowledgement = await _socketService.emitWithAck(
      'chat_send_message',
      payload,
    );
    final ackMap = _asMap(acknowledgement);
    if (ackMap != null && ackMap['status'] == false) {
      throw Exception(
        _string(ackMap['message']).ifEmpty('Message delivery failed'),
      );
    }

    final messageMap = _extractMessageMap(acknowledgement);
    if (messageMap.isEmpty) return null;
    final saved = BackendChatMessage.fromJson(messageMap);
    return saved.message.isEmpty ? null : saved;
  }

  BackendChatUnsubscribe onNewMessage(BackendChatMessageListener listener) {
    _newMessageListeners.add(listener);
    _bindNewMessageSocketEvents();
    return () => _newMessageListeners.remove(listener);
  }

  void offNewMessage([BackendChatMessageListener? listener]) {
    if (listener == null) {
      _newMessageListeners.clear();
      return;
    }
    _newMessageListeners.remove(listener);
  }

  BackendChatUnsubscribe onConversationChanged(
    BackendChatConversationListener listener,
  ) {
    _conversationListeners.add(listener);
    _bindNewMessageSocketEvents();
    _bindConversationSocketEvents();
    return () => _conversationListeners.remove(listener);
  }

  void _bindNewMessageSocketEvents() {
    if (_newMessageSocketBound) return;
    _newMessageSocketBound = true;

    for (final event in _newMessageEvents) {
      _socketService.on(event, (data) {
        final map = _extractMessageMap(data);
        if (map.isEmpty) return;
        final message = BackendChatMessage.fromJson(map);

        for (final listener in List<BackendChatMessageListener>.from(
          _newMessageListeners,
        )) {
          listener(message);
        }
        _notifyConversationListeners();
      });
    }
  }

  void _bindConversationSocketEvents() {
    if (_conversationSocketBound) return;
    _conversationSocketBound = true;

    for (final event in _conversationEvents) {
      _socketService.on(event, (_) => _notifyConversationListeners());
    }
  }

  void _notifyConversationListeners() {
    for (final listener in List<BackendChatConversationListener>.from(
      _conversationListeners,
    )) {
      listener();
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final uri = Uri.parse('${ApiEndPoints().baseUrl}$endpoint');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late http.Response response;
    if (method == 'GET') {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    } else {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 20));
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _string(_asMap(decoded)?['message']).ifEmpty(response.body),
      );
    }
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }

  Future<String> _token() async => (await AuthService.getToken()) ?? '';
}

Map<String, dynamic> _extractMap(dynamic value) {
  final root = _asMap(value);
  if (root == null) return const {};
  for (final key in ['conversation', 'message', 'result']) {
    final nested = _asMap(root[key]);
    if (nested != null) return nested;
  }
  final data = _asMap(root['data']);
  if (data != null) return _extractMap(data);
  return root;
}

Map<String, dynamic> _extractMessageMap(dynamic value) {
  final root = _asMap(value);
  if (root == null) return const {};

  final data = _asMap(root['data']);
  if (data != null) {
    final nested = _extractMessageMap(data);
    if (nested.isNotEmpty) return {...root, ...nested};
  }

  for (final key in ['message', 'chatMessage', 'newMessage', 'result']) {
    final nested = _asMap(root[key]);
    if (nested != null) return {...root, ...nested};
  }

  return root;
}

List<dynamic> _extractList(dynamic value) {
  final root = _asMap(value);
  if (value is List) return value;
  if (root == null) return const [];
  for (final key in ['data', 'conversations', 'messages', 'docs', 'result']) {
    final nested = root[key];
    if (nested is List) return nested;
    final nestedMap = _asMap(nested);
    if (nestedMap != null) {
      for (final childKey in ['data', 'conversations', 'messages', 'docs']) {
        final child = nestedMap[childKey];
        if (child is List) return child;
      }
    }
  }
  return const [];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _string(dynamic value) => value?.toString().trim() ?? '';

int _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

extension _EmptyStringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
