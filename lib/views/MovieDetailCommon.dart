import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:registeration/views/MyWishlistPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:registeration/views/MovieReviewsPage.dart';


// const String tmdbApiKey = '1a58119be39c7a19d754ca6f860b0129';

class MovieDetailPageView extends StatefulWidget {
  final List<String> movieIds;
  final int initialIndex;

  const MovieDetailPageView({
    super.key,
    required this.movieIds,
    this.initialIndex = 0,
  });

  @override
  _MovieDetailPageViewState createState() => _MovieDetailPageViewState();
}

class _MovieDetailPageViewState extends State<MovieDetailPageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.movieIds.length,
          scrollDirection: Axis.horizontal,
          pageSnapping: true,
          itemBuilder: (context, index) {
            return MovieDetailScreen(imdbID: widget.movieIds[index]);
          },
        ),
      ),
    );
  }
}

class MovieDetailScreen extends StatefulWidget {
  final String imdbID;

  const MovieDetailScreen({super.key, required this.imdbID});

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Map<String, dynamic>? movieData;
  bool isLoading = true;
  String errorMessage = "";
  bool isFavorite = false;
  final String omdbApiKey = "e28238e7";

  late SharedPreferences _prefs;
  String userEmail = "";

  // List<Map<String, dynamic>> tmdbReviews = [];
  bool hasFetchedReviews = false;

  @override
  void initState() {
    super.initState();
    _initPrefsAndState();
    fetchMovieDetails();
    // if (!hasFetchedReviews) {
    //   // fetchTMDbReviews();
    //   hasFetchedReviews = true;
    // }
  }

  Future<void> _initPrefsAndState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final username = user.email!.split('@')[0];

    final snapshot = await FirebaseFirestore.instance
        .collection('user_wishlist')
        .where('username', isEqualTo: username)
        .where('imdbID', isEqualTo: widget.imdbID)
        .limit(1)
        .get();

