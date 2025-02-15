import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  final String apiKey = "e28238e7"; // Use your API key

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
  }

  Future<void> fetchMovieDetails() async {
    final String url = "https://www.omdbapi.com/?apikey=$apiKey&i=${widget.imdbID}";

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
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load movie details: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching movie details: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movie Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster
            Center(
              child: movieData?["Poster"] != null && movieData?["Poster"] != "N/A"
                  ? Image.network(
                movieData!["Poster"],
                height: 300,
              )
                  : Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported,
                    size: 50, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            // Movie Title
            Text(
              movieData?["Title"] ?? "Unknown Title",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Movie Details
            Text("Year: ${movieData?["Year"] ?? "Unknown"}"),
            Text("Genre: ${movieData?["Genre"] ?? "Unknown"}"),
            Text("Director: ${movieData?["Director"] ?? "Unknown"}"),
            Text("Plot: ${movieData?["Plot"] ?? "No plot available"}"),
          ],
        ),
      ),
    );
  }
}
