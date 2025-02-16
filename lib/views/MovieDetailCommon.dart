import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
    checkIfFavorite();
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
    final String trailerUrl = "https://www.imdb.com/title/${widget.imdbID}/videogallery/";
    if (await canLaunchUrl(Uri.parse(trailerUrl))) {
      await launchUrl(Uri.parse(trailerUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> checkIfFavorite() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wishlist = prefs.getStringList('wishlist') ?? [];
    setState(() {
      isFavorite = wishlist.contains(widget.imdbID);
    });
  }

  Future<void> toggleWishlist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> wishlist = prefs.getStringList('wishlist') ?? [];
    setState(() {
      if (isFavorite) {
        wishlist.remove(widget.imdbID);
      } else {
        wishlist.add(widget.imdbID);
      }
      isFavorite = !isFavorite;
    });
    await prefs.setStringList('wishlist', wishlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movieData?["Title"] ?? "Movie Details"),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: toggleWishlist,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    movieData?["Poster"] ?? "",
                    height: 300,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (movieData?["Ratings"] != null && movieData?["Ratings"].isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: movieData?["Ratings"].map<Widget>((rating) {
                    return _ratingCard(rating["Source"], rating["Value"], Colors.orange);
                  }).toList() ?? [],
                ),
              const SizedBox(height: 20),
              _plotSection(),
              const SizedBox(height: 20),
              _boxOfficeSection(movieData?["BoxOffice"]),
              _styledInfoSection("Director", movieData?["Director"]),
              _styledInfoSection("Actors", movieData?["Actors"]),
              _styledInfoSection("Duration | Genre", "${movieData?["Runtime"]} | ${movieData?["Genre"]}"),
              _styledInfoSection("Awards", movieData?["Awards"]),
              const SizedBox(height: 20),
              Center(
                child: _customButton(Icons.play_arrow, "Watch Trailer", _watchTrailer, Colors.green),
              ),
            ],
          ),
        ),
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
        Text(platform.replaceAll("Internet Movie Database", "IMDb"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    )
        : const SizedBox();
  }

  Widget _styledInfoSection(String title, String? content) {
    return content != null && content.isNotEmpty
        ? Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    )
        : const SizedBox();
  }
  Widget _customButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
          Text("Box Office: $boxOffice", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
