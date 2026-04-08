import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/theme_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.connectSocket(authProvider.user!.id);
        chatProvider.fetchInbox();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: chatProvider.isLoading && chatProvider.inbox.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => chatProvider.fetchInbox(),
              child: chatProvider.inbox.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('No conversations yet'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatProvider.inbox.length,
                      itemBuilder: (context, index) {
                        final conversation = chatProvider.inbox[index];
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(conversation: conversation),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              conversation.contactDetails.username[0].toUpperCase(),
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            conversation.contactDetails.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            DateFormat.jm().format(conversation.timestamp),
                            style: theme.textTheme.bodySmall,
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show user selection or search to start a new chat
          _showNewChatDialog(context);
        },
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    // This would ideally search users from API
    // For now, let's keep it simple
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Start New Chat'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter User ID to chat',
              labelText: 'User ID',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context);
                  // Push to detail screen with a placeholder conversation or just the recipient ID
                  // In a real app, you'd fetch user details first
                }
              },
              child: const Text('Chat'),
            ),
          ],
        );
      },
    );
  }
}
