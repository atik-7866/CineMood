import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:registeration/views/MyReviewsPage.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _usernameController = TextEditingController();
  String? _profilePic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(
        user!.uid).get();
    final data = doc.data();
    _usernameController.text =
        data?['username'] ?? user!.email!.split('@').first;
    _profilePic = data?['profilePic'];
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'username': _usernameController.text.trim(),
      'profilePic': _profilePic ?? '',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profilePic = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF60063F),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF150F13), Color(0xFF752145), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePic != null &&
                        !_profilePic!.startsWith('http')
                        ? FileImage(File(_profilePic!))
                        : NetworkImage(_profilePic ?? '') as ImageProvider,
                    child: _profilePic == null ? const Icon(
                        Icons.person, size: 50, color: Colors.white) : null,
                    backgroundColor: const Color(0xFF60063F),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF60063F)),
                    ),
                  ),

                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60063F),
                  ),
                  child: const Text("Save Changes"),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyReviewsPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60063F),
                  ),
                  child: const Text("My Reviews"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed("/wishlist"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60063F),
                  ),
                  child: const Text("My Wishlist"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}