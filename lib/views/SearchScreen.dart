import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:registeration/views/MovieDetailPage.dart';
import 'package:registeration/views/MovieDetailScreen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}
final String apiKey = "e28238e7";

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _movies = [];
  bool _isLoading = false;
  String _errorMessage = "";

  // final String apiKey = "e28238e7";

  // Function to fetch movies
  Future<void> fetchMovies(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final url = Uri.parse("https://www.omdbapi.com/?apikey=$apiKey&s=$query");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["Response"] == "True") {
          setState(() {
            _movies = data["Search"];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "No movies found!";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error fetching data!";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Something went wrong!";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Movies")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Search TextField
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Search for movies...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: fetchMovies, // Call API when user presses enter
            ),

            const SizedBox(height: 10),

            // Show Loading Indicator
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Show Error Message
            if (_errorMessage.isNotEmpty)
              Center(
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
              ),

            // Show Movies Grid
            Expanded(
              child: _movies.isNotEmpty
                  ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  childAspectRatio: 0.7, // Adjust aspect ratio for better fit
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _movies.length,
                itemBuilder: (context, index) {
                  final movie = _movies[index];

                  return GestureDetector(
                    onTap: () => navigateToMovieDetail(context, movie["imdbID"]),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Movie Poster
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: Image.network(
                                movie["Poster"],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Movie Title
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              movie["Title"],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Movie Year
                          Text(
                            movie["Year"] ?? "Unknown Year",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
                  : const Center(child: Text("Search for movies to display results")),
            ),
          ],
        ),
      ),
    );
  }
}

void navigateToMovieDetail(BuildContext context, String imdbID) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MovieDetailScreen(imdbID: imdbID),
    ),
  );
}


