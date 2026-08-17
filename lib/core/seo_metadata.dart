import '../models/movie_model.dart';
import 'seo_metadata_stub.dart'
    if (dart.library.js_interop) 'seo_metadata_web.dart' as implementation;

void updateMovieSeoMetadata(Movie movie) {
  implementation.updateMovieSeoMetadata(
    id: movie.id,
    title: movie.title,
    description: movie.description,
    imageUrl: movie.imageUrl,
    releaseDate: movie.releaseDate,
    rating: movie.rating,
    ratingCount: movie.ratingCount,
  );
}

void resetSeoMetadata() => implementation.resetSeoMetadata();
