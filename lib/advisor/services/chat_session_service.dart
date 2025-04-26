import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/chat_message.dart';

class ChatSessionService {
  static const int _maxSessions = 10; // Maximum number of sessions to store
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get the Firestore collection reference for the current user's chat sessions
  CollectionReference<Map<String, dynamic>> get _chatSessionsCollection {
    final String userId = _auth.currentUser?.uid ?? 'anonymous';
    return _firestore.collection('users').doc(userId).collection('chat_sessions');
  }
  
  // Get all saved sessions, sorted by last updated time (most recent first)
  Future<List<ChatSession>> getAllSessions() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, returning empty chat list');
        return [];
      }
      
      // Get sessions from Firebase
      final querySnapshot = await _chatSessionsCollection
          .orderBy('lastUpdated', descending: true)
          .limit(_maxSessions)
          .get();
      
      List<ChatSession> sessions = querySnapshot.docs
          .map((doc) => ChatSession.fromJson(doc.data()))
          .toList();
      
      print('Loaded ${sessions.length} sessions from Firebase');
      return sessions;
    } catch (e) {
      print('Error loading sessions from Firebase: $e');
      return [];
    }
  }
  
  // Save a list of sessions
  Future<void> saveSessions(List<ChatSession> sessions) async {
    try {
      // Ensure user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, cannot save sessions');
        return;
      }
      
      // Ensure we don't exceed the maximum number of sessions
      if (sessions.length > _maxSessions) {
        // Sort by last updated and keep only the most recent ones
        sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        sessions = sessions.sublist(0, _maxSessions);
      }
      
      // With Firebase, we need to save each session individually
      final batch = _firestore.batch();
      
      for (var session in sessions) {
        final docRef = _chatSessionsCollection.doc(session.id);
        batch.set(docRef, session.toJson());
      }
      
      await batch.commit();
      print('Batch saved ${sessions.length} sessions to Firebase');
    } catch (e) {
      print('Error saving sessions: $e');
      throw Exception('Failed to save sessions: $e');
    }
  }
  
  // Save or update a single session
  Future<void> saveSession(ChatSession session) async {
    try {
      // Ensure user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, cannot save session');
        return;
      }
      
      // Update the timestamp
      session.updateTimestamp();
      
      // Save to Firebase
      await _chatSessionsCollection.doc(session.id).set(session.toJson());
      print('Saved session ${session.id} to Firebase');
    } catch (e) {
      print('Error saving session: $e');
      throw Exception('Failed to save session: $e');
    }
  }
  
  // Delete a session by ID
  Future<void> deleteSession(String sessionId) async {
    try {
      // Ensure user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, cannot delete session');
        return;
      }
      
      // Delete from Firebase
      await _chatSessionsCollection.doc(sessionId).delete();
      print('Deleted session $sessionId from Firebase');
    } catch (e) {
      print('Error deleting session: $e');
      throw Exception('Failed to delete session: $e');
    }
  }
  
  // Get a specific session by ID
  Future<ChatSession?> getSession(String sessionId) async {
    try {
      // Ensure user is logged in
      if (_auth.currentUser == null) {
        print('No user logged in, cannot get session');
        return null;
      }
      
      // Get from Firebase
      final docSnapshot = await _chatSessionsCollection.doc(sessionId).get();
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ChatSession.fromJson(docSnapshot.data()!);
      }
      throw Exception('Session not found in Firebase');
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }
  
  // Create a new session
  Future<ChatSession> createNewSession() async {
    if (_auth.currentUser == null) {
      throw Exception('User must be logged in to create a session');
    }
    
    final newSession = ChatSession.create();
    await saveSession(newSession);
    return newSession;
  }
}