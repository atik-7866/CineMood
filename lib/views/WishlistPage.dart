import 'package:flutter/material.dart';
import 'MovieDetailCommon.dart';

class WishlistPage extends StatefulWidget {
  static List<String> wishlist = []; // Global wishlist

  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wishlist")),
      body: WishlistPage.wishlist.isEmpty
          ? const Center(child: Text("Your wishlist is empty."))
          : ListView.builder(
        itemCount: WishlistPage.wishlist.length,
        itemBuilder: (context, index) {
          final imdbId = WishlistPage.wishlist[index];
          return ListTile(
            title: Text("Movie ID: $imdbId"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), // Dustbin icon
              onPressed: () {
                setState(() {
                  WishlistPage.wishlist.remove(imdbId); // Remove from wishlist
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Removed from Wishlist")),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(imdbID: imdbId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
