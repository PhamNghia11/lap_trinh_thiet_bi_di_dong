class MovieNote {
  const MovieNote({
    required this.movieId,
    required this.movieTitle,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  static const maxLength = 600;

  final String movieId;
  final String movieTitle;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object> toMap() => {
        'movieId': movieId,
        'movieTitle': movieTitle,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MovieNote.fromMap(Map<dynamic, dynamic> map) {
    final movieId = map['movieId'] as String?;
    final movieTitle = map['movieTitle'] as String?;
    final content = map['content'] as String?;
    final createdAt = DateTime.tryParse(map['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(map['updatedAt'] as String? ?? '');
    if (movieId == null ||
        movieTitle == null ||
        content == null ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Dữ liệu ghi chú không hợp lệ.');
    }
    return MovieNote(
      movieId: movieId,
      movieTitle: movieTitle,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
