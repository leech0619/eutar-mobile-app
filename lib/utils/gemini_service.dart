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
      final enhancedPrompt = "$prompt\n\nIMPORTANT: Please do not use markdown formatting like asterisks (**) in your response.";
      
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
    return "Hi there! Thanks for starting this academic advisory session. I'd like to learn a bit about your academic journey at UTAR so I can provide personalized guidance.\n\nLet's start with your academic progress. How are your classes going this semester? Could you also share your current CGPA and which subjects you're finding most interesting or challenging?";
  }
  
  Future<String> continueAdvisoryMeeting(String userResponse, int questionNumber, Map<int, String> responses) async {
    // Revised array of questions with clearer, unique identifiers for each topic
    final questions = [
      // First question about academic progress
      "Let's start with your academic progress. How are your classes going this semester? Could you also share your current CGPA and which subjects you're finding most interesting or challenging?",
      
      // Second question about extracurricular activities
      "Let's talk about your life outside of classes. What clubs, societies, sports, or volunteer activities are you involved in at UTAR? These extracurricular activities can really enhance your university experience.",
      
      // Third question about challenges
      "University life can sometimes be challenging. Is there anything specific that's been difficult for you lately, either with your studies or in other aspects of your life that might be affecting your academic performance?",
      
      // Fourth question about goals
      "Looking ahead to your future, what are your plans for the upcoming semester? And how do you see your current studies at UTAR fitting into your longer-term career goals?"
    ];
    
    // Debug - print the question number to verify correct tracking
    print("Processing question number: $questionNumber with response: "+
        userResponse.substring(0, userResponse.length > 30 ? 30 : userResponse.length)+"...");
    
    // Fix: nextQuestionIndex should be the next question to ask
    int nextQuestionIndex = questionNumber + 1;

    // After the last question (goals), respond to the user's goals, then wrap up and prompt for further questions or 'end'.
    if (questionNumber == 3) {
      // Use the AI to generate a short acknowledgment for the user's goals
      final prompt = '''
    The student just answered your question about their academic goals and future plans: "$userResponse"

    Respond with a brief, natural, and supportive acknowledgment about their goals and plans (do NOT give advice or summary). Then add: "Please type 'end' to terminate the session and I will send your session summary to your email."
    Keep your response conversational and do not use markdown formatting.
    ''';
      return await getAdvisorResponse(prompt);
}
    
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
      
      IMPORTANT: Begin your response with "### RECOMMENDATIONS SUMMARY ###" and end with "### END RECOMMENDATIONS ###" to make it easy to identify this as the final summary.
      
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
        The student just answered your question about their academic progress and CGPA: "$userResponse"
        
        Respond with a brief acknowledgment about their academic performance, mentioning their CGPA or any specific academic points they shared. 
        
        Then ask this next question about extracurricular activities: 
        
        "$nextQuestion"
        
        IMPORTANT: Make sure your response acknowledges their academic performance since that's what they just talked about. Add a short space or pause before asking the next question, but do not include any special characters like "\n" in your response.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      case 1:
        // Second response is about extracurricular activities
        contextPrompt = '''
        The student just answered your question about their extracurricular activities at UTAR: "$userResponse"
        
        Respond with a brief acknowledgment about their involvement in extracurricular activities (mention any specific clubs or activities they shared). 
        
        Then ask this next question about challenges: 
        
        "$nextQuestion"
        
        IMPORTANT: Make sure you clearly transition from extracurricular activities to challenges. Add a short space or pause before asking the next question, but do not include any special characters like "\n" in your response.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      case 2:
        // Third response is about challenges
        contextPrompt = '''
        The student just answered your question about challenges they're facing: "$userResponse"
        
        Respond with an empathetic acknowledgment about the challenges they mentioned.
        
        Then ask this next question about their goals for the future: 
        
        "$nextQuestion"
        
        IMPORTANT: Make sure you clearly transition from challenges to future goals. Add a short space or pause before asking the next question, but do not include any special characters like "\n" in your response.
        
        Keep your response natural and conversational. Don't use formatting like asterisks.
        ''';
        break;
        
      case 3:
        // Fourth response is about goals
        contextPrompt = '''
        The student just answered your question about their academic goals and future plans: "$userResponse"
        
        Respond with: "Let's wrap up our conversation. A summary of your session will be prepared and sent to your email. If you are done, just type 'end' and I'll prepare your summary and send via email."
        
        DO NOT provide any specific recommendations or advice in this response. Do NOT show the summary or advice in the chat. Only mention that the summary will be sent via email.
        
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