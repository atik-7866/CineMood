import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Ensure user is signed out before signing in

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(notesRoute, (route) => false);
      }
    } catch (e) {
      showErrorDialog(context, "Failed to sign in with Google. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color(0xFF752145),
            Colors.black,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF100A0C),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Color(0xFFB8336A), fontWeight: FontWeight.bold),
                    hintText: "Enter your Email here",
                    prefixIcon: const Icon(Icons.email, color: Color(0xFFB8336A)),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Color(0xFFB8336A), fontWeight: FontWeight.bold),
                    hintText: "Enter your Password here",
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFB8336A)),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8336A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final email = _email.text;
                    final password = _password.text;

                    if (email.isEmpty || password.isEmpty) {
                      showErrorDialog(context, "Please enter both email and password.");
                      return;
                    }

                    try {
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _signInWithGoogle,
                  child: SizedBox(
                    width: double.infinity, // Ensure full width
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Prevent unnecessary stretching
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            "Sign in with Google",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis, // Prevents overflow
                            softWrap: false, // Keeps text on a single line
                          ),
                        ),
                      ],
                    ),
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
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      decorationThickness: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
