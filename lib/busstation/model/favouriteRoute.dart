class FavoriteRoute {
  final String userId;
  final String routeId;
  final DateTime createdAt;

  FavoriteRoute({
    required this.userId,
    required this.routeId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'routeId': routeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoriteRoute.fromMap(Map<String, dynamic> map) {
    return FavoriteRoute(
      userId: map['userId'],
      routeId: map['routeId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}