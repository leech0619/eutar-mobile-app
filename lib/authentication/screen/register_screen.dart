import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController _controller = RegisterController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Update the UI when the controller notifies listeners
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Register',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _controller.formKey,
          child: ListView(
            children: [
              // Full Name Field
              Container(
                height: 90, // Text field height + error message height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller.fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name (as per IC)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: _controller.validateFullName,
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('full name'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Gender Dropdown
              Container(
                height: 90, // Dropdown height + error message height
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
                      value: _controller.selectedGender,
                      items:
                          _controller.genders.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _controller.selectedGender = newValue;
                        });
                      },
                      validator: _controller.validateGender,
                      isExpanded: true,
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('gender'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Birthday Field
              Container(
                height: 90, // Text field height + error message height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller.birthdayController,
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
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _controller.birthdayController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                          });
                        }
                      },
                      validator: _controller.validateBirthday,
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('birthday'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Faculty Dropdown
              Container(
                height: 90, // Dropdown height + error message height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded:
                          true, // Ensures the dropdown expands to fit the text
                      decoration: InputDecoration(
                        labelText: 'Faculty',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      value: _controller.selectedFaculty,
                      items:
                          _controller.faculties.map((String faculty) {
                            return DropdownMenuItem<String>(
                              value: faculty,
                              child: Text(
                                faculty, // Full text visible in the dropdown menu
                              ),
                            );
                          }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return _controller.faculties.map((String faculty) {
                          return Text(
                            faculty,
                            overflow:
                                TextOverflow
                                    .ellipsis, // Truncate text with ellipsis
                            maxLines: 1,
                          );
                        }).toList();
                      },
                      onChanged: (newValue) {
                        setState(() {
                          _controller.selectedFaculty = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a faculty';
                        }
                        return null;
                      },
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('faculty'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Email Field
              Container(
                height: 90, // Text field height + error message height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller.emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: _controller.validateEmail,
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('email'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Password Field
              Container(
                height: 90, // Text field height + error message height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller.passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: _controller.validatePassword,
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('password'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Confirm Password Field
              Container(
                height: 100, // Text field height + error message height
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _controller.confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Confirm Password.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: _controller.validateConfirmPassword,
                    ),
                    if (_controller.errorMessage != null &&
                        _controller.errorMessage!.contains('confirm password'))
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),

              // Register Button
              Container(
                height:
                    70, // Reserve space for the button and loading indicator
                alignment: Alignment.center,
                child:
                    _controller.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
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
                          onPressed: () => _controller.register(context),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 20),
              if (_controller.errorMessage !=
                  null) // Display error message if it exists
                Text(
                  _controller.errorMessage!,
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
