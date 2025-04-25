import 'package:flutter/material.dart';
import '../model/profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _birthdayController;

  String? _selectedGender;
  String? _selectedFaculty;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _faculties = [
    'Faculty of Accountancy and Management (FAM)',
    'Faculty of Arts and Social Science (FAS)',
    'Teh Hong Piow Faculty of Business and Finance (THP FBF)',
    'Faculty of Creative Industries (FCI)',
    'Faculty of Engineering and Green Technology (FEGT)',
    'Faculty of Information and Communication Technology (FICT)',
    'Faculty of Science (FSc)',
    'Institute of Chinese Studies (ICS)',
    'Lee Kong Chian Faculty of Engineering and Science (LKC FES)',
    'M. Kandiah Faculty of Medicine and Health Sciences (MK FMHS)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.profile.gender;
    _selectedFaculty = widget.profile.faculty;
    _birthdayController = TextEditingController(text: widget.profile.birthday);
  }

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 30),
              // Name Field
              Container(
                height: 90, // Reserve space for error message
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: widget.profile.fullName,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        widget.profile.fullName = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Gender Dropdown
              Container(
                height: 90, // Reserve space for error message
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      value:
                          _genders.contains(_selectedGender)
                              ? _selectedGender
                              : null, // Ensure valid value
                      items:
                          _genders.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a gender';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Faculty Dropdown
              Container(
                height: 90, // Reserve space for error message
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Faculty',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      value:
                          _faculties.contains(_selectedFaculty)
                              ? _selectedFaculty
                              : null, // Ensure valid value
                      items:
                          _faculties.map((String faculty) {
                            return DropdownMenuItem<String>(
                              value: faculty,
                              child: Text(
                                faculty, // Full text visible in the dropdown menu
                              ),
                            );
                          }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return _faculties.map((String faculty) {
                          return Text(
                            faculty,
                            overflow:
                                TextOverflow
                                    .ellipsis, // Truncate text with ellipsis
                            maxLines: 1, // Ensure the text stays on one line
                            style: const TextStyle(
                              fontSize: 16, // Adjust font size if needed
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (newValue) {
                        setState(() {
                          _selectedFaculty = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a faculty';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Birthday Field
              Container(
                height: 90, // Reserve space for error message
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _birthdayController,
                      decoration: InputDecoration(
                        labelText: 'Birthday',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(widget.profile.birthday) ??
                              DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _birthdayController.text =
                                '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your birthday';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Save Button
              Container(
                height: 70, // Reserve space for the button and loading indicator
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Save the updated data
                      final updatedProfile = ProfileModel(
                        fullName: widget.profile.fullName,
                        email: widget.profile.email, // Email remains unchanged
                        gender: _selectedGender ?? widget.profile.gender,
                        birthday: _birthdayController.text,
                        faculty: _selectedFaculty ?? widget.profile.faculty,
                      );

                      try {
                        // Query Firestore to find the document with the matching email
                        final querySnapshot = await FirebaseFirestore.instance
                            .collection('users') // Replace 'users' with your collection name
                            .where('email', isEqualTo: widget.profile.email)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          // Get the document ID of the first matching document
                          final docId = querySnapshot.docs.first.id;

                          // Update the document
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(docId)
                              .update({
                            'fullName': updatedProfile.fullName,
                            'gender': updatedProfile.gender,
                            'birthday': updatedProfile.birthday,
                            'faculty': updatedProfile.faculty,
                          });

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Profile updated successfully',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );

                          // Return updated profile to the previous screen
                          Navigator.pop(context, updatedProfile);
                        } else {
                          // Show error if no matching document is found
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.error, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'No matching profile found to update.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  'Failed to update profile: $error',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_formKey.currentState?.validate() ==
                  false) // Display error message if validation fails
                Text(
                  'Please correct the errors above.',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
