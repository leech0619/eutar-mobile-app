/// A model class representing a user's profile.
class ProfileModel {
  String fullName;
  String email;
  String gender;
  String birthday;
  String faculty;

  /// Constructor for creating a [ProfileModel] instance.
  ///
  /// All fields are required.
  ProfileModel({
    required this.fullName,
    required this.email,
    required this.gender,
    required this.birthday,
    required this.faculty,
  });

  /// Factory method to create a [ProfileModel] instance from a map.
  ///
  /// [data] is a map containing the profile data.
  /// If a field is missing in the map, a default value of 'N/A' is used.
  factory ProfileModel.fromMap(Map<String, dynamic> data) {
    return ProfileModel(
      fullName: data['fullName'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      gender: data['gender'] ?? 'N/A',
      birthday: data['birthday'] ?? 'N/A',
      faculty: data['faculty'] ?? 'N/A',
    );
  }
}
