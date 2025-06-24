import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyReviewsPage extends StatelessWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reviews"),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_reviews')
              .where('userEmail', isEqualTo: user.email)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading your reviews: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "You haven't posted any reviews yet.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final reviews = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final data = reviews[index].data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                final dateStr = timestamp != null
                    ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                    : 'N/A';

                return Card(
                  color: const Color(0xFFF8E2F1),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      data['movieTitle'] ?? 'Untitled Movie',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF60063F),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(data['review'] ?? ''),
                        const SizedBox(height: 4),
                        Text("⭐ ${data['rating'] ?? 'N/A'}"),
                        Text("🕒 $dateStr", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
