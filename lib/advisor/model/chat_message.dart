enum MessageType { user, advisor, system }

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
    "Academic Performance": "",
    "Co-curricular Activities": "",
    "Professional Development": "",
    "Problems Encountered": "",
    "Future Planning": ""
  };
  
  // Categories associated with each question number
  final List<String> categories = [
    "Academic Performance",
    "Co-curricular Activities",
    "Professional Development", 
    "Problems Encountered",
    "Future Planning"
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
  }
  
  void recordResponse(String response) {
    responses[currentQuestionNumber] = response;
    currentQuestionNumber++;
  }
  
  void endMeeting() {
    isInMeeting = false;
    isMeetingComplete = true;
  }
  
  bool get isAllQuestionsAnswered {
    // Check if we have responses for questions 0 through 4 (all 5 questions)
    for (int i = 0; i < 5; i++) {
      if (!responses.containsKey(i) || responses[i]?.trim().isEmpty == true) {
        return false;
      }
    }
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