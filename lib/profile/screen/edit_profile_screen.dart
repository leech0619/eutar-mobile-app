import 'package:flutter/material.dart';
import '../model/profile_model.dart';
import '../controller/edit_profile_controller.dart';

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

  final EditProfileController _controller = EditProfileController();

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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = ProfileModel(
        fullName: widget.profile.fullName,
        email: widget.profile.email, // Email remains unchanged
        gender: _selectedGender ?? widget.profile.gender,
        birthday: _birthdayController.text,
        faculty: _selectedFaculty ?? widget.profile.faculty,
      );

      try {
        final success = await _controller.updateProfile(updatedProfile);

        if (success) {
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

          // Return to ProfileScreen with success result
          Navigator.pop(context, true);
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
              const SizedBox(height: 20),
              // Name Field
              Container(
                height: 80,
                child: TextFormField(
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
              ),
              const SizedBox(height: 10),
              // Gender Dropdown
              Container(
                height: 80,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  value:
                      _genders.contains(_selectedGender)
                          ? _selectedGender
                          : null,
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
              ),
              const SizedBox(height: 10),
              // Faculty Dropdown
              Container(
                height: 80,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Faculty',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  value: _faculties.contains(_selectedFaculty) ? _selectedFaculty : null,
                  items: _faculties.map((String faculty) {
                    return DropdownMenuItem<String>(
                      value: faculty,
                      child: Text(
                        faculty,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFaculty = newValue;
                    });
                  },
                  selectedItemBuilder: (BuildContext context) {
                    return _faculties.map((String faculty) {
                      return Text(
                        faculty,
                        overflow: TextOverflow.ellipsis, // Truncate text with ellipsis
                        maxLines: 1,
                        style: const TextStyle(fontSize: 16),
                      );
                    }).toList();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a faculty';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Birthday Field
              Container(
                height: 90,
                child: TextFormField(
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
              ),
              const SizedBox(height: 20),
              // Save and Cancel Buttons
              Column(
                children: [
                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _saveChanges,
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
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
