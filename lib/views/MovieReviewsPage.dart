import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MovieReviewsPage extends StatefulWidget {
  final String imdbID;
  final String movieTitle; // ✅ Add movieTitle

  const MovieReviewsPage({
    super.key,
    required this.imdbID,
    required this.movieTitle, // ✅ Pass movieTitle
  });

  @override
  State<MovieReviewsPage> createState() => _MovieReviewsPageState();
}

class _MovieReviewsPageState extends State<MovieReviewsPage> {
  final _controller = TextEditingController();
  double _rating = 3.0;
  bool _isEditing = false;
  DocumentSnapshot? myReview;

  @override
  void initState() {
    super.initState();
    _fetchMyReview();
  }

  Future<void> _fetchMyReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('user_reviews')
        .where('imdbID', isEqualTo: widget.imdbID)
        .where('userEmail', isEqualTo: user.email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        myReview = query.docs.first;
        _controller.text = myReview!['review'];
        _rating = (myReview!['rating'] as num).toDouble();
        _isEditing = true;
      });
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;

    final username = user.email!.split('@')[0];

    final data = {
      'imdbID': widget.imdbID,
      'movieTitle': widget.movieTitle, // ✅ Store movieTitle
      'userEmail': user.email,
      // 'username': username,
      'review': _controller.text.trim(),
      'rating': _rating,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_isEditing && myReview != null) {
      await FirebaseFirestore.instance
          .collection('user_reviews')
          .doc(myReview!.id)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('user_reviews').add(data);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Review updated' : 'Review added')),
    );

    setState(() {
      _isEditing = true;
    });

    _fetchMyReview();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movieTitle), // ✅ Optional: Show movie title in AppBar
        backgroundColor: const Color(0xFF60063F),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_reviews')
                  .where('imdbID', isEqualTo: widget.imdbID)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading reviews: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reviews yet."));
                }

                final reviews = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: reviews.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .where('email', isEqualTo: data['userEmail'])
                              .limit(1)
                              .get()
                              .then((snapshot) => snapshot.docs.first),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Loading...');
                            } else if (snapshot.hasError || !snapshot.hasData) {
                              return const Text('Unknown');
                            }

                            final userDoc = snapshot.data!.data() as Map<String, dynamic>;
                            return Text(
                              userDoc['username'] ?? data['userEmail'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),


                        subtitle: Text(data['review'] ?? ''),
                        trailing: Text('⭐ ${data['rating'] ?? 'N/A'}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? "Edit your review:" : "Add your review:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter your review here...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Rating: "),
                    Slider(
                      value: _rating,
                      min: 0,
                      max: 10,
                      divisions: 20,
                      label: _rating.toStringAsFixed(1),
                      onChanged: (val) => setState(() => _rating = val),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _submitReview,
                    icon: const Icon(Icons.send),
                    label: Text(_isEditing ? "Update Review" : "Submit Review"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF752145),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
