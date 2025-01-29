import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:registeration/constants/routes.dart';
import 'package:registeration/utilities/show_error_dialog.dart';

class RegisterationView extends StatefulWidget {
  const RegisterationView({super.key});

  @override
  State<RegisterationView> createState() => _RegisterationViewState();
}

class _RegisterationViewState extends State<RegisterationView> {
  late TextEditingController _email;
  late TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          "Register",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Create a New Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                enableSuggestions: false,
                autocorrect: false,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your Email here",
                  prefixIcon: const Icon(Icons.email, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: "Enter your Password here",
                  prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final email = _email.text;
                  final password = _password.text;

                  // Add validation to check for empty fields
                  if (email.isEmpty || password.isEmpty) {
                    showErrorDialog(context, "Please enter both email and password.");
                    return;
                  }

                  try {
                    // Create User with email and password
                    final userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    final user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      await user.sendEmailVerification();
                      Navigator.of(context).pushNamed(verifyEmailRoute);
                    } else {
                      showErrorDialog(context, "Error: User could not be created.");
                    }
                  } on FirebaseAuthException catch (e) {
                    // Error handling based on FirebaseAuthException
                    if (e.code == 'weak-password') {
                      showErrorDialog(context, "Weak password. Please try again.");
                    } else if (e.code == "email-already-in-use") {
                      showErrorDialog(context, "This email is already in use.");
                    } else if (e.code == "invalid-email") {
                      showErrorDialog(context, "Invalid email address format.");
                    } else {
                      showErrorDialog(context, "An unexpected error occurred. Please try again.");
                    }
                  } catch (e) {
                    showErrorDialog(context, "An unexpected error occurred. Please try again.");
                  }
                },
                child: const Text(
                  "Register",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                        (route) => false,
                  );
                },
                child: const Text(
                  "Already registered? Login here!",
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
