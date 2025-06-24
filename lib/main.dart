import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:registeration/constants/routes.dart';
import 'package:registeration/firebase_options.dart';
import 'package:registeration/views/LoginView.dart';
import 'package:registeration/views/MovieDetailCommon.dart';
import 'package:registeration/views/MovieReviewsPage.dart';
import 'package:registeration/views/MyReviewsPage.dart';
import 'package:registeration/views/ProfileView.dart';
import 'package:registeration/views/RegisterationView.dart';
import 'dart:developer' as devtools show log;
import 'package:http/http.dart' as http;
import 'package:registeration/views/SearchScreen.dart';
import 'dart:convert';

import 'package:registeration/views/VerifyEmailView.dart';
import 'package:registeration/views/MyWishlistPage.dart';

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
        profileRoute: (context) => const ProfileView(),
        wishlistRoute: (context) => const MyWishlistPage() ,
        // reviewsRoute:(context)=>const MovieReviewsPage();
        myReviewsRoute: (context) => const MyReviewsPage(),



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
    // fetchTrendingMovies();
    fetchTrendingFromFirestore();
    fetchTopMovies();
  }
  Future<void> fetchTrendingFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('movies_trending').get();
      final moviesList = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        trendingMovies = List<Map<String, dynamic>>.from(moviesList);
        isLoadingTrending = false;
        errorTrending = trendingMovies.isEmpty ? "No trending movies found." : "";
      });

      // Optionally cache IDs if you still use them
      movieIdCache["trending"] = trendingMovies
          .where((movie) => movie.containsKey("id"))
          .map<String>((movie) => movie["id"].toString())
          .toList();

      print("🔥 Loaded ${trendingMovies.length} trending movies from Firebase");
    } catch (e) {
      setState(() {
        isLoadingTrending = false;
        errorTrending = "Error loading trending movies.";
      });
      print("Error fetching trending from Firestore: $e");
    }
  }

  Future<void> fetchBoxOfficeMovies() async {
    const String url = "https://imdb236.p.rapidapi.com/api/imdb/most-popular-tv";
    await fetchMovies(url, category: "boxOffice");
  }

  Future<void> fetchTrendingMovies() async {
    const String url = "https://imdb236.p.rapidapi.com/api/imdb/india/top-rated-indian-movies";
    await fetchMovies(url, category: "trending");
  }

  Future<void> fetchTopMovies() async {
    const String url = "https://imdb236.p.rapidapi.com/api/imdb/most-popular-movies";
    await fetchMovies(url, category: "top");
  }


  Map<String, List<String>> movieIdCache = {}; // Cache for IMDb IDs per category
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
          final moviesList = List<Map<String, dynamic>>.from(decodedData);

          if (category == "boxOffice") {
            setState(() {
              boxOfficeMovies = moviesList;
              isLoadingBoxOffice = false;
              errorBoxOffice = boxOfficeMovies.isEmpty ? "No box office movies found." : "";
            });
          } else if (category == "top") {
            setState(() {
              topMovies = moviesList;
              isLoadingTop = false;
              errorTop = topMovies.isEmpty ? "No top movies found." : "";
            });
          }

          movieIdCache[category] = moviesList
              .where((movie) => movie.containsKey("id"))
              .map<String>((movie) => movie["id"].toString())
              .toList();
        }

        else if (decodedData is Map && decodedData.containsKey("results")) {
          final moviesList = List<Map<String, dynamic>>.from(decodedData["results"]);

          if (category == "boxOffice") {
            setState(() {
              boxOfficeMovies = moviesList;
              isLoadingBoxOffice = false;
              errorBoxOffice = boxOfficeMovies.isEmpty ? "No box office movies found." : "";
            });
          } else if (category == "top") {
            setState(() {
              topMovies = moviesList;
              isLoadingTop = false;
              errorTop = topMovies.isEmpty ? "No top movies found." : "";
            });
          }

          movieIdCache[category] = moviesList
              .where((movie) => movie.containsKey("id"))
              .map<String>((movie) => movie["id"].toString())
              .toList();
        }
      }
    } catch (e) {
      if (category == "boxOffice") {
        setState(() {
          isLoadingBoxOffice = false;
          errorBoxOffice = "Error loading box office movies.";
        });
      } else if (category == "top") {
        setState(() {
          isLoadingTop = false;
          errorTop = "Error loading top movies.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF60063F),
        title: const Text(
          "Explore & Express",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            final data = doc.data();
            final profilePic = data?['profilePic'] ??
                'https://www.gravatar.com/avatar/${user.uid}?d=identicon';
            final TextEditingController usernameController =
            TextEditingController(text: data?['username'] ?? '');

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(
                      top: 20, left: 16, right: 16, bottom: 40), // for keyboard space
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(profilePic),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final newUsername = usernameController.text.trim();
                            if (newUsername.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({'username': newUsername});

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Username updated")),
                              );
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text("Save Username"),
                        ),
                        const Divider(height: 25),
                        ListTile(
                          leading: const Icon(Icons.reviews),
                          title: const Text("My Reviews"),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/myreviews');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.favorite),
                          title: const Text("My Wishlist"),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/wishlist');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_reset),
                          title: const Text("Change Password"),
                          onTap: () async {
                            Navigator.pop(context);
                            if (user.email != null) {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: user.email!);
                              showPasswordResetDialog(context);
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text("Logout"),
                          onTap: () async {
                            final shouldLogout = await showLogOutDialog(context);
                            if (shouldLogout) {
                              try {
                                await FirebaseAuth.instance.signOut();
                                Navigator.of(context)
                                    .pushNamedAndRemoveUntil(loginRoute, (_) => false);
                              } catch (e) {
                                devtools.log("Error signing out: $e");
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          color: Colors.white,
        ),


        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyWishlistPage()),
                );
              }
            },
            color: Colors.white,
          ),
        ],
      ),


      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF271A23),
              const Color(0xFF752145),
              Colors.black,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLoadingBoxOffice)
                const CircularProgressIndicator(color: Colors.white)
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
                      return BoxOfficeCard(movie: movie,movieIdCache: movieIdCache,);
                    },
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                "Trending Movies",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              if (isLoadingTrending)
                const CircularProgressIndicator(color: Colors.white)
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              if (isLoadingTop)
                const CircularProgressIndicator(color: Colors.white)
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

