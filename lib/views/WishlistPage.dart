import 'package:flutter/material.dart';
import 'package:registeration/views/MovieDetailCommon.dart';
 import 'package:shared_preferences/shared_preferences.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<String> wishlist = [];

  @override
  void initState() {
    super.initState();
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      wishlist = prefs.getStringList('wishlist') ?? [];
    });
  }

  Future<void> removeFromWishlist(String imdbId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      wishlist.remove(imdbId);
    });
    await prefs.setStringList('wishlist', wishlist);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from Wishlist"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wishlist")),
      body: wishlist.isEmpty
          ? const Center(child: Text("Your wishlist is empty."))
          : ListView.builder(
        itemCount: wishlist.length,
        itemBuilder: (context, index) {
          final imdbId = wishlist[index];
          return ListTile(
            title: Text("Movie ID: $imdbId"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => removeFromWishlist(imdbId),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(imdbID: imdbId, isFromRapidApi: false),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
