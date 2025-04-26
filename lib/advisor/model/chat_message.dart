enum MessageType { user, advisor, system, banner, endBanner }

class ChatMessage {
  final String text;
  final MessageType messageType;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.messageType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => messageType == MessageType.user;
  bool get isSystem => messageType == MessageType.system;
  
  // Convert ChatMessage to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'messageType': messageType.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  // Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      messageType: MessageType.values[json['messageType']],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class AdvisoryMeetingState {
  bool isInMeeting = false;
  bool isMeetingComplete = false;
  int currentQuestionNumber = 0;
  Map<int, String> responses = {};
  
  // Store questions and responses in key-value pairs for better tracking
  Map<String, String> questionResponses = {
    "Academic Progress": "",
    "Extracurricular Activities": "",
    "Challenges & Concerns": "",
    "Goals": ""
  };
  
  // Categories associated with each question number
  final List<String> categories = [
    "Academic Progress",
    "Extracurricular Activities",
    "Challenges & Concerns", 
    "Goals"
  ];
  
  // Default constructor
  AdvisoryMeetingState();
  
  // Add default constructor for proper serialization
  AdvisoryMeetingState.fromJson(Map<String, dynamic> json) {
    isInMeeting = json['isInMeeting'] as bool? ?? false;
    isMeetingComplete = json['isMeetingComplete'] as bool? ?? false;
    currentQuestionNumber = json['currentQuestionNumber'] as int? ?? 0;
    
    // Handle responses map
    final responsesJson = json['responses'];
    if (responsesJson != null && responsesJson is Map) {
      responsesJson.forEach((key, value) {
        // Convert string keys back to int
        int keyInt = int.tryParse(key.toString()) ?? -1;
        if (keyInt >= 0) {
          responses[keyInt] = value.toString();
        }
      });
    }
  }
  
  void startMeeting() {
    isInMeeting = true;
    isMeetingComplete = false;
    currentQuestionNumber = 0;
    responses = {};
    
    // Reset all question responses
    for (final category in categories) {
      questionResponses[category] = "";
    }
    
    print("Advisory meeting started. Questions will begin at index 0.");
  }
  
  void recordResponse(String response) {
    if (response.trim().isNotEmpty) {
      // Store in both maps for consistency
      responses[currentQuestionNumber] = response;
      
      // Also store in the category-based map if we have a matching category
      if (currentQuestionNumber < categories.length) {
        questionResponses[categories[currentQuestionNumber]] = response;
      }
      
      print("Recorded response for question $currentQuestionNumber (${currentQuestionNumber < categories.length ? categories[currentQuestionNumber] : 'unknown category'})");
    } else {
      print("Warning: Empty response for question $currentQuestionNumber");
    }
    
    // Move to next question
    currentQuestionNumber++;
  }
  
  void endMeeting() {
    isInMeeting = false;
    isMeetingComplete = true;
    print("Meeting ended with $currentQuestionNumber questions answered");
    
    // Debug print all responses
    responses.forEach((key, value) {
      String category = key < categories.length ? categories[key] : "Question $key";
      print("Response for $category: ${value.substring(0, value.length > 30 ? 30 : value.length)}...");
    });
  }
  
  bool get isAllQuestionsAnswered {
    // Check if we have responses for questions 0 through categories.length-1
    for (int i = 0; i < categories.length; i++) {
      if (!responses.containsKey(i) || responses[i]?.trim().isEmpty == true) {
        print("Missing response for question $i (${i < categories.length ? categories[i] : 'unknown'})");
        return false;
      }
    }
    print("All questions have been answered!");
    return true;
  }
  
  // Get all responses for summary generation
  Map<int, String> getAllResponses() {
    return Map.from(responses);
  }
  
  // Format responses as a string for backward compatibility
  String getFormattedResponses() {
    StringBuffer buffer = StringBuffer();
    responses.forEach((questionNum, response) {
      String topic = '';
      // Map question numbers to topics based on order
      if (questionNum < categories.length) {
        topic = categories[questionNum];
      } else {
        topic = "Question $questionNum";
      }
      buffer.write("- $topic: $response\n\n");
    });
    return buffer.toString();
  }
  
  // Add a toJson method that correctly serializes the state
  Map<String, dynamic> toJson() {
    return {
      'isInMeeting': isInMeeting,
      'isMeetingComplete': isMeetingComplete,
      'currentQuestionNumber': currentQuestionNumber,
      'responses': responses.map((key, value) => MapEntry(key.toString(), value)),
    };
  }
}

