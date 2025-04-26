import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controller/register_controller.dart';

// This screen allows users to register by filling out a form.
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
    // Listen to changes in the controller to update UI
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name Field
              _buildTextFieldWithFixedHeight(
                label: 'Full Name (as per IC)',
                controller: _controller.fullNameController,
                validator: _controller.validateFullName,
                errorMessage: _controller.errorMessage,
                screenWidth: screenWidth,
              ),

              // Gender and Birthday Fields in the same row
              Row(
                children: [
                  // Gender Dropdown
                  Expanded(
                    child: _buildDropdownFieldWithFixedHeight(
                      label: 'Gender',
                      value: _controller.selectedGender,
                      items: _controller.genders,
                      onChanged: (newValue) {
                        setState(() {
                          _controller.selectedGender = newValue;
                        });
                      },
                      validator: _controller.validateGender,
                      errorMessage: _controller.errorMessage,
                      screenWidth: screenWidth,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Birthday Date Picker Field
                  Expanded(
                    child: _buildTextFieldWithFixedHeight(
                      label: 'Birthday',
                      controller: _controller.birthdayController,
                      validator: _controller.validateBirthday,
                      errorMessage: _controller.errorMessage,
                      screenWidth: screenWidth,
                      readOnly: true,
                      onTap: () async {
                        // Show a date picker dialog
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
                    ),
                  ),
                ],
              ),

              // Faculty Dropdown Field
              _buildDropdownFieldWithFixedHeight(
                label: 'Faculty',
                value: _controller.selectedFaculty,
                items: _controller.faculties,
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
                errorMessage: _controller.errorMessage,
                screenWidth: screenWidth,
              ),

              // Email Field
              _buildTextFieldWithFixedHeight(
                label: 'Email',
                controller: _controller.emailController,
                validator: (value) {
                  String? result;
                  _controller.validateEmail(value).then((validationResult) {
                    result = validationResult;
                  });
                  return result;
                },
                errorMessage: _controller.errorMessage,
                screenWidth: screenWidth,
              ),

              // Password Field
              _buildTextFieldWithFixedHeight(
                label: 'Password',
                controller: _controller.passwordController,
                validator: _controller.validatePassword,
                errorMessage: _controller.errorMessage,
                screenWidth: screenWidth,
                obscureText: true,
              ),

              // Confirm Password Field
              _buildTextFieldWithFixedHeight(
                label: 'Confirm Password',
                controller: _controller.confirmPasswordController,
                validator: _controller.validateConfirmPassword,
                errorMessage: _controller.errorMessage,
                screenWidth: screenWidth,
                obscureText: true,
              ),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child:
                    _controller.isLoading
                        ? const Center(
                          child: CircularProgressIndicator(),
                        ) // Show loading spinner while registering
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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

              // Display error message if any
              if (_controller.errorMessage != null)
                Center(
                  child: Text(
                    _controller.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable text field widget with consistent height and error display
  Widget _buildTextFieldWithFixedHeight({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    String? errorMessage,
    required double screenWidth,
    bool readOnly = false,
    bool obscureText = false,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 80,
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            onTap: onTap,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: validator,
          ),
          if (errorMessage != null)
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // Reusable dropdown widget with consistent height and error display
  Widget _buildDropdownFieldWithFixedHeight({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
    String? errorMessage,
    required double screenWidth,
  }) {
    return Container(
      height: 80,
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            value: value,
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
            onChanged: onChanged,
            validator: validator,
            selectedItemBuilder: (BuildContext context) {
              return items.map((String item) {
                return Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 16),
                );
              }).toList();
            },
          ),
          if (errorMessage != null)
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
