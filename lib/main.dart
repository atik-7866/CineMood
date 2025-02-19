import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:registeration/constants/routes.dart';
import 'package:registeration/firebase_options.dart';
import 'package:registeration/views/LoginView.dart';
import 'package:registeration/views/MovieDetailCommon.dart';
 import 'package:registeration/views/RegisterationView.dart';
import 'dart:developer' as devtools show log;
import 'package:http/http.dart' as http;
import 'package:registeration/views/SearchScreen.dart';
import 'dart:convert';

import 'package:registeration/views/VerifyEmailView.dart';
import 'package:registeration/views/WishlistPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterationView(),
        notesRoute: (context) => const NotesView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              if (user.emailVerified) {
                return const NotesView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}

enum MenuAction { logout, changePassword }


class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  List<Map<String, dynamic>> boxOfficeMovies = [];
  List<Map<String, dynamic>> trendingMovies = [];
  List<Map<String, dynamic>> topMovies = [];
  bool isLoadingBoxOffice = true;
  bool isLoadingTrending = true;
  bool isLoadingTop = true;
  String errorBoxOffice = "";
  String errorTrending = "";
  String errorTop = "";

  @override
  void initState() {
    super.initState();
    fetchBoxOfficeMovies();
    fetchTrendingMovies();
    fetchTopMovies();
  }

  Future<void> fetchBoxOfficeMovies() async {
    const String url = "https://imdb236.p.rapidapi.com/imdb/top-box-office";
    await fetchMovies(url, category: "boxOffice");
  }

  Future<void> fetchTrendingMovies() async {
    const String url = "https://imdb236.p.rapidapi.com/imdb/most-popular-movies";
    await fetchMovies(url, category: "trending");
  }

  Future<void> fetchTopMovies() async {
    const String url = "https://imdb236.p.rapidapi.com/imdb/top250-movies";
    await fetchMovies(url, category: "top");
  }

  Future<void> fetchMovies(String url, {required String category}) async {
    const Map<String, String> headers = {
      "X-RapidAPI-Host": "imdb236.p.rapidapi.com",
      "X-RapidAPI-Key": "b8da8d822dmsh382b2aefcac888bp13b9a6jsn51c625417a41",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      devtools.log("Response for $category: ${response
          .body}"); // Add this line for debugging

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        devtools.log(
            "Decoded data for $category: $decodedData"); // Log decoded data

        if (decodedData is List) {
          setState(() {
            if (category == "boxOffice") {
              boxOfficeMovies = List<Map<String, dynamic>>.from(decodedData);
              isLoadingBoxOffice = false;
              errorBoxOffice =
              boxOfficeMovies.isEmpty ? "No box office movies found." : "";
            } else if (category == "trending") {
              trendingMovies = List<Map<String, dynamic>>.from(decodedData);
              isLoadingTrending = false;
              errorTrending =
              trendingMovies.isEmpty ? "No trending movies found." : "";
            } else {
              topMovies = List<Map<String, dynamic>>.from(decodedData);
              isLoadingTop = false;
              errorTop = topMovies.isEmpty ? "No top movies found." : "";
            }
          });
        } else {
          devtools.log("Unexpected data format: $decodedData");
        }
      } else {
        devtools.log("Failed to fetch movies: ${response.statusCode}");
      }
    } catch (e) {
      devtools.log("Error fetching movies: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF60063F), // Dark magenta for AppBar
        title: const Text(
          "Main UI",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
            color: Colors.white, // White color for the search icon
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WishlistPage(),
                  ),
                );
              }
            },
            color: Colors.white, // White color for the heart icon
          ),
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    try {
                      await FirebaseAuth.instance.signOut();
                      devtools.log("User signed out successfully.");
                      Navigator.of(context).pushNamedAndRemoveUntil(loginRoute, (_) => false);
                    } catch (e) {
                      devtools.log("Error signing out: $e");
                    }
                  }
                  break;

                case MenuAction.changePassword:
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: user.email!);
                    showPasswordResetDialog(context);
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.changePassword,
                  child: Text("Change Password",
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                ),
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text("Logout",
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF271A23), // Dark pink / magenta at the top
              const Color(0xFF752145), // Lighter pink/magenta transition
              Colors.black, // Black at the bottom for a smooth fade
            ], // Gradient from dark pink/magenta to black
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLoadingBoxOffice)
                const CircularProgressIndicator(
                    color: Colors.white) // White loading indicator
              else
                if (errorBoxOffice.isNotEmpty)
                  Text(errorBoxOffice,
                      style: const TextStyle(color: Colors.red, fontSize: 16))
                else
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: boxOfficeMovies.length,
                      itemBuilder: (context, index) {
                        final movie = boxOfficeMovies[index];
                        return BoxOfficeCard(movie: movie);
                      },
                    ),
                  ),
              const SizedBox(height: 20),
              const Text(
                "Trending Movies",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text color
                ),
              ),
              const SizedBox(height: 10),
              if (isLoadingTrending)
                const CircularProgressIndicator(
                    color: Colors.white) // White loading indicator
              else
                if (errorTrending.isNotEmpty)
                  Text(errorTrending,
                      style: const TextStyle(color: Colors.red, fontSize: 16))
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: trendingMovies.length,
                      itemBuilder: (context, index) {
                        final movie = trendingMovies[index];
                        return MovieCard(movie: movie);
                      },
                    ),
                  ),
              const SizedBox(height: 20),
              const Text(
                "Top 250 Movies",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text color
                ),
              ),
              const SizedBox(height: 12),
              if (isLoadingTop)
                const CircularProgressIndicator(
                    color: Colors.white) // White loading indicator
              else
                if (errorTop.isNotEmpty)
                  Text(errorTop,
                      style: const TextStyle(color: Colors.red, fontSize: 12))
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topMovies.length,
                      itemBuilder: (context, index) {
                        final movie = topMovies[index];
                        return MovieCard(movie: movie);
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
  class BoxOfficeCard extends StatelessWidget {
  final Map<String, dynamic> movie;

  const BoxOfficeCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    print("Box Office Data: $movie");

    String title = movie["primaryTitle"]?.toString() ?? "Unknown Title";
    String? imageUrl;
    String? imdbId = movie["id"]?.toString(); // Extract IMDB ID

    if (movie["primaryImage"] is String) {
      imageUrl = movie["primaryImage"];
    }

    return GestureDetector(
      onTap: () {
        if (imdbId != null && imdbId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(imdbID: imdbId),
            ),
          );
        }
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 3,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 180,
                height: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    width: 180,
                    color: Colors.grey[400],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  );
                },
              )
                  : Container(
                height: 250,
                width: 180,
                color: Colors.grey[400],
                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Movie Card Widget

class MovieCard extends StatelessWidget {
  final Map<String, dynamic> movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    print("Movie Data: $movie");

    String title = movie["primaryTitle"]?.toString() ?? "Unknown Title";
    String? imageUrl;
    String? imdbId = movie["id"]?.toString(); // Extract IMDB ID

    if (movie["primaryImage"] is String) {
      imageUrl = movie["primaryImage"];
    }

    return GestureDetector(
      onTap: () {
        if (imdbId != null && imdbId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(imdbID: imdbId),
            ),
          );
        }
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 150,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    width: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  );
                },
              )
                  : Container(
                height: 220,
                width: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              ),
            ),
            Container(
              width: 150,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout"),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}

void showPasswordResetDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Password Reset"),
        content: const Text(
            "A password reset email has been sent to your registered email address. Please check your inbox."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
