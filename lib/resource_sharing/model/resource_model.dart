import 'package:cloud_firestore/cloud_firestore.dart';

class Resource {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadDate;
  final List<String> tags;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.uploadedByName,
    required this.uploadedBy,
    required this.uploadDate,
    required this.tags,
  });

  factory Resource.fromMap(Map<String, dynamic> map, String docId) {
    return Resource(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'tags': tags,
    };
  }
}