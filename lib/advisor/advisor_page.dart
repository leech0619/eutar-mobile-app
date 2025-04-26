import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/gemini_service.dart';
import '../utils/pdf_email_service.dart';
import '../utils/auth.dart';  // Import the auth service
import 'model/chat_message.dart';
import 'widgets/message_bubble.dart';
import 'services/chat_session_service.dart'; // Import the chat session service
import '../profile/controller/profile_controller.dart'; // Import ProfileController
import '../profile/model/profile_model.dart'; // Import ProfileModel
import 'package:intl/intl.dart';

class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  _AdvisorPageState createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();
  final AuthService _authService = AuthService();  // Add auth service
  final ProfileController _profileController = ProfileController(); // Add profile controller
  final ChatSessionService _sessionService = ChatSessionService(); // Add session service
  
  late ChatSession _currentSession;
  
  bool _isLoading = false;
  String _emailAddress = '';
  bool _showEmailDialog = false;
  File? _pdfFile;
  final bool _isSendingEmail = false;
  ProfileModel? _userProfile; // Store user profile data
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ChatSession> _chatSessions = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeSession();
    await _getUserEmail();
    await _loadUserProfile();
    await _loadSessions();
    
    setState(() {
      _isInitialized = true;
    });
  }

  // Initialize the current session
  Future<void> _initializeSession() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Try to load the last session
      await _loadSessions();
      if (_chatSessions.isNotEmpty) {
        setState(() {
          _currentSession = _chatSessions.first;
        });
      } else {
        // Create a new session if none exists
        await _createNewSession();
      }
    } catch (e) {
      print('Error initializing session: $e');
      await _createNewSession();
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // Initialize chat if the current session has no messages
      if (_currentSession.messages.isEmpty) {
        await _initializeChat();
      }
    }
  }
  
  // Create a new session
  Future<void> _createNewSession() async {
    try {
      // Create a new session
      _currentSession = await _sessionService.createNewSession();
      
      // Add welcome message to the new session
      setState(() {
        _currentSession.addMessage(ChatMessage(
          text: "Hello! I'm your UTAR Academic Advisor chatbot. How can I help you today? You can ask me about courses, study tips, academic resources, or start a formal Academic Advisor Meeting for more personalized guidance.",
          messageType: MessageType.advisor,
        ));
      });
      
      // Save the session and reload all sessions
      await _sessionService.saveSession(_currentSession);
      await _loadSessions();
      
      // Close the drawer if it's open
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Error creating new session: $e');
    }
  }
  
  // Method to get the current user's email
  Future<void> _getUserEmail() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null && user.email != null) {
        setState(() {
          _emailAddress = user.email!;
        });
      }
    } catch (e) {
      print('Error getting user email: $e');
    }
  }
  
  // Method to load user profile data
  Future<void> _loadUserProfile() async {
    try {
      final profileData = await _profileController.fetchUserData();
      setState(() {
        _userProfile = profileData;
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // More natural, conversational initial message
      final initialMessage = "Hello! I'm your UTAR academic advisor. How can I help you with your studies today? Feel free to ask me about courses, academic policies, or we can have a more structured advising session if you'd like.";
      
      setState(() {
        _currentSession.addMessage(ChatMessage(
          text: initialMessage,
          messageType: MessageType.advisor,
        ));
      });
      
      // Save the updated session
      await _sessionService.saveSession(_currentSession);
    } catch (e) {
      _showErrorSnackBar('Failed to initialize chat: $e');
      // Add a fallback message so the screen isn't empty
      setState(() {
        _currentSession.addMessage(ChatMessage(
          text: "Hello! I'm your UTAR academic advisor. I'm having trouble connecting to my knowledge service at the moment. Please check your API configuration or try again later.",
          messageType: MessageType.advisor,
        ));
      });
      
      // Save the updated session
      await _sessionService.saveSession(_currentSession);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send email automatically when the meeting is complete
  Future<void> _sendEmailAutomatically() async {
    if (_currentSession.meetingState.isMeetingComplete) {
      await Future.delayed(const Duration(milliseconds: 1500));
      
      try {
        // Make sure we have the latest profile data
        if (_userProfile == null) {
          await _loadUserProfile();
        }
        
        // Before sending the email, make sure that we have recommendations generated
        // If there are no messages with recommendation tags, generate them
        bool hasRecommendations = false;
        
        // Check if we have a properly formatted recommendation
        for (final message in _currentSession.messages) {
          if (message.messageType == MessageType.advisor &&
              message.text.contains('### RECOMMENDATIONS SUMMARY ###') &&
              message.text.contains('### END RECOMMENDATIONS ###')) {
            hasRecommendations = true;
            print('Found existing recommendations for PDF');
            break;
          }
        }
        
        // If no recommendations found, generate them now
        if (!hasRecommendations && _currentSession.meetingState.isAllQuestionsAnswered) {
          setState(() {
            _isLoading = true;
          });
          
          // Generate recommendations using all the responses
          final responses = _currentSession.meetingState.getAllResponses();
          final formattedResponses = _currentSession.meetingState.getFormattedResponses();
          
          if (responses.isNotEmpty) {
            try {
              print('Generating recommendations before sending email');
              // Create a prompt specifically for the summary
              String summaryPrompt = '''
              You're a friendly UTAR academic advisor who just finished a conversation with a student named ${_userProfile?.fullName ?? 'the student'}. Create a natural, helpful summary of your discussion that feels like a real advisor wrote it.

              Here's what the student shared during your conversation:
              
              $formattedResponses
              
              Write a personalized summary that covers:
              
              1. Academic Progress: Highlight how they're doing academically and acknowledge their strengths/challenges.
              2. Extracurricular Activities: Note their participation in clubs, societies, sports or other activities at UTAR.
              3. Challenges & Concerns: Address their concerns with empathy.
              4. Goals: Mention their academic and career goals.
              5. Recommendations: Offer 3-4 helpful, specific suggestions tailored to their situation.
              
              IMPORTANT: Begin your response with "### RECOMMENDATIONS SUMMARY ###" and end with "### END RECOMMENDATIONS ###" to make it easy to identify this as the final summary.
              
              Use a warm, supportive tone. Address them by their actual name (${_userProfile?.fullName ?? 'the student'}) instead of using "[Student Name]". Do NOT use placeholder text like [Student Name] or [Your Name] anywhere in your response. Sign the recommendations as "UTAR Academic Advisor" without any placeholder for advisor name.
              
              End by letting them know they can download this summary for their records.
              
              IMPORTANT: Please do not use markdown formatting like asterisks (**) in your response.
              ''';
              
              final recommendationResponse = await _geminiService.getAdvisorResponse(summaryPrompt);
              
              // Add the response to the chat
              setState(() {
                _currentSession.addMessage(ChatMessage(
                  text: recommendationResponse,
                  messageType: MessageType.advisor,
                ));
                _isLoading = false;
              });
              
              // Save the session with the new recommendation message
              await _sessionService.saveSession(_currentSession);
              
            } catch (e) {
              print('Error generating recommendations: $e');
              setState(() {
                _isLoading = false;
              });
            }
          }
        }
        
        // Generate the PDF and send email with user profile data
        await PdfEmailService().generatePdfAndSendEmail(
          _currentSession.messages, 
          _currentSession.meetingState.responses, 
          _userProfile
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your consultation summary has been sent through email!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error sending email: $e');
        
        // Show a different message if no email client was found
        if (e.toString().contains('NoEmailClient')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No email app found. You can share the PDF using other apps.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          // Show general error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send email: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isEmpty) return;
    
    _messageController.clear();
    
    setState(() {
      _currentSession.addMessage(ChatMessage(
        text: messageText,
        messageType: MessageType.user,
      ));
      _isLoading = true;
    });
    
    // Update the title based on the user's message only if it's the first user message
    // or if the title is still a default one
    if (_currentSession.messages.where((m) => m.isUser).length == 1 || 
        _currentSession.title.startsWith("New Chat") || 
        _currentSession.title.startsWith("Chat -")) {
      _currentSession.generateTitle();
    }
    
    // Save the updated session
    await _sessionService.saveSession(_currentSession);
    
    _scrollToBottom();
    
    try {
      String response;
      
      // Check if we're in a meeting and user is trying to end it
      if (_currentSession.meetingState.isInMeeting && 
          _currentSession.meetingState.currentQuestionNumber >= _currentSession.meetingState.categories.length) {
        
        if (messageText.trim().toLowerCase() == 'end') {
          // User correctly typed "end" to finish the session
          _currentSession.meetingState.endMeeting();
          await _sessionService.saveSession(_currentSession);
          
          setState(() {
            _currentSession.addMessage(ChatMessage(
              text: 'Thank you for your time! Your summary will be prepared shortly to send via email.',
              messageType: MessageType.advisor,
            ));
          });
          
          // Generate and send the summary email first
          await _sendEmailAutomatically();
          
          // Now add the end meeting banner after the summary
          setState(() {
            _currentSession.addMessage(ChatMessage(
              text: "SESSION COMPLETED",
              messageType: MessageType.endBanner,
            ));
          });
          
          return;
        } else if (!messageText.toLowerCase().contains('stop')) {
          // User entered something other than "end" or "stop"
          setState(() {
            _currentSession.addMessage(ChatMessage(
              text: "Sorry, I didn't understand. Please type \"end\" to finish the session and receive your summary.",
              messageType: MessageType.advisor,
            ));
            _isLoading = false;
          });
          
          return;
        }
      }
      
      if (_currentSession.meetingState.isInMeeting && messageText.toLowerCase().contains('stop')) {
        _currentSession.meetingState.endMeeting();
        
        response = 'Advisory meeting has been stopped. You can continue chatting with me or start a new meeting later.';
        
        // We'll add the end banner after the response message
      } else if (_currentSession.meetingState.isInMeeting) {
        // Handle meeting response
        _currentSession.meetingState.recordResponse(messageText);
        
        // Get the next question or recommendation based on the current question number
        response = await _geminiService.continueAdvisoryMeeting(
          messageText, 
          _currentSession.meetingState.currentQuestionNumber - 1,
          _currentSession.meetingState.getAllResponses()
        );
        
        // Check if all questions have been answered and we need to prompt for "end"
        // Only add the prompt if the AI response doesn't already mention typing "end"
        if (_currentSession.meetingState.currentQuestionNumber >= _currentSession.meetingState.categories.length &&
            !response.toLowerCase().contains('type "end"') && 
            !response.toLowerCase().contains("type 'end'") &&
            !response.toLowerCase().contains("type end")) {
          response += "\n\nThanks for sharing all that information! To finish this advisory session and get your personalized summary, please type \"end\".";
        }
        
        // Do NOT auto-send summary here!
      } else if (_shouldStartMeeting(messageText)) {
        // Start new meeting
        _currentSession.meetingState.startMeeting();
        
        // Add a banner message to indicate the start of a formal advisory session
        setState(() {
          _currentSession.addMessage(ChatMessage(
            text: "FORMAL ACADEMIC ADVISORY SESSION",
            messageType: MessageType.banner,
          ));
        });
        
        response = _getMeetingIntroduction();
      } else {
        // Regular conversation mode
        response = await _geminiService.getAdvisorResponse(
          "You are an academic advisor chatbot. The student asks: $messageText"
        );
      }
      
      setState(() {
        _currentSession.addMessage(ChatMessage(
          text: response,
          messageType: MessageType.advisor,
         ));
        
        // If we stopped the meeting, add the end banner after the response
        if (_currentSession.meetingState.isMeetingComplete && messageText.toLowerCase().contains('stop')) {
          _currentSession.addMessage(ChatMessage(
            text: "SESSION COMPLETED",
            messageType: MessageType.endBanner,
          ));
        }
      });
      
      // Save the updated session
      await _sessionService.saveSession(_currentSession);
    } catch (e) {
      _showErrorSnackBar('Failed to get response: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  bool _shouldStartMeeting(String message) {
    if (_currentSession.meetingState.isInMeeting) return false;
    
    final List<String> meetingTriggers = [
      'start meeting',
      'begin consultation',
      'formal advisory',
      'academic consultation',
      'start advisory',
      'begin advisory',
      'advisor meeting',
      'start advisor meeting',
      'start an advisor meeting',
      'would like to start an advisor meeting'
    ];
    
    return meetingTriggers.any((trigger) => 
      message.toLowerCase().contains(trigger.toLowerCase()));
  }

  String _getMeetingIntroduction() {
    return "Hi there! Thanks for starting this academic advisory session. I'd like to learn a bit about your academic journey at UTAR so I can provide personalized guidance.\n\nLet's start with your academic progress. How are your classes going this semester? Could you also share your current CGPA and which subjects you're finding most interesting or challenging?";
  }

  // Load all chat sessions
  Future<void> _loadSessions() async {
    final sessions = await _sessionService.getAllSessions();
    setState(() {
      _chatSessions = sessions;
    });
  }

  // Load a specific session
  Future<void> _loadSession(String sessionId) async {
    try {
      final session = await _sessionService.getSession(sessionId);
      if (session != null) {
        setState(() {
          _currentSession = session;
          _isLoading = false;
        });
        
        // Close the drawer
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text(
            'Academic Advisor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 4.0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            // Only show the New Chat button if the user has sent at least one message
            if (_currentSession.messages.any((message) => message.isUser))
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'New Chat',
                onPressed: () {
                  _createNewSession();
                },
              ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'Help',
              onPressed: _showInfoDialog,
            ),
          ],
        ),
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(),
                Expanded(
                  child: _chatSessions.isEmpty || 
                           !_chatSessions.any((session) => 
                               session.messages.any((message) => message.isUser))
                    ? Center(
                        child: Text('No chat history'),
                      )
                    : ListView.builder(
                        // Show all sessions with user messages (including the current session)
                        itemCount: _chatSessions
                            .where((session) => 
                                session.messages.any((message) => message.isUser))
                            .length,
                        itemBuilder: (context, index) {
                          // Get all sessions that have user messages
                          final filteredSessions = _chatSessions
                              .where((session) => 
                                  session.messages.any((message) => message.isUser))
                              .toList();
                          final session = filteredSessions[index];
                          
                          return GestureDetector(
                            onLongPress: () {
                              // Show delete option
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Chat'),
                                  content: Text('Are you sure you want to delete this chat?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteSession(session.id);
                                      },
                                      child: Text('DELETE', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: ListTile(
                              title: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: session.id == _currentSession.id ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              trailing: Text(
                                DateFormat.MMMd().format(session.lastUpdated),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              selected: session.id == _currentSession.id,
                              selectedTileColor: Colors.blue.withOpacity(0.1),
                              onTap: () => _loadSession(session.id),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentSession.meetingState.isInMeeting
                              ? 'Advisory session in progress. Please respond to each question.'
                              : 'Chat with your UTAR advisor or type "start advisor meeting" for a guided session.',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: _currentSession.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icon/advisor.png',
                                width: 120,
                                height: 120,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Starting your advisor consultation...',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              if (_isLoading) const CircularProgressIndicator(),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _currentSession.messages.length,
                          itemBuilder: (context, index) {
                            final message = _currentSession.messages[index];
                            return MessageBubble(message: message);
                          },
                        ),
                ),
                if (_isLoading && !_showEmailDialog)
                  const LinearProgressIndicator(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 3, // Allow text to expand up to 3 lines
                          style: const TextStyle(fontSize: 14.0), // Smaller text size
                          decoration: InputDecoration(
                            hintText: 'Ask your academic advisor...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, // Slightly smaller padding
                              vertical: 8.0,
                            ),
                            isDense: true, // Make the input more compact
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      SizedBox(
                        width: 40.0, // Fixed width
                        height: 40.0, // Fixed height
                        child: FloatingActionButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          backgroundColor: Colors.blueAccent,
                          elevation: 0,
                          mini: true, // Make the button smaller
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20.0, // Smaller icon
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showEmailDialog)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Share Consultation Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Your Email Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onChanged: (value) => _emailAddress = value,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showEmailDialog = false;
                                  });
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _sendEmailAutomatically,
                                icon: const Icon(Icons.email),
                                label: const Text('Send Email'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isLoading && _showEmailDialog)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('UTAR Academic Advisory'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('You can:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Ask questions about UTAR academics'),
                Text('• Get help with UTAR course selection'),
                Text('• Seek advice on career planning at UTAR'),
                Text('• Access UTAR study resources and tips'),
                Text('• Learn about UTAR policies and procedures'),
                SizedBox(height: 16),
                Text('Formal UTAR Advisory Meeting:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('To start a formal UTAR academic advisory meeting, type:'),
                Text('"I would like to start an advisor meeting"', 
                    style: TextStyle(fontStyle: FontStyle.italic)),
                SizedBox(height: 8),
                Text('The meeting will cover:'),
                Text('• Academic Performance (CGPA)'),
                Text('• UTAR Co-curricular Activities'),
                Text('• Professional Development at UTAR'),
                Text('• Problems & Challenges in UTAR'),
                Text('• Future Planning for UTAR Students'),
                SizedBox(height: 12),
                Text('Meeting Summary:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('After completing the meeting, a summary will be automatically sent to your UTAR email.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await _sessionService.deleteSession(sessionId);
      
      // If the current session was deleted, create a new one
      if (_currentSession.id == sessionId) {
        await _createNewSession();
      }
      
      // Reload sessions
      await _loadSessions();
    } catch (e) {
      _showErrorSnackBar('Error deleting session: $e');
    }
  }
}