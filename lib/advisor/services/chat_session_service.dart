import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chat_message.dart';

class ChatSessionService {
  static const String _sessionsKey = 'advisor_chat_sessions';
  static const int _maxSessions = 10; // Maximum number of sessions to store
  
  // Get all saved sessions, sorted by last updated time (most recent first)
  Future<List<ChatSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionsJson = prefs.getString(_sessionsKey);
      
      if (sessionsJson == null || sessionsJson.isEmpty) {
        return [];
      }
      
      List<dynamic> sessionsList = jsonDecode(sessionsJson);
      List<ChatSession> sessions = sessionsList
          .map((json) => ChatSession.fromJson(json))
          .toList();
      
      // Sort by last updated time (newest first)
      sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      
      return sessions;
    } catch (e) {
      print('Error loading sessions: $e');
      return [];
    }
  }
  
  // Save a list of sessions
  Future<void> saveSessions(List<ChatSession> sessions) async {
    try {
      // Ensure we don't exceed the maximum number of sessions
      if (sessions.length > _maxSessions) {
        // Sort by last updated and keep only the most recent ones
        sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        sessions = sessions.sublist(0, _maxSessions);
      }
      
      final List<Map<String, dynamic>> sessionsJson = 
          sessions.map((session) => session.toJson()).toList();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
      
      print('Saved ${sessions.length} sessions');
    } catch (e) {
      print('Error saving sessions: $e');
      throw Exception('Failed to save sessions: $e');
    }
  }
  
  // Save or update a single session
  Future<void> saveSession(ChatSession session) async {
    try {
      // Get current sessions
      List<ChatSession> sessions = await getAllSessions();
      
      // Find and update existing session or add new one
      int existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.add(session);
      }
      
      // Save updated list
      await saveSessions(sessions);
    } catch (e) {
      print('Error saving session: $e');
      throw Exception('Failed to save session: $e');
    }
  }
  
  // Delete a session by ID
  Future<void> deleteSession(String sessionId) async {
    try {
      // Get current sessions
      List<ChatSession> sessions = await getAllSessions();
      
      // Remove session with matching ID
      sessions.removeWhere((session) => session.id == sessionId);
      
      // Save updated list
      await saveSessions(sessions);
      
      print('Deleted session $sessionId');
    } catch (e) {
      print('Error deleting session: $e');
      throw Exception('Failed to delete session: $e');
    }
  }
  
  // Get a specific session by ID
  Future<ChatSession?> getSession(String sessionId) async {
    try {
      // Get all sessions
      List<ChatSession> sessions = await getAllSessions();
      
      // Find session with matching ID
      return sessions.firstWhere(
        (session) => session.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }
  
  // Create a new session
  Future<ChatSession> createNewSession() async {
    final newSession = ChatSession.create();
    await saveSession(newSession);
    return newSession;
  }
} 