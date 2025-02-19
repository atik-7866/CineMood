import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:registeration/views/MovieDetailCommon.dart';

class MovieDetailPageView extends StatefulWidget {
  final List<String> movieIds;
  final int initialIndex;

  const MovieDetailPageView({
    super.key,
    required this.movieIds,
    this.initialIndex = 0,
  });

  @override
  _MovieDetailPageViewState createState() => _MovieDetailPageViewState();
}

class _MovieDetailPageViewState extends State<MovieDetailPageView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.movieIds.length,
        itemBuilder: (context, index) {
          return MovieDetailScreen(
            imdbID: widget.movieIds[index],
          );
        },
      ),
    );
  }
}