import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../advisor/model/chat_message.dart';
import '../profile/model/profile_model.dart';

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
    
    // First pass - search for AI response with recommendation tags
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      
      // Look for the specially formatted recommendation summary
      if (message.messageType == MessageType.advisor &&
          message.text.contains('### RECOMMENDATIONS SUMMARY ###') &&
          message.text.contains('### END RECOMMENDATIONS ###')) {
        // Extract the content between the tags
        int startIndex = message.text.indexOf('### RECOMMENDATIONS SUMMARY ###') + 
                         '### RECOMMENDATIONS SUMMARY ###'.length;
        int endIndex = message.text.indexOf('### END RECOMMENDATIONS ###');
        
        if (startIndex >= 0 && endIndex > startIndex) {
          recommendationText = message.text.substring(startIndex, endIndex).trim();
          print('Found tagged recommendation: ${recommendationText.substring(0, 
              recommendationText.length > 50 ? 50 : recommendationText.length)}...');
        }
        break;
      }
      
      // If this is a long advisor message at the end, it's likely the recommendations
      if (recommendationText.isEmpty && message.messageType == MessageType.advisor && message.text.length > 500) {
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
    if ((foundResponses || recommendationText.isNotEmpty)) {
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

  static Future<File> generatePdf(List<ChatMessage> messages, [Map<int, String>? responses, ProfileModel? userProfile]) async {
    // Create PDF document with default fonts to avoid asset loading errors
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
      
      // First check for specially marked recommendation message
      bool foundRecommendation = false;
      for (int i = 0; i < messages.length; i++) {
        final message = messages[i];
        if (message.messageType == MessageType.advisor && 
            message.text.contains('### RECOMMENDATIONS SUMMARY ###') &&
            message.text.contains('### END RECOMMENDATIONS ###')) {
          // Extract the content between the tags
          int startIndex = message.text.indexOf('### RECOMMENDATIONS SUMMARY ###') + 
                          '### RECOMMENDATIONS SUMMARY ###'.length;
          int endIndex = message.text.indexOf('### END RECOMMENDATIONS ###');
          
          if (startIndex >= 0 && endIndex > startIndex) {
            String recommendationText = message.text.substring(startIndex, endIndex).trim();
            // Replace any problematic apostrophes with straight quotes
            recommendationText = _sanitizeText(recommendationText);
            // Remove any placeholder text like "[Student Name]" or "[Your Name]"
            recommendationText = _cleanRecommendationText(recommendationText, userProfile?.fullName);
            meetingData['Recommendations'] = recommendationText;
            print('Found tagged recommendation for PDF: ${meetingData['Recommendations']!.substring(0, 
                meetingData['Recommendations']!.length > 50 ? 50 : meetingData['Recommendations']!.length)}...');
            foundRecommendation = true;
            break;
          }
        }
      }
      
      // If no specifically tagged recommendation was found, fall back to long advisor message
      if (!foundRecommendation) {
        for (int i = messages.length - 1; i >= 0; i--) {
          final message = messages[i];
          if (message.messageType == MessageType.advisor && message.text.length > 500) {
            String recommendationText = message.text;
            // Replace any problematic apostrophes with straight quotes
            recommendationText = _sanitizeText(recommendationText);
            // Remove any placeholder text like "[Student Name]" or "[Your Name]"
            recommendationText = _cleanRecommendationText(recommendationText, userProfile?.fullName);
            meetingData['Recommendations'] = recommendationText;
            print('Found fallback recommendation text: ${recommendationText.substring(0, 50)}...');
            break;
          }
        }
      }
    } else {
      // Fallback to extracting from messages with improved logic
      meetingData = _extractMeetingDataImproved(messages);
      // Clean recommendation text 
      if (meetingData['Recommendations']!.isNotEmpty) {
        // Replace any problematic apostrophes with straight quotes
        meetingData['Recommendations'] = _sanitizeText(meetingData['Recommendations']!);
        meetingData['Recommendations'] = _cleanRecommendationText(
          meetingData['Recommendations']!, userProfile?.fullName);
      }
    }
    
    // Sanitize all text fields to ensure no special characters cause rendering issues
    meetingData.forEach((key, value) {
      if (key != 'Recommendations') { // Already sanitized recommendations above
        meetingData[key] = _sanitizeText(value);
      }
    });
    
    // Calculate consultation duration
    DateTime startTime = messages.isNotEmpty ? messages.first.timestamp : DateTime.now();
    DateTime endTime = messages.isNotEmpty ? messages.last.timestamp : DateTime.now();
    Duration duration = endTime.difference(startTime);
    String durationText = '${duration.inMinutes} minutes';
    
    // Format date for display
    String consultationDate = DateFormat('yyyy-MM-dd HH:mm').format(endTime);

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
            
            // Consultation & Counseling Details section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CONSULTATION & COUNSELING DETAILS',
                    style: pw.TextStyle(
                      fontSize: 14, 
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildConsultationDetailRow('Student Name:', userProfile?.fullName ?? 'N/A'),
                  _buildConsultationDetailRow('Faculty:', userProfile?.faculty ?? 'N/A'),
                  _buildConsultationDetailRow('Consultation Date:', consultationDate),
                  _buildConsultationDetailRow('Consultation Duration:', durationText),
                  _buildConsultationDetailRow('Email:', userProfile?.email ?? 'N/A'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 15),
            
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
            
            // First page content - Discussion points
            _buildSummarySection('Academic Progress', 
              meetingData['Academic Progress'] ?? 'Not discussed during this session.'),
            
            _buildSummarySection('Extracurricular Activities', 
              meetingData['Extracurricular Activities'] ?? 'Not discussed during this session.'),
              
            _buildSummarySection('Challenges & Concerns', 
              meetingData['Challenges & Concerns'] ?? 'Not discussed during this session.'),
              
            _buildSummarySection('Goals', 
              meetingData['Goals'] ?? 'Not discussed during this session.'),
            
            // Page break before recommendations
            pw.NewPage(),
            
            // Second page - Personalized recommendations
            pw.Header(
              level: 1,
              child: pw.Text('Personalized Recommendations', 
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                )
              )
            ),
            
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue400, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.white,
              ),
              child: pw.Text(
                meetingData['Recommendations'] ?? 'No specific recommendations were provided.',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            
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
  
  static pw.Widget _buildConsultationDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
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

  static Future<void> sendEmail(File pdfFile, String recipientEmail, [ProfileModel? userProfile]) async {
    // Use a placeholder that users can edit themselves
    String greeting = 'Hi [Recipient Name],';
    
    // Avoid using any apostrophes or special characters that could cause encoding issues
    final Email email = Email(
      body: '$greeting\n\nAttached is a summary of our recent academic advising session. This document includes the key points we discussed about your studies at UTAR, along with personalized recommendations.\n\nIf you have questions or need assistance, feel free to schedule another meeting.\n\nBest regards,\nUTAR Academic Advisory Team',
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
  Future<void> generatePdfAndSendEmail(List<ChatMessage> messages, [Map<int, String>? responses, ProfileModel? userProfile]) async {
    try {
      // First generate the PDF
      final pdfFile = await PdfEmailService.generatePdf(messages, responses, userProfile);
      
      // Then send the email with user profile data for personalized greeting
      await PdfEmailService.sendEmail(pdfFile, '', userProfile);
    } catch (e) {
      print('Error generating PDF and sending email: $e');
      rethrow; // Rethrow to allow caller to handle it
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
    
    // First search for AI response with recommendation tags - this is the highest priority
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      
      // Look for the specially formatted recommendation summary
      if (message.messageType == MessageType.advisor &&
          message.text.contains('### RECOMMENDATIONS SUMMARY ###') &&
          message.text.contains('### END RECOMMENDATIONS ###')) {
        // Extract the content between the tags
        int startIndex = message.text.indexOf('### RECOMMENDATIONS SUMMARY ###') + 
                        '### RECOMMENDATIONS SUMMARY ###'.length;
        int endIndex = message.text.indexOf('### END RECOMMENDATIONS ###');
        
        if (startIndex >= 0 && endIndex > startIndex) {
          meetingData['Recommendations'] = message.text.substring(startIndex, endIndex).trim();
          print('Found tagged recommendation in _extractMeetingDataImproved: ${meetingData['Recommendations']!.substring(0, 
              meetingData['Recommendations']!.length > 50 ? 50 : meetingData['Recommendations']!.length)}...');
        }
        break;
      }
    }
    
    // If no tagged recommendations found, look for long messages that might be recommendations
    if (meetingData['Recommendations']!.isEmpty) {
      for (int i = messages.length - 1; i >= 0; i--) {
        final message = messages[i];
        if (message.messageType == MessageType.advisor && message.text.length > 500) {
          meetingData['Recommendations'] = message.text;
          print('Found fallback recommendation in _extractMeetingDataImproved: ${message.text.substring(0, 50)}...');
          break;
        }
      }
    }
    
    // Second pass - identify advisor messages that contain each category's question
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      
      if (message.messageType == MessageType.advisor) {
        String text = message.text.toLowerCase();
        
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
    
    // Third pass - match user responses to advisor questions
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

  static String _cleanRecommendationText(String text, String? studentName) {
    // Replace [Student Name] with "Hi StudentName" to add a greeting before their name
    text = text.replaceAll('[Student Name]', 'Hi ${studentName ?? 'Student'}');
    // Remove placeholder text for advisor name
    text = text.replaceAll('[Your Name]', 'Advisor');
    return text;
  }

  // Helper method to sanitize text by replacing problematic characters
  static String _sanitizeText(String text) {
    // Replace curved/smart quotes with straight quotes
    text = text.replaceAll('’', '\'')
               .replaceAll('‘', '\'')
               .replaceAll('“', '"')
               .replaceAll('”', '"')
               .replaceAll('–', '-')
               .replaceAll('—', '-');
               
    // You can add more replacements for other problematic characters here
    
    return text;
  }
}