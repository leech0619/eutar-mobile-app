import 'package:flutter/material.dart';
import '../model/chat_message.dart';
import '../services/chat_session_service.dart';

class ChatHistoryDrawer extends StatefulWidget {
  final String currentSessionId;
  final Function(ChatSession) onSessionSelected;
  final Function() onNewSessionCreated;
  final Function(ChatSession) onSessionDeleted;

  const ChatHistoryDrawer({
    super.key,
    required this.currentSessionId,
    required this.onSessionSelected,
    required this.onNewSessionCreated,
    required this.onSessionDeleted,
  });

  @override
  _ChatHistoryDrawerState createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final ChatSessionService _sessionService = ChatSessionService();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _sessionService.getAllSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading sessions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewSession() async {
    try {
      await widget.onNewSessionCreated();
      // Refresh the list after creating a new session
      await _loadSessions();
    } catch (e) {
      print("Error creating new session: $e");
    }
  }

  Future<void> _deleteSession(ChatSession session) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Chat"),
          content: const Text("Are you sure you want to delete this chat?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _sessionService.deleteSession(session.id);
        widget.onSessionDeleted(session);
        
        // Refresh the list after deleting
        await _loadSessions();
      }
    } catch (e) {
      print("Error deleting session: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[100],
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            color: Colors.blueAccent,
            child: Row(
              children: [
                Expanded(
                  child: const Text(
                    "Chat History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'New Chat',
                  onPressed: _createNewSession,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? const Center(child: Text("No chat history yet"))
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final isSelected = session.id == widget.currentSessionId;
                          
                          return Dismissible(
                            key: Key(session.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _deleteSession(session),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Chat"),
                                  content: const Text("Are you sure you want to delete this chat?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                            },
                            child: InkWell(
                              onTap: () {
                                widget.onSessionSelected(session);
                                Navigator.pop(context); // Close the drawer
                              },
                              onLongPress: () {
                                _showSessionOptions(session);
                              },
                              child: Container(
                                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    session.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    session.getPreview(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    _formatDate(session.lastUpdated),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("New Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _createNewSession,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionOptions(ChatSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text("Delete Chat"),
            onTap: () {
              Navigator.pop(context);
              _deleteSession(session);
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
} 