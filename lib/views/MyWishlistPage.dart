import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:registeration/views/MovieDetailCommon.dart';
// import 'package:registeration/views/MovieDetailScreen.dart'; // Adjust path if needed

class MyWishlistPage extends StatefulWidget {
  const MyWishlistPage({super.key});

  @override
  State<MyWishlistPage> createState() => _MyWishlistPageState();
}

class _MyWishlistPageState extends State<MyWishlistPage> {
  final String apiKey = "e28238e7";
  late Future<List<Map<String, dynamic>>> _wishlistMovies;

  @override
  void initState() {
    super.initState();
    _wishlistMovies = fetchWishlistMovies();
  }

  Future<List<Map<String, dynamic>>> fetchWishlistMovies() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final username = user.email!.split('@')[0];

    final snapshot = await FirebaseFirestore.instance
        .collection('user_wishlist')
        .where('username', isEqualTo: username)
        .get();

    List<Map<String, dynamic>> movies = [];

    for (var doc in snapshot.docs) {
      final imdbID = doc['imdbID'];
      final url = "https://www.omdbapi.com/?apikey=$apiKey&i=$imdbID";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["Response"] == "True") {
          movies.add(data);
        }
      }
    }

    return movies;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist"),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _wishlistMovies,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text("Error loading wishlist", style: TextStyle(color: Colors.white)),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Your wishlist is empty.", style: TextStyle(color: Colors.white)),
              );
            }

            final movies = snapshot.data!;
            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(imdbID: movie["imdbID"]),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: const Color(0xFFF8E2F1),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.network(
                            movie["Poster"] != "N/A"
                                ? movie["Poster"]
                                : "https://via.placeholder.com/150",
                            height: 140,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie["Title"] ?? "Unknown Title",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF60063F),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${movie["Year"]} | ${movie["Genre"]}",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
