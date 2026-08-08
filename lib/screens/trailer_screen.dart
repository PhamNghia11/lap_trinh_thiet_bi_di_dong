// lib/screens/trailer_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/flix_network_image.dart';

class TrailerScreen extends StatelessWidget {
  final Movie? movie;

  const TrailerScreen({super.key, this.movie});

  @override
  Widget build(BuildContext context) {
    final targetMovie = movie ?? mockMovies.first;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Trailer ${targetMovie.title}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: AppTheme.inputBg,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlixNetworkImage(
                  targetMovie.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                Container(color: Colors.black38),
                IconButton(
                  iconSize: 64,
                  icon: const Icon(Icons.play_circle_fill,
                      color: AppTheme.primaryRed),
                  onPressed: () {},
                ),
                const Positioned(
                  bottom: 12,
                  left: 12,
                  child: Text('01:45 / 02:30',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
