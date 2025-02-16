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
      "X-RapidAPI-Key": "222cdddb17msh20db10d9fbd80b0p19f20ajsnc7e766c3fb2d",
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          setState(() {
            if (category == "boxOffice") {
              boxOfficeMovies = List<Map<String, dynamic>>.from(decodedData);
              isLoadingBoxOffice = false;
              errorBoxOffice = boxOfficeMovies.isEmpty ? "No box office movies found." : "";
            } else if (category == "trending") {
              trendingMovies = List<Map<String, dynamic>>.from(decodedData);
              isLoadingTrending = false;
              errorTrending = trendingMovies.isEmpty ? "No trending movies found." : "";
            } else {
              topMovies = List<Map<String, dynamic>>.from(decodedData);
              isLoadingTop = false;
              errorTop = topMovies.isEmpty ? "No top movies found." : "";
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        if (category == "boxOffice") {
          isLoadingBoxOffice = false;
          errorBoxOffice = "Error fetching box office movies: $e";
        } else if (category == "trending") {
          isLoadingTrending = false;
          errorTrending = "Error fetching trending movies: $e";
        } else {
          isLoadingTop = false;
          errorTop = "Error fetching top movies: $e";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Main UI",
          style: TextStyle(fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to SearchScreen when clicked
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),

          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(loginRoute, (_) => false);
                  }
                  break;
                case MenuAction.changePassword:
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                    showPasswordResetDialog(context);
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.changePassword,
                  child: Text("Change Password", style: TextStyle(fontSize: 16)),
                ),
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text("Logout", style: TextStyle(fontSize: 16)),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLoadingBoxOffice)
                const CircularProgressIndicator()
              else if (errorBoxOffice.isNotEmpty)
                Text(errorBoxOffice, style: const TextStyle(color: Colors.red, fontSize: 16))
              else
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: boxOfficeMovies.length,
                    itemBuilder: (context, index) {
                      final movie = boxOfficeMovies[index];
                      return BoxOfficeMovieCard(movie: movie);
                    },
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                "Trending Movies",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (isLoadingTrending)
                const CircularProgressIndicator()
              else if (errorTrending.isNotEmpty)
                Text(errorTrending, style: const TextStyle(color: Colors.red, fontSize: 16))
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isLoadingTop)
                const CircularProgressIndicator()
              else if (errorTop.isNotEmpty)
                Text(errorTop, style: const TextStyle(color: Colors.red, fontSize: 12))
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



class BoxOfficeMovieCard extends StatelessWidget {
  final Map<String, dynamic> movie;

  const BoxOfficeMovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    print("Box Office Movie Data: $movie");

    String title = movie["primaryTitle"]?.toString() ?? "Unknown Title";
    String? imageUrl = movie["primaryImage"] is String ? movie["primaryImage"] : null;
    String? imdbId = movie["id"]?.toString();

    // Get Box Office Collection (assuming it's stored as a number in "boxOffice")
    int? boxOffice = movie["boxOffice"] is int ? movie["boxOffice"] : null;
    String boxOfficeDisplay = boxOffice != null ? "\$${boxOffice.toString()}" : "";
    String approxBoxOffice = boxOffice != null ? _formatApproximate(boxOffice) : "";

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
            if (boxOffice != null)
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boxOfficeDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      approxBoxOffice,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
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

  /// Converts large numbers to an approximate readable format
  String _formatApproximate(int number) {
    if (number >= 1e9) {
      return "(${(number / 1e9).toStringAsFixed(1)}B)";
    } else if (number >= 1e6) {
      return "(${(number / 1e6).toStringAsFixed(1)}M)";
    } else if (number >= 1e3) {
      return "(${(number / 1e3).toStringAsFixed(1)}K)";
    }
    return "";
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
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Log Out"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("Cancel"),
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
