import 'package:flutter/material.dart';
import '../controller/verify_controller.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final VerifyController controller = VerifyController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Verify Your Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, // 5% of screen width
          vertical: screenHeight * 0.02, // 2% of screen height
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Container for the email verification image
            SizedBox(
              height: screenHeight * 0.3, // 30% of screen height
              child: Image.asset(
                'assets/images/email_verification.png',
                height: screenHeight * 0.3, // 30% of screen height
                width: screenWidth * 0.6, // 60% of screen width
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: screenHeight * 0.03), // 3% of screen height
            // Informational message
            const Text(
              'Please check your email to verify your account.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.02), // 2% of screen height
            // Container for the Resend Email Button
            SizedBox(
              height: screenHeight * 0.08, // 8% of screen height
              child: SizedBox(
                width: screenWidth * 0.6, // 60% of screen width
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.emailResent
                        ? Colors.grey // Grey if email has been resent
                        : (controller.canResendEmail
                            ? Colors.blue
                            : Colors.blueGrey),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02, // 2% of screen height
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: controller.canResendEmail && !controller.emailResent
                      ? () async {
                          await controller.resendEmailVerification(context);
                          setState(() {}); // Trigger UI update
                        }
                      : null,
                  child: Text(
                    controller.emailResent
                        ? 'Resent Email' // Change text to "Resent Email"
                        : (controller.canResendEmail
                            ? 'Resend Email'
                            : 'Wait 60s'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02), // 2% of screen height
            // Container for the Navigate to Login button
            SizedBox(
              height: screenHeight * 0.08, // 8% of screen height
              child: SizedBox(
                width: screenWidth * 0.6, // 60% of screen width
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02, // 2% of screen height
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => controller.navigateToLogin(context),
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% of screen height
            // Container for the error message
            SizedBox(
              height: screenHeight * 0.03, // 3% of screen height
              child: controller.errorMessage != null
                  ? Text(
                      controller.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}