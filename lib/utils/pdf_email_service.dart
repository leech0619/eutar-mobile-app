import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../advisor/model/chat_message.dart';

class PdfEmailService {
  // Structure for organizing extracted meeting data - improved version
  static Map<String, String> extractMeetingData(List<ChatMessage> messages) {
    // Initialize meeting data structure
    Map<String, String> meetingData = {
      'Academic Progress': '',
      'Extracurricular Activities': '',
      'Challenges & Concerns': '',
      'Goals': '',
      'Recommendations': '',
    };
    
    // Look for AdvisoryMeetingState data in system messages
    String recommendationText = '';
    bool foundResponses = false;
    
    // First pass - find all advisor responses that contain all responses
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      
      // If this is a long advisor message at the end, it's likely the recommendations
      if (message.messageType == MessageType.advisor && message.text.length > 500) {
        recommendationText = message.text;
      }
      
      // If this is a user message right after a message asking for that specific topic
      if (message.messageType == MessageType.user && i > 0) {
        String previousText = messages[i-1].text.toLowerCase();
        String currentText = message.text;
        
        if (previousText.contains('cgpa') || 
            previousText.contains('classes going') || 
            previousText.contains('subjects') || 
            previousText.contains('academic')) {
          meetingData['Academic Progress'] = currentText;
          foundResponses = true;
        }
        else if (previousText.contains('clubs') || 
                previousText.contains('activities') || 
                previousText.contains('societies') || 
                previousText.contains('extracurricular') ||
                previousText.contains('co-curricular')) {
          meetingData['Extracurricular Activities'] = currentText;
          foundResponses = true;
        }
        else if (previousText.contains('challenges') || 
                previousText.contains('difficult') || 
                previousText.contains('problems') || 
                previousText.contains('affecting')) {
          meetingData['Challenges & Concerns'] = currentText;
          foundResponses = true;
        }
        else if (previousText.contains('goals') || 
                previousText.contains('upcoming semester') || 
                previousText.contains('longer-term') ||
                previousText.contains('career plans')) {
          meetingData['Goals'] = currentText;
          foundResponses = true;
        }
      }
    }
    
    // If we found specific user responses, add the recommendations
    if (foundResponses && recommendationText.isNotEmpty) {
      meetingData['Recommendations'] = recommendationText;
    }
    