class BoxOfficeCard extends StatelessWidget {
  final Map<String, List<String>> movieIdCache; // ✅ Accept as a parameter
  final Map<String, dynamic> movie;

  const BoxOfficeCard({
    super.key,
    required this.movie,
    required this.movieIdCache, // ✅ Constructor requires it
  });

  @override
  Widget build(BuildContext context) {
    print("Box Office Data: $movie");

    String title = movie["primaryTitle"]?.toString() ?? "Unknown Title";
    String? imageUrl;
    String? imdbId = movie["id"]?.toString();

    if (movie["primaryImage"] is String) {
      imageUrl = movie["primaryImage"];
    }

    return GestureDetector(
      onTap: () {
        String category = "boxOffice";
        List<String> imdbIds = movieIdCache[category] ?? [];
        if (imdbIds.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailPageView(
                movieIds: imdbIds,
                initialIndex: 0,
              ),
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

class MovieCard extends StatelessWidget {
  final Map<String, dynamic> movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    print("Movie Data: $movie");

    String title = movie["primaryTitle"]?.toString() ?? "Unknown Title";
    String? imageUrl;
    String? imdbId = movie["id"]?.toString();

    if (movie["primaryImage"] is String) {
      imageUrl = movie["primaryImage"];
    }

    return GestureDetector(
      onTap: () {
        if (imdbId != null && imdbId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailPageView(
                movieIds: [imdbId],
                initialIndex: 0,
              ),
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
        content: const Text("A password reset email has been sent to your registered email address. Please check your inbox."),
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