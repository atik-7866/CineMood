import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart'; // Import video_player package

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
  String userEmail = ""; // To store the logged-in user's email

  // Video player controller
  VideoPlayerController? _videoPlayerController;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
    _loadUserEmail(); // Load the logged-in user's email
    checkIfFavorite();
  }

  @override
  void dispose() {
    // Dispose of the video player controller when the widget is disposed
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail =
          prefs.getString('userEmail') ?? ""; // Get the logged-in user's email
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

  Future<void> _watchTrailer() async {
    // Replace this with the actual trailer URL (e.g., from an API or hardcoded)
    const String trailerUrl =
        "https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";

    setState(() {
      _isVideoLoading = true;
    });

    // Initialize the video player controller
    _videoPlayerController = VideoPlayerController.network(trailerUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoLoading = false;
        });
        _videoPlayerController?.play(); // Auto-play the video
      }).catchError((error) {
        setState(() {
          _isVideoLoading = false;
          errorMessage = "Failed to load trailer: $error";
        });
      });
  }

  Future<void> checkIfFavorite() async {
    if (userEmail.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Get the wishlist for the logged-in user (mapped by email)
      String? wishlist = prefs.getString(userEmail); // Get wishlist as a comma-separated string

      setState(() {
        // Check if the current movie is in the wishlist
        isFavorite = wishlist != null && wishlist.split(',').contains(widget.imdbID);
      });
    }
  }

  Future<void> toggleWishlist() async {
    if (userEmail.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? wishlist = prefs.getString(userEmail) ?? ''; // Get the wishlist for the user

      List<String> userMovies = wishlist.isNotEmpty ? wishlist.split(',') : []; // Split to get individual movie IDs

      setState(() {
        if (isFavorite) {
          userMovies.remove(widget.imdbID); // Remove from wishlist
        } else {
          userMovies.add(widget.imdbID); // Add to wishlist
        }
        isFavorite = !isFavorite;
      });

      // Save the updated wishlist back to SharedPreferences
      await prefs.setString(userEmail, userMovies.join(',')); // Save as a comma-separated string
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          movieData?["Title"] ?? "Movie Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF60063F), // Dark magenta for AppBar
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white, // White for icon color
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF150F13), // Dark magenta at the top
              const Color(0xFF752145), // Lighter pink/magenta transition
              Colors.black, // Black at the bottom for a smooth fade
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster Image Section
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
              if (movieData?["Ratings"] != null && movieData?["Ratings"].isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: movieData?["Ratings"].map<Widget>((rating) {
                    return _ratingCard(rating["Source"], rating["Value"], Colors.orangeAccent);
                  }).toList() ?? [],
                ),

              const SizedBox(height: 20),

              // Plot Section with distinct background
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color(0xFFF8E2F1), // Light pinkish background for plot
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _plotSection(),
              ),
              const SizedBox(height: 20),

              // BoxOffice Section
              _boxOfficeSection(movieData?["BoxOffice"]),
              const SizedBox(height: 20),

              // Styled Information Sections with light text color
              _styledInfoSection(
                "Director",
                movieData?["Director"],
                textColor: Color(0xFFD8A7BB), // Light pinkish color
              ),
              _styledInfoSection(
                "Actors",
                movieData?["Actors"],
                textColor: Color(0xFFD8A7BB), // Light pinkish color
              ),
              _styledInfoSection(
                "Duration | Genre",
                "${movieData?["Runtime"]} | ${movieData?["Genre"]}",
                textColor: Color(0xFFD8A7BB), // Light pinkish color
              ),
              _styledInfoSection(
                "Awards",
                movieData?["Awards"],
                textColor: Color(0xFFD8A7BB), // Light pinkish color
              ),

              const SizedBox(height: 20),

              // Video Player Section
              if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ),

              if (_isVideoLoading)
                const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 20),

              // Watch Trailer Button
              Center(
                child: _customButton(
                  Icons.play_arrow,
                  "Watch Trailer",
                  _watchTrailer,
                  const Color(0xFF752145), // Lighter pink/magenta color for button
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledInfoSection(String title, String? value, {Color textColor = const Color(0xFFD8A7BB)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor, // Use the passed textColor here
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? "Not Available",
            style: TextStyle(
              fontSize: 16,
              color: textColor, // Use the passed textColor here as well
            ),
          ),
        ],
      ),
    );
  }

  Widget _customButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, // Use backgroundColor instead of primary
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
        Text(platform.replaceAll("Internet Movie Database", "IMDb"),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFFD8A7BB))),
      ],
    )
        : const SizedBox();
  }

  Widget _boxOfficeSection(String? boxOffice) {
    return boxOffice != null && boxOffice.isNotEmpty
        ? Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.green[800]),
          const SizedBox(width: 10),
          Text("Box Office: $boxOffice",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    )
        : const SizedBox();
  }

  Widget _plotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Plot",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          movieData?["Plot"] ?? "No plot available",
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}