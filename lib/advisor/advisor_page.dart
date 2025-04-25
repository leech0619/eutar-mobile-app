import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/gemini_service.dart';
import '../utils/pdf_email_service.dart';
import '../utils/auth.dart';  // Import the auth service
import 'model/chat_message.dart';
import 'widgets/message_bubble.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<ChatMessage> _messages = [];
  AdvisoryMeetingState _meetingState = AdvisoryMeetingState();
  bool _isLoading = false;
  String _emailAddress = '';
  bool _showEmailDialog = false;
  File? _pdfFile;
  bool _isSendingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    // Get the user's email address
    _getUserEmail();
  }

  // Method to get the current user's email
  void _getUserEmail() {
    final user = _authService.getCurrentUser();
    if (user != null && user.email != null && user.email!.isNotEmpty) {
      _emailAddress = user.email!;
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
        _messages.add(ChatMessage(
          text: initialMessage,
          messageType: MessageType.advisor,
        ));
      });
    } catch (e) {
      _showErrorSnackBar('Failed to initialize chat: $e');
      // Add a fallback message so the screen isn't empty
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! I'm your UTAR academic advisor. I'm having trouble connecting to my knowledge service at the moment. Please check your API configuration or try again later.",
          messageType: MessageType.advisor,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show email notification instead of PDF instructions
  void _showEmailNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.email, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _emailAddress.isNotEmpty 
                  ? 'Your consultation summary will be sent to $_emailAddress' 
                  : 'A consultation summary will be sent to your email'
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            // Dismiss the snackbar
          },
        ),
      ),
    );
  }

  // Send email automatically when the meeting is complete
  void _sendEmailAutomatically() async {
    // Check if the meeting is complete and all questions have been answered
    if (!_meetingState.isMeetingComplete || !_meetingState.isAllQuestionsAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all questions before sending an email summary.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
      
      // Generate the PDF and send email
      await PdfEmailService().generatePdfAndSendEmail(_messages, _meetingState.responses);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your consultation summary has been prepared for email!'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isEmpty) return;
    
    _messageController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        messageType: MessageType.user,
      ));
      _isLoading = true;
    });
    
    // Save chat history after adding user message
    await _saveChatHistory();
    
    _scrollToBottom();
    
    try {
      String response;
      
      // Check if the user is requesting to start an advisory meeting
      if (!_meetingState.isInMeeting && 
          _containsAdvisoryMeetingRequest(messageText)) {
        // Start the formal advisory meeting process
        _meetingState.startMeeting();
        
        // Add a visual divider to indicate meeting start
        setState(() {
          _messages.add(ChatMessage(
            text: "Starting Academic Advisory Session",
            messageType: MessageType.system,
          ));
        });
        
        // Save chat history after adding system message
        await _saveChatHistory();
        
        response = await _geminiService.startAdvisoryMeeting();
      } 
      // If we're in a meeting, continue with the sequential questions
      else if (_meetingState.isInMeeting) {
        _meetingState.recordResponse(messageText);
        response = await _geminiService.continueAdvisoryMeeting(
          messageText, 
          _meetingState.currentQuestionNumber,
          _meetingState.getAllResponses()
        );
        
        // Check if the meeting is complete - we've gone through all the questions
        if (_meetingState.isAllQuestionsAnswered) {
          // Debug
          print("All questions answered! currentQuestionNumber: ${_meetingState.currentQuestionNumber}");
          
          _meetingState.endMeeting();
          
          // Add a visual divider to indicate meeting end
          setState(() {
            _messages.add(ChatMessage(
              text: "Advisory Session Complete - Summary Available",
              messageType: MessageType.system,
            ));
          });
          
          // Save chat history after adding system message
          await _saveChatHistory();
          
          // Automatically send the email instead of showing a snackbar
          Future.delayed(const Duration(milliseconds: 1500), () {
            _sendEmailAutomatically();
          });
        }
      } 
      // Otherwise, handle as a regular conversation
      else {
        // Regular conversation mode
        response = await _geminiService.getAdvisorResponse(
          "You are an academic advisor chatbot. The student asks: $messageText"
        );
      }
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          messageType: MessageType.advisor,
        ));
      });
      
      // Save chat history after adding advisor message
      await _saveChatHistory();
    } catch (e) {
      _showErrorSnackBar('Failed to get response: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }
  
  bool _containsAdvisoryMeetingRequest(String message) {
    final messageLower = message.toLowerCase();
    return messageLower.contains('academic advisor meeting') || 
           messageLower.contains('aa meeting') ||
           messageLower.contains('advisor meeting') ||
           messageLower.contains('formal meeting') ||
           messageLower.contains('consultation session') ||
           messageLower.contains('advising session') ||
           messageLower.contains('start meeting') ||
           messageLower.contains('begin consultation');
  }
  
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _generateAndSavePdf() async {
    if (_messages.isEmpty) {
      _showErrorSnackBar('No messages to export');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Request storage permission more carefully
      final hasPermission = await _requestStoragePermissionWithRetry();
      if (!hasPermission) {
        _showPermissionDeniedDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final pdfFile = await PdfEmailService.generatePdf(_messages, _meetingState.responses);
      setState(() {
        _pdfFile = pdfFile;
        _showEmailDialog = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to generate PDF: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Improved permission handling with retry
  Future<bool> _requestStoragePermissionWithRetry() async {
    var status = await PdfEmailService.requestStoragePermission();
    
    // If permission is denied but we can request it again
    if (!status) {
      // Show a dialog explaining why we need the permission
      final shouldRetry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Permission Needed'),
          content: const Text(
            'To save your consultation summary as a PDF, the app needs permission to access storage. Please grant this permission in the next dialog.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      ) ?? false;
      
      if (shouldRetry) {
        // Try requesting permission again
        status = await PdfEmailService.requestStoragePermission(forceRequest: true);
      }
    }
    
    return status;
  }
  
  // Show dialog when permission is permanently denied
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Storage permission is required to save PDF files. Please enable it in your device settings:\n\n'
          'Settings > Apps > eUTAR > Permissions > Storage'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) {
      _showErrorSnackBar('No PDF file to share');
      return;
    }

    try {
      await PdfEmailService.sharePdf(_pdfFile!);
    } catch (e) {
      _showErrorSnackBar('Failed to share PDF: $e');
    }
  }

  Future<void> _sendEmailWithPdf() async {
    if (_pdfFile == null) {
      _showErrorSnackBar('No PDF file to send');
      return;
    }

    if (_emailAddress.isEmpty) {
      _showErrorSnackBar('Email address is required');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailAddress)) {
      _showErrorSnackBar('Invalid email address');
      return;
    }

    try {
      setState(() {
        _isSendingEmail = true;
      });

      await PdfEmailService.sendEmail(_pdfFile!, _emailAddress);
      
      setState(() {
        _showEmailDialog = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (e.toString().contains('NoEmailClient')) {
        // Handle the special case - email client not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No email app found. The PDF has been shared using other available apps.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        // Close the email dialog since we've already shared via the fallback method
        setState(() {
          _showEmailDialog = false;
        });
      } else {
        _showErrorSnackBar('Failed to send email: $e');
      }
    } finally {
      setState(() {
        _isSendingEmail = false;
      });
    }
  }

  void _sendPdfEmail() async {
    // First check if all questions have been answered
    if (_messages.length < 6) { // Assuming at least 6 messages would indicate a complete conversation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before sending the consultation summary.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSendingEmail = true;
    });

    try {
      // Generate PDF
      final File pdfFile = await PdfEmailService.generatePdf(_messages, _meetingState.responses);
      
      // Get email from TextField
      final String email = _messageController.text.trim();
      
      // Validate email
      if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }
      
      // Send email with PDF attachment
      await PdfEmailService.sendEmail(pdfFile, email);
      
      setState(() {
        _isSendingEmail = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation summary sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSendingEmail = false;
      });
      
      // Check if it's our special NoEmailClient exception
      if (e.toString().contains('NoEmailClient')) {
        // This is already handled by sharePdf in the service
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    if (_messages.isEmpty) return; // Don't save if there are no messages
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert messages to JSON
      List<Map<String, dynamic>> messagesJson = _messages.map((msg) => msg.toJson()).toList();
      String messagesJsonString = jsonEncode(messagesJson);
      
      // Convert meeting state to JSON
      String meetingStateJsonString = jsonEncode(_meetingState.toJson());
      
      // Save to SharedPreferences
      await prefs.setString('advisor_chat_messages', messagesJsonString);
      await prefs.setString('advisor_meeting_state', meetingStateJsonString);
      
      print('Chat history saved successfully');
    } catch (e) {
      print('Error saving chat history: $e');
      // Don't show error to user as this happens in the background
    }
  }
  
  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load messages
      String? messagesJsonString = prefs.getString('advisor_chat_messages');
      if (messagesJsonString != null && messagesJsonString.isNotEmpty) {
        try {
          List<dynamic> messagesJson = jsonDecode(messagesJsonString) as List<dynamic>;
          List<ChatMessage> loadedMessages = messagesJson
              .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
              .toList();
          
          if (loadedMessages.isNotEmpty) {
            setState(() {
              _messages.clear();
              _messages.addAll(loadedMessages);
            });
          } else {
            _initializeChat(); // If no saved messages, initialize with default
          }
        } catch (e) {
          print('Error parsing saved messages: $e');
          _initializeChat();
        }
      } else {
        _initializeChat(); // If no saved messages, initialize with default
      }
      
      // Load meeting state
      String? meetingStateJsonString = prefs.getString('advisor_meeting_state');
      if (meetingStateJsonString != null && meetingStateJsonString.isNotEmpty) {
        try {
          Map<String, dynamic> meetingStateJson = jsonDecode(meetingStateJsonString) as Map<String, dynamic>;
          setState(() {
            _meetingState = AdvisoryMeetingState.fromJson(meetingStateJson);
          });
        } catch (e) {
          print('Error parsing saved meeting state: $e');
          // Use default meeting state
          setState(() {
            _meetingState = AdvisoryMeetingState();
          });
        }
      }
    } catch (e) {
      print('Error loading chat history: $e');
      _initializeChat(); // Fallback to initialize chat
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Clear chat history
  Future<void> _clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('advisor_chat_messages');
      await prefs.remove('advisor_meeting_state');
      
      setState(() {
        _messages.clear();
        _meetingState = AdvisoryMeetingState();
      });
      
      _initializeChat();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history cleared'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error clearing chat history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing chat history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UTAR Academic Advisor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Add menu with option to clear chat history
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_history') {
                // Show confirmation dialog before clearing
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat History'),
                    content: const Text('Are you sure you want to clear your chat history? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _clearChatHistory();
                        },
                        child: const Text('CLEAR'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat History'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
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
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: _meetingState.isMeetingComplete ? Colors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Tooltip(
              message: 'Send consultation summary to your email',
              child: IconButton(
                icon: Icon(
                  Icons.email,
                  color: _meetingState.isMeetingComplete ? Colors.white : Colors.white.withOpacity(0.5),
                  size: _meetingState.isMeetingComplete ? 28 : 24,
                ),
                onPressed: _meetingState.isMeetingComplete ? _sendEmailAutomatically : () {
                  // If meeting is not complete, show a message explaining why
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You need to complete a full advising session before sending a summary.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
                        _meetingState.isInMeeting
                            ? 'Advisory session in progress. Please respond to each question.'
                            : 'Chat with your UTAR advisor or type "start advisor meeting" for a guided session.',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
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
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
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
                        decoration: InputDecoration(
                          hintText: 'Ask your academic advisor...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FloatingActionButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      backgroundColor: Colors.blueAccent,
                      elevation: 0,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
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
                              onPressed: _sendEmailWithPdf,
                              icon: const Icon(Icons.email),
                              label: const Text('Send Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _sharePdf,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
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
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}