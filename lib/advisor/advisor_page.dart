import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/gemini_service.dart';
import '../utils/pdf_email_service.dart';
import '../utils/auth.dart';  // Import the auth service
import 'model/chat_message.dart';
import 'widgets/message_bubble.dart';

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
  final AdvisoryMeetingState _meetingState = AdvisoryMeetingState();
  bool _isLoading = false;
  String _emailAddress = '';
  bool _showEmailDialog = false;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _initializeChat();
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
      // Always use the same initial message for consistency
      final initialMessage = "Hello! I'm your Academic Advisor Chatbot to guide you through your academic journey. I'm ready to assist you, just like your academic supervisor.";
      
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
          text: "Hello! I'm your academic advisor. I'm having trouble connecting to my knowledge service at the moment. Please check your API configuration or try again later.",
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

  // Send email at meeting completion instead of using the PDF download button
  Future<void> _sendEmailAutomatically() async {
    if (_messages.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final pdfFile = await PdfEmailService.generatePdf(_messages);

      // Verify we have an email address
      if (_emailAddress.isEmpty) {
        // Try to get the email one more time
        _getUserEmail();
        // If still empty, show a dialog for manual entry
        if (_emailAddress.isEmpty) {
          setState(() {
            _pdfFile = pdfFile;
            _showEmailDialog = true;
            _isLoading = false;
          });
          return;
        }
      }

      // Send the email automatically
      await PdfEmailService.sendEmail(pdfFile, _emailAddress);
      
      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation summary sent to $_emailAddress'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
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
      } else {
        _showErrorSnackBar('Failed to send email: $e');
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
            text: "--- Beginning Formal Academic Advisory Meeting ---",
            messageType: MessageType.system,
          ));
        });
        
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
        
        // Check if the meeting is complete
        if (_meetingState.isAllQuestionsAnswered) {
          _meetingState.endMeeting();
          
          // Add a visual divider to indicate meeting end
          setState(() {
            _messages.add(ChatMessage(
              text: "--- End of Formal Academic Advisory Meeting ---",
              messageType: MessageType.system,
            ));
          });
          
          // Send the consultation summary via email automatically
          Future.delayed(const Duration(milliseconds: 1000), () {
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

      final pdfFile = await PdfEmailService.generatePdf(_messages);
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
        _isLoading = true;
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Academic Advisor Chatbot',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Academic Advisor Help'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('You can:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('• Ask any questions about academics'),
                          Text('• Get help with course selection'),
                          Text('• Seek advice on career planning'),
                          Text('• Get study resources and tips'),
                          Text('• Learn about university policies'),
                          SizedBox(height: 16),
                          Text('Formal Advisory Meeting:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('To start a formal academic advisory meeting, type:'),
                          Text('"I would like to start an advisor meeting"', 
                              style: TextStyle(fontStyle: FontStyle.italic)),
                          SizedBox(height: 8),
                          Text('The meeting will cover:'),
                          Text('• Academic Performance (CGPA)'),
                          Text('• Co-curricular Activities'),
                          Text('• Professional Development'),
                          Text('• Problems & Challenges'),
                          Text('• Future Planning'),
                          SizedBox(height: 12),
                          Text('Meeting Summary:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('After completing a meeting, a summary will be automatically sent to your email.'),
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
                  color: Colors.white,
                  size: _meetingState.isMeetingComplete ? 28 : 24,
                ),
                onPressed: _sendEmailAutomatically,
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
                            ? 'Formal advisory meeting in progress. Please answer each question to continue.'
                            : 'Ask any academic questions, or type "start advisor meeting" for a formal consultation.',
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