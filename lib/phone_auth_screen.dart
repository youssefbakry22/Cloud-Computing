import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'channel_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  late String verificationId;
  bool isCodeSent = false;

  void verifyPhoneNumber() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
          _checkDisplayName(userCredential.user);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isCodeSent = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OTP sent to the phone number')),
            );
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void signInWithOTP() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      _checkDisplayName(userCredential.user);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _checkDisplayName(User? user) {
    if (user != null) {
      if (user.displayName == null || user.displayName!.isEmpty) {
        // Ask for display name if not set
        _askForDisplayName(user);
      } else {
        // Navigate to the main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChannelScreen()),
        );
      }
    }
  }

  void _askForDisplayName(User user) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Display Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  try {
                    await user.updateDisplayName(nameController.text.trim());
                    await user.reload();

                    Navigator.pop(context); // Close the dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ChannelScreen()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid name')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isCodeSent) ...[
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: verifyPhoneNumber,
                child: Text('Send OTP'),
              ),
            ] else ...[
              TextField(
                controller: otpController,
                decoration: InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: signInWithOTP,
                child: Text('Verify OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
