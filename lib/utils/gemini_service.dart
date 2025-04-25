import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final GenerativeModel _model;
  
  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      print('Gemini model initialized successfully with API key: ${apiKey.substring(0, 5)}...');
    } catch (e) {
      print('Error initializing Gemini model: $e');
      rethrow;
    }
  }

  Future<String> getAdvisorResponse(String prompt) async {
    try {
      // Add instruction to avoid markdown formatting
      final enhancedPrompt = prompt + "\n\nIMPORTANT: Please do not use markdown formatting like asterisks (**) in your response.";
      
      final content = [Content.text(enhancedPrompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Sorry, I couldn\'t generate a response.';
    } catch (e) {
      print('Error with Gemini API: $e');
      return 'Error connecting to academic advisor service. Please check your API key configuration or internet connection.';
    }
  }

  Future<String> getInitialAdvice() async {
    const systemPrompt = '''
    You are a UTAR (Universiti Tunku Abdul Rahman) academic advisor chatbot. Your role is to help UTAR students with various academic queries such as:
    
    - UTAR course selection and planning
    - UTAR academic progress tracking
    - Career guidance related to their UTAR degree
    - Study tips and resources for UTAR students
    - UTAR policies and procedures
    
    Start with a friendly introduction and ask how you can help the UTAR student today. Be conversational and helpful.
    
    IMPORTANT: Do NOT initiate a formal UTAR academic advisory meeting unless the student specifically asks for one. 
    If they ask for a formal academic advisory meeting, THEN you can begin the structured consultation.
    ''';
    
    return await getAdvisorResponse(systemPrompt);
  }
  
  Future<String> startAdvisoryMeeting() async {
    // Use a more natural, conversational introduction that clearly indicates this is about academic progress
    return "Hi there! I'm your UTAR academic advisor. It's good to meet with you today. Let's have a structured meeting covering a few key areas. First, I'd like to discuss your academic progress at UTAR. How are your classes going this semester? Could you tell me about your current CGPA and which subjects you're finding most interesting or challenging?";
  }
  
  Future<String> continueAdvisoryMeeting(String userResponse, int questionNumber, Map<int, String> responses) async {
    // Revised array of questions with clearer, unique identifiers for each topic
    final questions = [
      // First question about academic progress
      "I'd like to know about your academic progress at UTAR. How are your classes going this semester? Could you tell me about your current CGPA and which subjects you're finding most interesting or challenging?",
      
      // Second question about extracurricular activities
      "Let's talk about your extracurricular activities at UTAR. What clubs, societies, sports, or volunteer work are you involved in? These co-curricular activities can really enhance your university experience.",
      
      // Third question about challenges
      "University life can certainly have its challenges. Is there anything specific that's been difficult for you lately, either with your studies or otherwise that might be affecting your academic performance?",
      
      // Fourth question about goals
      "Looking ahead to your future goals, what are your plans for the upcoming semester? And how do you see your current studies at UTAR fitting into your longer-term career plans?"
    ];
    
    // Debug - print the question number to verify correct tracking
    print("Processing question number: $questionNumber with response: ${userResponse.substring(0, userResponse.length > 30 ? 30 : userResponse.length)}...");
    
    // Determine which question to ask next (0-based index)
    int nextQuestionIndex = questionNumber;
    
    if (nextQuestionIndex >= questions.length) {
      // For the final summary - pass all student responses with clear categorization
      
      // Convert the map to a formatted string for the prompt
      String formattedResponses = '';
      
      // Use explicit category labels that match PDF output
      final Map<int, String> categoryLabels = {
        0: "Academic Progress",
        1: "Extracurricular Activities",
        2: "Challenges & Concerns",
        3: "Goals",
      };
      
      // Print all responses for debugging
      print("All collected responses for summary:");
      responses.forEach((questionNum, response) {
        String category = categoryLabels[questionNum] ?? "Question $questionNum";
        print("$category: ${response.substring(0, response.length > 30 ? 30 : response.length)}...");
        formattedResponses += "- $category: $response\n\n";
      });
      
      // Use the Gemini API for the final summary to allow deep analysis of all responses
      String summaryPrompt = '''
      You're a friendly UTAR academic advisor who just finished a conversation with a student. Create a natural, helpful summary of your discussion that feels like a real advisor wrote it.

      Here's what the student shared during your conversation:
      
      $formattedResponses
      
      Write a personalized summary that covers:
      
      1. Academic Progress: Highlight how they're doing academically and acknowledge their strengths/challenges.
      2. Extracurricular Activities: Note their participation in clubs, societies, sports or other activities at UTAR.
      3. Challenges & Concerns: Address their concerns with empathy.
      4. Goals: Mention their academic and career goals.
      5. Recommendations: Offer 3-4 helpful, specific suggestions tailored to their situation.
      
      Use a warm, supportive tone. Write as if directly speaking to the student. Make specific references to things they mentioned. Keep it natural and conversational.
      
      End by letting them know they can download this summary for their records.
      
      IMPORTANT: Please do not use markdown formatting like asterisks (**) in your response.
      ''';
      
      return await getAdvisorResponse(summaryPrompt);
    }
    
    // Get the next question to ask
    String nextQuestion = questions[nextQuestionIndex];
    
    // Create a clear prompt for the AI that specifies exactly what question was answered
    String contextPrompt = '';
    
    // Map question numbers to specific topics using consistent labels
    switch(questionNumber) {
      case 0:
        // First response is about academic progress
        contextPrompt = '''
        The student just answered your question about their academic progress and CGPA: "${userResponse}"
        
        Respond with a brief acknowledgment about their academic performance, mentioning their CGPA or any specific academic points they shared. Then ask this next question about extracurricular activities: 
        
        "${nextQuestion}"
        
        IMPORTANT: Make sure your response acknowledges their academic performance since that's what they just talked about.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      case 1:
        // Second response is about extracurricular activities
        contextPrompt = '''
        The student just answered your question about their extracurricular activities at UTAR: "${userResponse}"
        
        Respond with a brief acknowledgment about their involvement in extracurricular activities (mention any specific clubs or activities they shared). Then ask this next question about challenges: 
        
        "${nextQuestion}"
        
        IMPORTANT: Make sure you clearly transition from extracurricular activities to challenges.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      case 2:
        // Third response is about challenges
        contextPrompt = '''
        The student just answered your question about challenges they're facing: "${userResponse}"
        
        Respond with an empathetic acknowledgment about the challenges they mentioned. Then ask this next question about their goals for the future: 
        
        "${nextQuestion}"
        
        IMPORTANT: Make sure you clearly transition from challenges to future goals.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      case 3:
        // Fourth response is about goals
        contextPrompt = '''
        The student just answered your question about their academic goals and future plans: "${userResponse}"
        
        Respond with a brief acknowledgment about their goals and plans. Then let them know you'll now provide a summary with personalized advice based on your conversation.
        
        IMPORTANT: Indicate that all questions have been answered and you'll now provide a summary of the meeting.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      default:
        // Fallback for unexpected question numbers
        return nextQuestion;
    }
    
    // Use AI to generate a contextual response
    return await getAdvisorResponse(contextPrompt);
  }
} 