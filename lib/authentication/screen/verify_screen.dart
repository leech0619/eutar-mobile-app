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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Verify Your Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Container for the email verification image
            SizedBox(
              height: 300, // Fixed height for the image
              child: Image.asset(
                'assets/images/email_verification.png',
                height: 300,
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
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
            const SizedBox(height: 20),
            // Container for the Resend Email Button
            SizedBox(
              height: 60, // Fixed height for the button
              child: SizedBox(
                width: 200, // Set a fixed width for the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        controller.emailResent
                            ? Colors
                                .grey // Grey if email has been resent
                            : (controller.canResendEmail
                                ? Colors.blue
                                : Colors.blueGrey),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed:
                      controller.canResendEmail && !controller.emailResent
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
            const SizedBox(height: 20),
            // Container for the Navigate to Login button
            SizedBox(
              height: 60, // Fixed height for the button
              child: SizedBox(
                width: 200, // Set the same fixed width for the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
            const SizedBox(height: 10),
            // Container for the error message
            SizedBox(
              height: 20, // Fixed height for the error message
              child:
                  controller.errorMessage != null
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
