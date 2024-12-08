import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'channel_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscureText = true; // Track password visibility

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update Display Name with the Username
      await userCredential.user?.updateDisplayName(_usernameController.text.trim());
      await userCredential.user?.reload(); // Ensure changes are applied.

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up successful!')));

      // Navigate to the ChannelScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChannelScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText, // Toggle password visibility
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off, // Toggle icon
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // Toggle visibility
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
