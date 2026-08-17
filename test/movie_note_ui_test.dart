import 'package:flix_app/models/movie_note.dart';
import 'package:flix_app/theme/app_theme.dart';
import 'package:flix_app/viewmodels/movie_note_view_model.dart';
import 'package:flix_app/widgets/movie_note_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _InMemoryMovieNotes extends MovieNoteViewModel {
  MovieNote? _note;

  @override
  bool get isReady => true;

  @override
  MovieNote? noteFor(String movieId) =>
      _note?.movieId == movieId ? _note : null;

  @override
  Future<void> saveNote({
    required String movieId,
    required String movieTitle,
    required String content,
  }) async {
    final now = DateTime.now();
    _note = MovieNote(
      movieId: movieId,
      movieTitle: movieTitle,
      content: content.trim(),
      createdAt: _note?.createdAt ?? now,
      updatedAt: now,
    );
    notifyListeners();
  }

  @override
  Future<void> deleteNote(String movieId) async {
    _note = null;
    notifyListeners();
  }
}

void main() {
  late _InMemoryMovieNotes notes;

  setUp(() => notes = _InMemoryMovieNotes());

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    bool visible = true,
  }) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty == visible) return;
    }
    fail('Không đạt trạng thái giao diện mong đợi: $finder');
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Mở ghi chú'));
    await waitFor(tester, find.byKey(const Key('movie-note-field')));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('bottom sheet lưu, mở lại và xóa ghi chú thật', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MovieNoteViewModel>.value(
        value: notes,
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<MovieNoteSheetResult>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const MovieNoteSheet(
                      movieId: '550',
                      movieTitle: 'Fight Club',
                    ),
                  ),
                  child: const Text('Mở ghi chú'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await openSheet(tester);
    expect(find.textContaining('Chỉ lưu trên thiết bị này'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('movie-note-field')),
      'Xem lại đoạn kết và cách dựng phim.',
    );
    final saveButton = find.byKey(const Key('movie-note-save'));
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await waitFor(
      tester,
      find.byKey(const Key('movie-note-field')),
      visible: false,
    );
    expect(
        notes.noteFor('550')?.content, 'Xem lại đoạn kết và cách dựng phim.');

    await openSheet(tester);
    expect(find.text('Xem lại đoạn kết và cách dựng phim.'), findsOneWidget);
    final deleteButton = find.byKey(const Key('movie-note-delete'));
    await tester.ensureVisible(deleteButton);
    await tester.pump();
    await tester.tap(deleteButton);
    await waitFor(tester, find.byType(AlertDialog));
    await tester.tap(find.text('Xóa').last);
    await waitFor(
      tester,
      find.byKey(const Key('movie-note-field')),
      visible: false,
    );
    expect(notes.noteFor('550'), isNull);
  });
}
