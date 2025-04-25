class ProfileModel {
  String fullName;
  String email;
  String gender;
  String birthday;
  String faculty;

  ProfileModel({
    required this.fullName,
    required this.email,
    required this.gender,
    required this.birthday,
    required this.faculty,
  });

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