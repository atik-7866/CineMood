import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MovieDetailCommon.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String errorMessage = "";

  final String omdbApiKey = "e28238e7"; // Replace with your OMDb API key

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) return;
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final String url = "https://www.omdbapi.com/?apikey=$omdbApiKey&s=$query";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData["Response"] == "True") {
          setState(() {
            searchResults = decodedData["Search"];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = decodedData["Error"] ?? "No results found.";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load search results: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error searching movies: $e";
      });
    }
  }

  void navigateToMovieDetail(String imdbID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(imdbID: imdbID, isFromRapidApi: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Movies")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Enter movie name",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchMovies(_controller.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (errorMessage.isNotEmpty) Text(errorMessage, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final movie = searchResults[index];
                  return ListTile(
                    leading: movie["Poster"] != "N/A" ? Image.network(movie["Poster"], width: 50) : const Icon(Icons.movie),
                    title: Text(movie["Title"] ?? "Unknown"),
                    subtitle: Text("Year: ${movie["Year"] ?? "Unknown"}"),
                    onTap: () => navigateToMovieDetail(movie["imdbID"]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}