    setState(() {
      isFavorite = snapshot.docs.isNotEmpty;
    });
  }


  Future<void> fetchMovieDetails() async {
    String url = "https://www.omdbapi.com/?apikey=$omdbApiKey&i=${widget.imdbID}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData["Response"] == "True") {
          setState(() {
            movieData = decodedData;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = decodedData["Error"] ?? "Failed to fetch details.";
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching movie details: $e";
      });
    }
  }

  // Future<void> fetchTMDbReviews() async {
  //   try {
  //     final tmdbId = await _getTMDbIdFromImdbId(widget.imdbID);
  //     if (tmdbId == null) return;
  //
  //     final url =
  //         "https://api.themoviedb.org/3/movie/$tmdbId/reviews?api_key=$tmdbApiKey";
  //
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {"Accept": "application/json"},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (data["results"] != null) {
  //         setState(() {
  //           tmdbReviews = List<Map<String, dynamic>>.from(data["results"]);
  //         });
  //       }
  //     } else {
  //       debugPrint("TMDb error: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     debugPrint("TMDb review fetch failed: $e");
  //   }
  // }

  // Future<String?> _getTMDbIdFromImdbId(String imdbId) async {
  //   final url =
  //       "https://api.themoviedb.org/3/find/$imdbId?external_source=imdb_id&api_key=$tmdbApiKey";
  //
  //   try {
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {"Accept": "application/json"},
  //     );
  //
  //     if (response.statusCode != 200) {
  //       debugPrint("Failed to get TMDb ID: ${response.statusCode}");
  //       return null;
  //     }
  //
  //     final data = json.decode(response.body);
  //     final results = data["movie_results"];
  //     if (results != null && results.isNotEmpty) {
  //       return results[0]["id"].toString();
  //     }
  //   } catch (e) {
  //     debugPrint("Error getting TMDb ID: $e");
  //     await Future.delayed(Duration(seconds: 2)); // wait 2s before retry
  //     try {
  //       final retryResponse = await http.get(
  //         Uri.parse(url),
  //         headers: {"Accept": "application/json"},
  //       );
  //
  //       if (retryResponse.statusCode == 200) {
  //         final data = json.decode(retryResponse.body);
  //         final results = data["movie_results"];
  //         if (results != null && results.isNotEmpty) {
  //           return results[0]["id"].toString();
  //         }
  //       }
  //     } catch (e2) {
  //       debugPrint("Retry failed: $e2");
  //     }
  //   }
  //
  //   return null;
  // }

  void _watchTrailer() async {
    final trailerUrl = "https://www.imdb.com/title/${widget.imdbID}/videogallery/";
    if (await canLaunch(trailerUrl)) {
      await launch(trailerUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open trailer link")),
      );
    }
  }
  void toggleWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final username = user.email!.split('@')[0];
    final docRef = FirebaseFirestore.instance
        .collection('user_wishlist')
        .where('username', isEqualTo: username)
        .where('imdbID', isEqualTo: widget.imdbID)
        .limit(1);

    final snapshot = await docRef.get();

    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      // Add to Firestore
      if (snapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('user_wishlist').add({
          'username': username,
          'imdbID': widget.imdbID,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Wishlist')),
      );
    } else {
      // Remove from Firestore
      for (var doc in snapshot.docs) {
        await FirebaseFirestore.instance
            .collection('user_wishlist')
            .doc(doc.id)
            .delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Wishlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          movieData?["Title"] ?? "Movie Details",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF60063F),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: toggleWishlist,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: const TextStyle(
            color: Color(0xDFD8A7BB),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF150F13),
              Color(0xFF752145),
              Colors.black,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    movieData?["Poster"] ?? "",
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (movieData?["Ratings"] != null &&
                  movieData?["Ratings"].isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: movieData?["Ratings"]
                      .map<Widget>((rating) {
                    return _ratingCard(
                      rating["Source"],
                      rating["Value"],
                      Colors.orangeAccent,
                    );
                  }).toList() ??
                      [],
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _plotSection(),
              ),
              const SizedBox(height: 20),
              _boxOfficeSection(movieData?["BoxOffice"]),
              const SizedBox(height: 20),
              _styledInfoSection("Director", movieData?["Director"]),
              _styledInfoSection("Actors", movieData?["Actors"]),
              _styledInfoSection("Duration | Genre",
                  "${movieData?["Runtime"]} | ${movieData?["Genre"]}"),
              _styledInfoSection("Awards", movieData?["Awards"]),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    _customButton(
                      Icons.play_arrow,
                      "Watch Trailer",
                      _watchTrailer,
                      const Color(0xFF752145),
                    ),
                    const SizedBox(height: 12),
                    _customButton(
                      Icons.reviews,
                      "See Reviews",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieReviewsPage(imdbID: widget.imdbID, movieTitle: movieData?["Title"] ?? "Untitled Movie", ),
                          ),
                        );
                      },
                      const Color(0xFF45818E),
                    ),
                  ],
                ),
              ),

              // const Text("TMDb Reviews",
              //     style: TextStyle(
              //         color: Colors.white,
              //         fontWeight: FontWeight.bold,
              //         fontSize: 18)),
              // const SizedBox(height: 8),
              // tmdbReviews.isEmpty
              //     ? const Padding(
              //   padding: EdgeInsets.all(8.0),
              //   child: Text(
              //     "No reviews found.",
              //     style: TextStyle(color: Colors.white70),
              //   ),
              // )
              //     : Column(
              //   children: tmdbReviews
              //       .map((review) => ReviewTile(review: review))
              //       .toList(),
              // ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _styledInfoSection(String title, String? value,
      {Color textColor = const Color(0xFFD8A7BB)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(value ?? "Not Available", style: TextStyle(fontSize: 16, color: textColor)),
        ],
      ),
    );
  }

  Widget _customButton(
      IconData icon, String label, VoidCallback onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _ratingCard(String platform, String? rating, Color color) {
    return rating != null && rating.isNotEmpty
        ? Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 25,
          child: Text(
            rating,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          platform.replaceAll("Internet Movie Database", "IMDb"),
          style:
          const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD8A7BB)),
        ),
      ],
    )
        : const SizedBox();
  }

  Widget _boxOfficeSection(String? boxOffice) {
    return boxOffice != null && boxOffice.isNotEmpty
        ? Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.green[800]),
          const SizedBox(width: 10),
          Text("Box Office: $boxOffice",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    )
        : const SizedBox();
  }

  Widget _plotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Plot",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(movieData?["Plot"] ?? "No plot available",
            style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final author = review['author_details']['username'] ?? 'Anonymous';
    final content = review['content'] ?? '';
    final rating = review['author_details']['rating']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
        trailing: Text(rating == 'N/A' ? '' : '⭐ $rating'),
      ),
    );
  }
}

class UserReviewForm extends StatefulWidget {
  final String imdbID;
  final String movieTitle;

  const UserReviewForm({super.key, required this.imdbID,required this.movieTitle,});

  @override
  State<UserReviewForm> createState() => _UserReviewFormState();
}

class _UserReviewFormState extends State<UserReviewForm> {
  final _controller = TextEditingController();
  double _rating = 3.0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await FirebaseFirestore.instance.collection('user_reviews').add({
        'imdbID': widget.imdbID,
        'userEmail': user.email,
        'review': _controller.text.trim(),
        'movieTitle': widget.movieTitle,
        'rating': _rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted")),
      );
    } catch (e) {
      debugPrint("Failed to submit review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit review")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Write a review",
            style: TextStyle(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: "Type your review here...",
            hintStyle: const TextStyle(color: Colors.white60),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text("Rating:",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Slider(
              value: _rating,
              onChanged: (val) => setState(() => _rating = val),
              min: 0,
              max: 10,
              divisions: 20,
              label: _rating.toStringAsFixed(1),
              activeColor: Colors.amber,
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitReview,
            icon: const Icon(Icons.send),
            label: const Text("Submit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF752145),
            ),
          ),
        ),
      ],
    );
  }
}
