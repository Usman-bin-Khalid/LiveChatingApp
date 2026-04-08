import 'package:flutter/material.dart';
import '../data/models/conversation_model.dart';
import '../data/models/message_model.dart';
import '../data/repositories/chat_repository.dart';
import '../data/services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final SocketService _socketService;
  
  List<ConversationModel> _inbox = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  ChatProvider(this._chatRepository, this._socketService) {
    _socketService.messages.listen((message) {
      // Only add to messages if it belongs to current active chat
      // For simplicity, we add it and UI handles filtering or we can store currentChatId
      _messages.add(message);
      notifyListeners();
      fetchInbox(); // Refresh inbox to see latest message
    });
  }

  List<ConversationModel> get inbox => _inbox;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> fetchInbox() async {
    _isLoading = true;
    notifyListeners();
    try {
      _inbox = await _chatRepository.getInbox();
    } catch (e) {
      print('Fetch inbox error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String otherUserId) async {
    _isLoading = true;
    _messages = [];
    notifyListeners();
    try {
      _messages = await _chatRepository.getMessages(otherUserId);
    } catch (e) {
      print('Fetch messages error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sendMessage(String senderId, String receiverId, String text) {
    _socketService.sendMessage(senderId, receiverId, text);
    // Optimistic update
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: senderId,
      receiver: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );
    _messages.add(newMessage);
    notifyListeners();
  }
  
  void connectSocket(String userId) {
    _socketService.connect(userId);
  }
  
  void disconnectSocket() {
    _socketService.disconnect();
  }
}
