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
  // Get current username
  Future<String> get currentUserName async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore
              .collection('users') // Replace 'users' with your collection name
              .doc(currentUserId)
              .get();

      if (userDoc.exists) {

        return userDoc['fullName'] as String? ??
            ''; // Return username, or empty string if missing.  Crucially, use the as keyword.
      } else {
        print('User document not found');
        return ''; // Return empty string if document not found
      }
    } catch (e) {
      print('Error getting username: $e');
      return ''; // Return empty string if an error occurred
    }
  }

  // Get all assignments
  Stream<List<Resource>> getResources() {
    return _firestore
        .collection('assignments')
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Resource.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Search assignments by query
  Future<List<Resource>> searchResources(String query) async {
    query = query.toLowerCase();

    final snapshot = await _firestore.collection('assignments').get();

    return snapshot.docs
        .map((doc) => Resource.fromMap(doc.data(), doc.id))
        .where(
          (assignment) =>
              assignment.title.toLowerCase().contains(query) ||
              assignment.description.toLowerCase().contains(query) ||
              assignment.tags.any((tag) => tag.toLowerCase().contains(query)),
        )
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
      final storageRef = _storage.ref().child('assignments/$fileName');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => null);
      final fileUrl = await snapshot.ref.getDownloadURL();
      String uploadedByName = await currentUserName;
      // Create assignment in Firestore
      final assignment = Resource(
        id: '',
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileName: fileName,
        uploadedByName: uploadedByName,
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
      final docSnapshot =
          await _firestore
              .collection(
                'assignments',
              ) // Ensure this matches your collection name
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
  // **DELETE RESOURCE**
  Future<bool> deleteResource(String resourceId, String fileUrl) async {
    try {
      // 1. Delete the document from Firestore
      await _firestore.collection('assignments').doc(resourceId).delete();

      // 2. Delete the file from Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);  // Create a reference from the URL
      await storageRef.delete();

      return true;
    } catch (e) {
      print('Error deleting resource: $e');
      return false;
    }
  }

  // **UPDATE RESOURCE**
  Future<bool> updateResource({
    required String resourceId,
    required String title,
    required String description,
    required List<String> tags,
    File? newFile, // New optional file. If provided, we'll replace the old one
    required String oldFileUrl, // To delete old file
  }) async {
    try {
      String fileUrl = oldFileUrl; // Assume we're not changing the file URL

      if (newFile != null) {
        // Delete the old file if a new file is being uploaded
        await FirebaseStorage.instance.refFromURL(oldFileUrl).delete();

        // Upload the new file
        final fileName = newFile.path.split('/').last;
        final storageRef = _storage.ref().child('assignments/$fileName');
        final uploadTask = storageRef.putFile(newFile);
        final snapshot = await uploadTask.whenComplete(() => null);
        fileUrl = await snapshot.ref.getDownloadURL();
      }

      // Update the document in Firestore
      await _firestore.collection('assignments').doc(resourceId).update({
        'title': title,
        'description': description,
        'tags': tags,
        'fileUrl': fileUrl,
      });

      return true;
    } catch (e) {
      print('Error updating resource: $e');
      return false;
    }
  }

  Future<bool> isCurrentUserUploader(String resourceId) async {
      try {
          final docSnapshot = await _firestore
              .collection('assignments')
              .doc(resourceId)
              .get();

          if (docSnapshot.exists) {
              final data = docSnapshot.data();
              if (data != null && data.containsKey('uploadedBy')) {
                  String uploadedBy = data['uploadedBy'] as String;
                  return uploadedBy == currentUserId;
              } else {
                  print("uploadedBy field not found in document");
                  return false;
              }
          } else {
              print("Document with ID $resourceId not found.");
              return false;
          }
      } catch (e) {
          print("Error checking uploader: $e");
          return false;
      }
  }

}