// Add a class to represent a chat session
class ChatSession {
  String id;
  String title;
  DateTime createdAt;
  DateTime lastUpdated;
  List<ChatMessage> messages = [];
  AdvisoryMeetingState meetingState = AdvisoryMeetingState();

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdated,
    required this.messages,
    required this.meetingState,
  });

  // Create a new empty chat session
  factory ChatSession.create() {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    return ChatSession(
      id: id,
      title: 'New Chat - ${_formatDateTime(now)}',
      createdAt: now,
      lastUpdated: now,
      messages: [],
      meetingState: AdvisoryMeetingState(),
    );
  }

  // Generate a title based on the content of messages
  void generateTitle() {
    if (messages.isEmpty) {
      title = 'New Chat - ${_formatDateTime(createdAt)}';
      return;
    }

    // Find the first user message and use it as the title
    for (final message in messages) {
      if (message.isUser) {
        String text = message.text.trim();
        
        // Extract a meaningful title from the message
        String extractedTitle = _extractTitleFromText(text);
        title = extractedTitle;
        return;
      }
    }

    // Fallback title
    title = 'Chat - ${_formatDateTime(lastUpdated)}';
  }
  
  // Helper method to extract a meaningful title from text
  String _extractTitleFromText(String text) {
    // Remove common question phrases
    final questionsToRemove = [
      'i would like to ask about',
      'can you tell me about',
      'what is',
      'how do i',
      'how can i',
      'tell me about',
      'i want to know about',
      'i want to know',
      'i want to learn about',
      'i want to learn',
      'i need to know about',
      'i need to know',
      'i need information on',
      'i need information about',
      'i need help with',
      'i need help',
      'i have a question about',
      'i have a question',
      'please tell me about',
      'please help me with',
      'could you tell me about',
      'would you tell me about',
      'can you help me with',
      'can you help me',
      'can you explain',
      'please explain',
      'i would like to know about',
      'i would like to know',
      'i would like to',
      'i would like',
      'i would love to know about',
      'i would love to know',
      'i was wondering about',
      'i was wondering',
      'i am wondering about',
      'i am wondering',
      'please',
      'thank you',
      'thanks',
      'hi',
      'hello',
    ];
    
    String cleanedText = text.toLowerCase();
    
    for (final phrase in questionsToRemove) {
      if (cleanedText.startsWith(phrase)) {
        cleanedText = cleanedText.substring(phrase.length).trim();
      }
    }
    
    // Remove punctuation at the end
    if (cleanedText.endsWith('?') || 
        cleanedText.endsWith('.') ||
        cleanedText.endsWith('!')) {
      cleanedText = cleanedText.substring(0, cleanedText.length - 1).trim();
    }
    
    // Capitalize the first letter
    if (cleanedText.isNotEmpty) {
      cleanedText = cleanedText[0].toUpperCase() + 
                    (cleanedText.length > 1 ? cleanedText.substring(1) : '');
    }
    
    // Limit length
    if (cleanedText.length > 30) {
      cleanedText = '${cleanedText.substring(0, 27)}...';
    } else if (cleanedText.isEmpty) {
      // If nothing meaningful remains, use a generic title
      final now = DateTime.now();
      return 'Chat - ${_formatDateTime(now)}';
    }
    
    return cleanedText;
  }

  // Create a session from JSON for storage
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    List<ChatMessage> messages = [];
    if (json['messages'] != null) {
      messages = (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg))
          .toList();
    }

    AdvisoryMeetingState meetingState;
    if (json['meetingState'] != null) {
      meetingState = AdvisoryMeetingState.fromJson(json['meetingState']);
    } else {
      meetingState = AdvisoryMeetingState();
    }

    return ChatSession(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Chat',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
      messages: messages,
      meetingState: meetingState,
    );
  }

  // Convert session to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'meetingState': meetingState.toJson(),
    };
  }

  // Update the lastUpdated timestamp
  void updateTimestamp() {
    lastUpdated = DateTime.now();
  }

  // Add a message to the session
  void addMessage(ChatMessage message) {
    messages.add(message);
    updateTimestamp();
    
    // Only generate a title for the first user message if the title is still default
    if (messages.length <= 3 && message.isUser && 
        (title.startsWith('New Chat') || title.startsWith('Chat -'))) {
      generateTitle();
    }
  }

  // Get a preview of the chat content
  String getPreview() {
    if (messages.isEmpty) return 'No messages yet';
    
    // Find the last message that's not a system message
    for (int i = messages.length - 1; i >= 0; i--) {
      if (!messages[i].isSystem) {
        String preview = messages[i].text;
        if (preview.length > 40) {
          preview = '${preview.substring(0, 40)}...';
        }
        return preview;
      }
    }
    
    return 'Empty chat';
  }

  // Helper method to format datetime
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}