    // For any fields that are still empty, look through all user messages
    if (meetingData.values.any((value) => value.isEmpty)) {
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        if (message.messageType == MessageType.user) {
          String text = message.text.toLowerCase();
          
          // Try to fill in missing fields
          if (meetingData['Academic Progress']!.isEmpty && 
              (text.contains('cgpa') || text.contains('gpa') || text.contains('grade') || 
               text.contains('semester') || text.contains('exam'))) {
            meetingData['Academic Progress'] = message.text;
          }
          else if (meetingData['Extracurricular Activities']!.isEmpty && 
                  (text.contains('club') || text.contains('activit') || text.contains('societ') || 
                   text.contains('extracurricular') || text.contains('co-curricular'))) {
            meetingData['Extracurricular Activities'] = message.text;
          }
          else if (meetingData['Challenges & Concerns']!.isEmpty && 
                  (text.contains('challenge') || text.contains('difficult') || 
                   text.contains('problem') || text.contains('issue'))) {
            meetingData['Challenges & Concerns'] = message.text;
          }
          else if (meetingData['Goals']!.isEmpty && 
                  (text.contains('goal') || text.contains('plan') || 
                   text.contains('future') || text.contains('career'))) {
            meetingData['Goals'] = message.text;
          }
        }
      }
    }
    
    return meetingData;
  }

  static Future<File> generatePdf(List<ChatMessage> messages, [Map<int, String>? responses]) async {
    final pdf = pw.Document();
    
    // Extract structured data from the conversation or use provided responses
    Map<String, String> meetingData;
    
    if (responses != null && responses.isNotEmpty) {
      // Use the provided responses map - make sure to map them correctly
      meetingData = {
        'Academic Progress': responses[0] ?? 'Not provided',
        'Extracurricular Activities': responses[1] ?? 'Not provided',
        'Challenges & Concerns': responses[2] ?? 'Not provided',
        'Goals': responses[3] ?? 'Not provided',
        'Recommendations': '',
      };
      
      // Debug print the responses to ensure they're being used
      print('Using direct responses map: ${responses.toString()}');
      responses.forEach((key, value) {
        if (value.isNotEmpty) {
          print('Response $key: ${value.substring(0, value.length > 30 ? 30 : value.length)}...');
        } else {
          print('Response $key: <empty>');
        }
      });
      
      // Find the recommendation (long advisor message) in the chat
      for (int i = messages.length - 1; i >= 0; i--) {
        final message = messages[i];
        if (message.messageType == MessageType.advisor && message.text.length > 500) {
          meetingData['Recommendations'] = message.text;
          print('Found recommendation text: ${message.text.substring(0, 50)}...');
          break;
        }
      }
    } else {
      // Fallback to extracting from messages with improved logic
      meetingData = _extractMeetingDataImproved(messages);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('UTAR Academic Advising Session Summary', 
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold
                )
              )
            ),
            pw.Paragraph(
              text: 'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12)
            ),
            pw.SizedBox(height: 10),
            
            // Introduction section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ABOUT THIS SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 14, 
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'This document summarizes your advising session. It includes details about your academic progress, extracurricular activities, professional development goals, challenges, and personalized recommendations.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Dynamically build sections from the extracted meeting data
            _buildSummarySection('Academic Progress', 
              meetingData['Academic Progress'] ?? 'Not discussed during this session.'),
            
            _buildSummarySection('Extracurricular Activities', 
              meetingData['Extracurricular Activities'] ?? 'Not discussed during this session.'),
              
            _buildSummarySection('Challenges & Concerns', 
              meetingData['Challenges & Concerns'] ?? 'Not discussed during this session.'),
              
            _buildSummarySection('Goals', 
              meetingData['Goals'] ?? 'Not discussed during this session.'),
              
            _buildSummarySection('Personalized Recommendations', 
              meetingData['Recommendations'] ?? 'No specific recommendations were provided.'),
            
            pw.SizedBox(height: 20),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue800),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(
                    pw.IconData(0xe88e), // Info icon
                    color: PdfColors.blue800,
                    size: 24,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text(
                      'This document is for your reference. Please schedule a follow-up meeting if you have further questions or need additional guidance.',
                      style: pw.TextStyle(
                        fontSize: 10, 
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/academic_consultation_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  static pw.Widget _buildSummarySection(String title, String content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue200,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              content,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> sendEmail(File pdfFile, String recipientEmail) async {
    final Email email = Email(
      body: 'Hi there,\n\nAttached is a summary of our recent academic advising session. This document includes the key points we discussed about your studies at UTAR, along with personalized recommendations.\n\nIf you have any questions or need further assistance, feel free to schedule another meeting.\n\nBest regards,\nUTAR Academic Advisory Team',
      subject: 'Your UTAR Academic Advising Session Summary',
      recipients: [recipientEmail],
      attachmentPaths: [pdfFile.path],
      isHTML: false,
    );

    try {
      // Try to send the email - if it fails, we'll use the fallback
      await FlutterEmailSender.send(email);
    } catch (e) {
      // If we get an exception, use share as fallback
      print('Error sending email, falling back to share: $e');
      await sharePdf(pdfFile);
      // Throw a special error that will be handled differently
      throw Exception('NoEmailClient: You can share the PDF using other apps');
    }
  }

  static Future<void> sharePdf(File pdfFile) async {
    try {
      await Share.shareXFiles([XFile(pdfFile.path)], 
        text: 'Academic Advisor Consultation Summary');
    } catch (e) {
      throw Exception('Error sharing PDF: $e');
    }
  }

  // Combine PDF generation and email sending into a single method
  Future<void> generatePdfAndSendEmail(List<ChatMessage> messages, [Map<int, String>? responses]) async {
    try {
      // First generate the PDF
      final pdfFile = await PdfEmailService.generatePdf(messages, responses);
      
      // Then send the email
      await PdfEmailService.sendEmail(pdfFile, ''); // Empty email will use device's default email app
    } catch (e) {
      print('Error generating PDF and sending email: $e');
      throw e; // Rethrow to allow caller to handle it
    }
  }

  static Future<bool> requestStoragePermission({bool forceRequest = false}) async {
    try {
      // For Android 13+ (API level 33 and above), we need to request specific permissions
      // Check for the specific permissions based on platform version
      var statusRead = await Permission.storage.status;
      
      // If permission is denied but we want to force a request, or if it's not determined yet
      if (forceRequest || statusRead.isDenied || statusRead.isRestricted || statusRead.isLimited) {
        statusRead = await Permission.storage.request();
      }
      
      // On newer Android versions, we might need additional permissions
      try {
        var manageStorage = await Permission.manageExternalStorage.status;
        if (forceRequest || manageStorage.isDenied) {
          manageStorage = await Permission.manageExternalStorage.request();
        }
      } catch (e) {
        // Ignore errors for unsupported permissions on some devices
        print('Additional storage permission check failed: $e');
      }
      
      // Verify permission was granted
      return statusRead.isGranted;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  // Improved extraction method to better identify categories
  static Map<String, String> _extractMeetingDataImproved(List<ChatMessage> messages) {
    // Initialize meeting data structure
    Map<String, String> meetingData = {
      'Academic Progress': '',
      'Extracurricular Activities': '',
      'Challenges & Concerns': '',
      'Goals': '',
      'Recommendations': '',
    };
    
    // Define patterns that identify each category's question
    final Map<String, List<String>> categoryPatterns = {
      'Academic Progress': ['cgpa', 'academic', 'classes going', 'subjects', 'interesting or challenging', 'semester'],
      'Extracurricular Activities': ['life outside', 'clubs', 'activities', 'societies', 'co-curricular', 'extracurricular'],
      'Challenges & Concerns': ['challenges', 'difficult', 'problems', 'affecting your academic', 'been difficult for you'],
      'Goals': ['goals', 'looking ahead', 'upcoming semester', 'longer-term career plans', 'future plans']
    };
    
    // Track which advisor messages match which category
    Map<int, String> advisorMessageCategories = {};
    
    // First pass - identify advisor messages that contain each category's question
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      
      if (message.messageType == MessageType.advisor) {
        String text = message.text.toLowerCase();
        
        // Check for recommendation/summary (end of meeting)
        if (message.text.length > 500) {
          meetingData['Recommendations'] = message.text;
          continue;
        }
        
        // Try to categorize the advisor message
        for (final category in categoryPatterns.keys) {
          for (final pattern in categoryPatterns[category]!) {
            if (text.contains(pattern)) {
              advisorMessageCategories[i] = category;
              print('Categorized message $i as $category: ${message.text.substring(0, 30)}...');
              break;
            }
          }
        }
      }
    }
    
    // Second pass - match user responses to advisor questions
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      
      if (message.messageType == MessageType.user && i > 0) {
        // Look for the most recent advisor message before this user message
        for (int j = i - 1; j >= 0; j--) {
          if (messages[j].messageType == MessageType.advisor && 
              advisorMessageCategories.containsKey(j)) {
            final category = advisorMessageCategories[j]!;
            meetingData[category] = message.text;
            print('Matched user response at index $i to category $category');
            break;
          }
        }
      }
    }
    
    return meetingData;
  }
} 