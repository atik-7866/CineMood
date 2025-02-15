import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailScreen extends StatefulWidget {
  final String imdbID;
  final bool isFromRapidApi;

  const MovieDetailScreen({super.key, required this.imdbID, this.isFromRapidApi = false});

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Map<String, dynamic>? movieData;
  bool isLoading = true;
  String errorMessage = "";
  bool isFavorite = false;

  final String omdbApiKey = "e28238e7"; // Replace with your OMDb API key
  final String rapidApiKey = "222cdddb17msh20db10d9fbd80b0p19f20ajsnc7e766c3fb2d"; // Replace with your RapidAPI key

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
    checkIfFavorite();
  }

  Future<void> fetchMovieDetails() async {
    String url;
    Map<String, String> headers = {};

    // if (widget.isFromRapidApi) {
    //   url = "https://imdb236.p.rapidapi.com/imdb/india/upcoming";
    //   headers = {
    //     "X-RapidAPI-Key": rapidApiKey,
    //     "X-RapidAPI-Host": "imdb236.p.rapidapi.com"
    //   };
    // } else {
      url = "https://www.omdbapi.com/?apikey=$omdbApiKey&i=${widget.imdbID}";
    // }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData["Response"] == "True" || widget.isFromRapidApi) {
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

  Future<void> _watchTrailer() async {
    final String trailerUrl = "https://www.imdb.com/title/${widget.imdbID}/videogallery/";
    if (await canLaunchUrl(Uri.parse(trailerUrl))) {
      await launchUrl(Uri.parse(trailerUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch trailer link.")));
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

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFavorite ? "Added to Wishlist!" : "Removed from Wishlist!")));
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
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              movieData?["Title"] ?? "Unknown Title",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Year: ${movieData?["Year"] ?? "Unknown"}"),
            Text("Genre: ${movieData?["Genre"] ?? "Unknown"}"),
            Text("Director: ${movieData?["Director"] ?? "Unknown"}"),
            Text("Plot: ${movieData?["Plot"] ?? "No plot available"}"),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _watchTrailer,
            child: const Icon(Icons.play_arrow),
            tooltip: "Watch Trailer",
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: toggleWishlist,
            child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            tooltip: isFavorite ? "Remove from Wishlist" : "Add to Wishlist",
          ),
        ],
      ),
    );
  }
}
