import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/resource_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class ResourceController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? '';
  
  // Get all assignments
  Stream<List<Resource>> getResources() {
    return _firestore
        .collection('assignments')
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Resource.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Search assignments by query
  Future<List<Resource>> searchResources(String query) async {
    query = query.toLowerCase();
    
    final snapshot = await _firestore.collection('assignments').get();
    
    return snapshot.docs
        .map((doc) => Resource.fromMap(doc.data(), doc.id))
        .where((assignment) =>
            assignment.title.toLowerCase().contains(query) ||
            assignment.description.toLowerCase().contains(query) ||
            assignment.tags.any((tag) => tag.toLowerCase().contains(query)))
        .toList();
  }

  // Upload a new assignment
  Future<bool> uploadResource({
    required String title,
    required String description,
    required List<String> tags,
    required File file,
  }) async {
    try {
      // Upload file to Firebase Storage
      final fileName = file.path.split('/').last;
      final storageRef = _storage.ref("gs://focus-album-455510-h8.firebasestorage.app").child('assignments/$fileName');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final fileUrl = await snapshot.ref.getDownloadURL();

      // Create assignment in Firestore
      final assignment = Resource(
        id: '',
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileName: fileName,
        uploadedBy: currentUserId,
        uploadDate: DateTime.now(),
        tags: tags,
      );

      await _firestore.collection('assignments').add(assignment.toMap());
      return true;
    } catch (e) {
      print('Error uploading assignment: $e');
      return false;
    }
  }
    Future<Resource?> getResourceDetails(String resourceId) async {
    if (resourceId.isEmpty) {
      print("Error: resourceId cannot be empty.");
      return null;
    }
    try {
      final docSnapshot = await _firestore
          .collection('assignments') // Ensure this matches your collection name
          .doc(resourceId)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        // Assuming Resource.fromMap exists and handles data conversion
        // It needs the data Map and the document ID
        return Resource.fromMap(docSnapshot.data()!, docSnapshot.id);
      } else {
        print("Resource with ID $resourceId not found.");
        return null; // Document doesn't exist
      }
    } catch (e) {
      print("Error fetching resource details for ID $resourceId: $e");
      return null; // Return null on error
    }
  }

  // Pick a file from device
  Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  // Download assignment file
  Future<void> downloadFile(Resource assignment) async {
    // Implementation would depend on platform (web vs mobile)
    // This is a simplified version
    // For mobile, you might save to local storage
    // For web, you might open in a new tab
    // This is a placeholder for the actual implementation
  }
}