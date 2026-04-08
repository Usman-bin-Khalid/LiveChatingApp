import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/models/user_model.dart';
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
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
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
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text('No conversations yet'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatProvider.inbox.length,
                      itemBuilder: (context, index) {
                        final conversation = chatProvider.inbox[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 13,
                            ),
                            child:
                                ListTile(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatDetailScreen(
                                              conversation: conversation,
                                            ),
                                          ),
                                        );
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        child: Text(
                                          conversation
                                              .contactDetails
                                              .username[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        conversation.contactDetails.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        conversation.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        DateFormat.jm().format(
                                          conversation.timestamp,
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: (index * 50).ms)
                                    .slideX(begin: 0.1),
                          ),
                        );
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
    final theme = Theme.of(context);
    final authProvider = context.read<AuthProvider>();
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Start New Chat',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.primary.withOpacity(0.05),
                      ),
                      onChanged: (value) {
                        authProvider.searchUsers(value);
                        setState(
                          () {},
                        ); // Update local UI to show loading/results
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (auth.searchResults.isEmpty &&
                            searchController.text.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 48,
                                  color: theme.disabledColor,
                                ),
                                const SizedBox(height: 12),
                                const Text('No users found'),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: auth.searchResults.length,
                          itemBuilder: (context, index) {
                            final user = auth.searchResults[index];
                            return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      user.username[0].toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(user.email),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Start chat with this user
                                    final conversation = ConversationModel(
                                      id: '', // Empty ID means it's a new conversation
                                      lastMessage: '',
                                      timestamp: DateTime.now(),
                                      contactDetails: user,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatDetailScreen(
                                          conversation: conversation,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                .animate()
                                .fadeIn(delay: (index * 30).ms)
                                .slideX(begin: 0.1);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => authProvider.searchUsers('')); // Clear results on close
  }
}
