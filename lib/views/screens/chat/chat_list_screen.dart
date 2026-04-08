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

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Local filtering of inbox only
    final filteredInbox = chatProvider.inbox.where((conv) {
      final query = _searchController.text.toLowerCase();
      return conv.contactDetails.username.toLowerCase().contains(query) ||
             conv.contactDetails.email.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (value) => setState(() {}),
              )
            : const Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: () => themeProvider.toggleTheme(),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => authProvider.logout(),
            ),
          ],
        ],
      ),
      body: chatProvider.isLoading && chatProvider.inbox.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => chatProvider.fetchInbox(),
              child: filteredInbox.isEmpty
                  ? _buildEmptyState(theme, _isSearching)
                  : ListView.builder(
                      itemCount: filteredInbox.length,
                      itemBuilder: (context, index) {
                        final conversation = filteredInbox[index];
                        return _buildConversationTile(theme, conversation, index);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatModal(context),
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.person_search_rounded : Icons.chat_bubble_outline_rounded,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(isSearching ? 'No matching contacts found' : 'No conversations yet'),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ThemeData theme, ConversationModel conversation, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
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
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
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
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
      ),
    );
  }

  void _showNewChatModal(BuildContext context) {
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
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Start New Chat',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by username or email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: theme.colorScheme.primary.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        authProvider.searchUsers(value);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (auth.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (auth.searchResults.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_add_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'Search for people to chat with'
                                      : 'No users found with that name/email',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: auth.searchResults.length,
                          itemBuilder: (context, index) {
                            final user = auth.searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.email),
                              trailing: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.primary, size: 20),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      conversation: ConversationModel(
                                        id: '',
                                        lastMessage: '',
                                        timestamp: DateTime.now(),
                                        contactDetails: user,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.1);
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
    ).then((_) => authProvider.searchUsers(''));
  }
}
