import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/movie_note.dart';

class MovieNoteViewModel extends ChangeNotifier {
  MovieNoteViewModel({Box<dynamic>? box}) : _box = box;

  static final MovieNoteViewModel instance = MovieNoteViewModel();
  static const _boxName = 'flix_movie_notes_v1';

  Box<dynamic>? _box;

  bool get isReady => _box?.isOpen == true;

  Future<void> initialize() async {
    if (isReady) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    notifyListeners();
  }

  MovieNote? noteFor(String movieId) {
    final value = _box?.get(movieId);
    if (value is! Map) return null;
    try {
      return MovieNote.fromMap(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNote({
    required String movieId,
    required String movieTitle,
    required String content,
  }) async {
    final box = _requireBox();
    final normalized = content.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
          content, 'content', 'Ghi chú không được trống.');
    }
    if (normalized.length > MovieNote.maxLength) {
      throw ArgumentError.value(
        content,
        'content',
        'Ghi chú không được vượt quá ${MovieNote.maxLength} ký tự.',
      );
    }

    final existing = noteFor(movieId);
    final now = DateTime.now();
    final note = MovieNote(
      movieId: movieId,
      movieTitle: movieTitle,
      content: normalized,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await box.put(movieId, note.toMap());
    notifyListeners();
  }

  Future<void> deleteNote(String movieId) async {
    final box = _requireBox();
    await box.delete(movieId);
    notifyListeners();
  }

  Box<dynamic> _requireBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('Kho ghi chú chưa sẵn sàng.');
    }
    return box;
  }
}
