import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:registeration/constants/routes.dart';
import 'package:registeration/utilities/show_error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late TextEditingController _email;
  late TextEditingController _password;
  late TextEditingController _phone;
  late TextEditingController _otp;
  bool _isLoading = false;
  bool _isOTPSent = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
    _phone = TextEditingController();
    _otp = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phoneNumber = _phone.text.trim();
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      await showErrorDialog(context, "Enter a valid phone number.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phoneNumber", // Change the country code as needed
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.of(context).pushNamedAndRemoveUntil(notesRoute, (route) => false);
        },
        verificationFailed: (FirebaseAuthException e) {
          showErrorDialog(context, "Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOTPSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      await showErrorDialog(context, "Error sending OTP: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    final smsCode = _otp.text.trim();
    if (smsCode.isEmpty) {
      await showErrorDialog(context, "Enter the OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.of(context).pushNamedAndRemoveUntil(notesRoute, (route) => false);
    } catch (e) {
      await showErrorDialog(context, "Invalid OTP.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      await showErrorDialog(context, "Email or Password cannot be empty.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified ?? false) {
        Navigator.of(context).pushNamedAndRemoveUntil(notesRoute, (route) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(verifyEmailRoute, (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      await showErrorDialog(context, 'Login failed: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0xFF752142), Colors.black],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF170C11),
          title: const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Welcome Back!", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),

                // Email Login
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Color(0xFFB8336A), fontWeight: FontWeight.bold),
                    hintText: "Enter your Email here",
                    prefixIcon: const Icon(Icons.email, color: Color(0xFFB8336A)),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Color(0xFFB8336A), fontWeight: FontWeight.bold),
                    hintText: "Enter your Password here",
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFB8336A)),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB8336A), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _loginWithEmail,
                  child: _isLoading ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)) : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),

                const SizedBox(height: 30),

                // Phone Login
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: const TextStyle(color: Color(0xFFB8336A), fontWeight: FontWeight.bold),
                    hintText: "Enter your phone number",
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFFB8336A)),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor:Color(0xFFB8336A), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _sendOTP,
                  child: const Text("Send OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),

                if (_isOTPSent) ...[
                  const SizedBox(height: 15),
                  TextField(controller: _otp, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Enter OTP", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isLoading ? null : _verifyOTP,
                    child: const Text("Verify OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                ],
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      registerRoute,
                          (route) => false,
                    );
                  },
                  child: const Text(
                    "Not registered yet? Register here!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
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
