import 'dart:io';

import 'package:flix_app/models/movie_note.dart';
import 'package:flix_app/viewmodels/movie_note_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late MovieNoteViewModel notes;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('flix_notes_test_');
    Hive.init(tempDirectory.path);
    box = await Hive.openBox<dynamic>('movie_notes');
    notes = MovieNoteViewModel(box: box);
  });

  tearDown(() async {
    await box.close();
    await tempDirectory.delete(recursive: true);
  });

  test('ghi chú Hive hỗ trợ tạo, đọc, cập nhật và xóa', () async {
    expect(notes.noteFor('101'), isNull);

    await notes.saveNote(
      movieId: '101',
      movieTitle: 'Dune',
      content: '  Xem lại phần âm thanh.  ',
    );
    final created = notes.noteFor('101');
    expect(created?.content, 'Xem lại phần âm thanh.');
    expect(box.containsKey('101'), isTrue);

    await notes.saveNote(
      movieId: '101',
      movieTitle: 'Dune',
      content: 'Chú ý cả phần quay phim.',
    );
    final updated = notes.noteFor('101');
    expect(updated?.content, 'Chú ý cả phần quay phim.');
    expect(updated?.createdAt, created?.createdAt);
    expect(updated!.updatedAt.isBefore(created!.updatedAt), isFalse);

    await notes.deleteNote('101');
    expect(notes.noteFor('101'), isNull);
    expect(box.containsKey('101'), isFalse);

    await box.put('broken', {'content': 42});
    expect(notes.noteFor('broken'), isNull);

    expect(
      () => notes.saveNote(
        movieId: '101',
        movieTitle: 'Dune',
        content: '   ',
      ),
      throwsArgumentError,
    );
    expect(
      () => notes.saveNote(
        movieId: '101',
        movieTitle: 'Dune',
        content: 'a' * (MovieNote.maxLength + 1),
      ),
      throwsArgumentError,
    );
  });
}
