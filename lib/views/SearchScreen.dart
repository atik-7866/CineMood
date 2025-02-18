import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
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

  final String omdbApiKey = "e28238e7";

  late stt.SpeechToText _speech;
  bool _isListening = false;

  String searchType = "Title"; // Default search type

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) return;
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    String url;
    if (searchType == "Title") {
      url = "https://www.omdbapi.com/?apikey=$omdbApiKey&s=$query";
    } else if (searchType == "Genre") {
      url =
      "https://www.omdbapi.com/?apikey=$omdbApiKey&type=movie&genre=$query";
    } else {
      url =
      "https://www.omdbapi.com/?apikey=$omdbApiKey&type=movie&actor=$query";
    }

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
          errorMessage =
          "Failed to load search results: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error searching movies: $e";
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
        onSoundLevelChange: (level) => print("Sound level: $level"),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });

    if (_controller.text.isNotEmpty) {
      searchMovies(_controller.text);
    }
  }

  void navigateToMovieDetail(String imdbID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(imdbID: imdbID),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Movies"),
        backgroundColor: const Color(0xFF752145), // Dark Pink shade for AppBar
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF150F13), // Dark magenta at the top
              const Color(0xFF752145), // Lighter pink/magenta transition
              Colors.black,// Light pink transition
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white), // Set the text color to white
                    decoration: InputDecoration(
                      hintText: "Enter search term",
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true, // Ensures background color if needed
                      fillColor: Colors.transparent, // No background color interference
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white), // Border color
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white), // Default border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFFD8A7BB)), // Focused color
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: Color(0xFFD8A7BB)),
                            onPressed: () => searchMovies(_controller.text),
                          ),
                          IconButton(
                            icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Color(0xFFD8A7BB)),
                            onPressed: () {
                              if (_isListening) {
                                _stopListening();
                              } else {
                                _startListening();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: searchType,
                  items: ["Title", "Genre", "Actor"].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: const TextStyle(
                            color: Color(0xFFD8A7BB)), // Light pink text color
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        searchType = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading) const CircularProgressIndicator(),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.white38),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final movie = searchResults[index];
                  return ListTile(
                    leading: movie["Poster"] != "N/A"
                        ? Image.network(movie["Poster"], width: 50)
                        : const Icon(Icons.movie),
                    title: Text(
                      movie["Title"] ?? "Unknown",
                      style: const TextStyle(
                        color: Color(0xFFD8A7BB), // Light pink text color
                      ),
                    ),
                    subtitle: Text(
                      "Year: ${movie["Year"] ?? "Unknown"}",
                      style: const TextStyle(
                        color: Color(0xFFD8A7BB), // Light pink text color
                      ),
                    ),
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