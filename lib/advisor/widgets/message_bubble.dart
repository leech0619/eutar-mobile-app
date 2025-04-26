import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/chat_message.dart';
import 'meeting_banner.dart';
import 'end_meeting_banner.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  // Helper method to fix text formatting issues
  String _cleanMessageText(String text) {
    // Replace ** with empty string to remove them
    return text.replaceAll('**', '');
  }

  @override
  Widget build(BuildContext context) {
    // If this is a banner message, show the meeting banner
    if (message.messageType == MessageType.banner) {
      return const MeetingBanner();
    }
    
    // If this is an end banner message, show the end meeting banner
    if (message.messageType == MessageType.endBanner) {
      return const EndMeetingBanner();
    }
    
    // If this is a system message, use a special format
    if (message.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.blue.shade700, width: 1),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    
    // Regular user/advisor messages
    final isUser = message.messageType == MessageType.user;
    final bubbleColor = isUser ? Colors.blueAccent : Colors.grey[300];
    final textColor = isUser ? Colors.white : Colors.black87;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isUser
        ? const EdgeInsets.only(left: 50.0, right: 10.0, top: 8.0, bottom: 8.0)
        : const EdgeInsets.only(right: 50.0, left: 10.0, top: 8.0, bottom: 8.0);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: alignment,
            children: [
              Text(
                isUser ? 'You' : 'UTAR Academic Advisor',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                _cleanMessageText(message.text),
                style: TextStyle(
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}