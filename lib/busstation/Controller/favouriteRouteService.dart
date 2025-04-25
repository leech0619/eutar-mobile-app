import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/favouriteRoute.dart';

class FavoriteRouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Get all favorite route IDs for the current user as a stream
  Stream<Set<String>> getFavoriteRouteIds() {
    try {
      return _favoritesCollection
          .where('userId', isEqualTo: currentUserId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .map((data) => data['routeId'] as String)
            .toSet();
      });
    } catch (e) {
      print('Error fetching favorite route IDs: $e');
      return const Stream.empty();
    }
  }

  // Add a route to favorites
  Future<void> addFavorite(String routeId) async {
    try {
      final favorite = FavoriteRoute(
        userId: currentUserId,
        routeId: routeId,
        createdAt: DateTime.now(),
      );

      // Create a document ID combining userId and routeId for uniqueness
      final docId = '$currentUserId-$routeId';

      await _favoritesCollection.doc(docId).set(favorite.toMap());
      print('Favorite added: $routeId');
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  // Remove a route from favorites
  Future<void> removeFavorite(String routeId) async {
    try {
      final docId = '$currentUserId-$routeId';
      await _favoritesCollection.doc(docId).delete();
      print('Favorite removed: $routeId');
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String routeId, bool isFavorite) async {
    if (isFavorite) {
      await removeFavorite(routeId);
    } else {
      await addFavorite(routeId);
    }
  }
}