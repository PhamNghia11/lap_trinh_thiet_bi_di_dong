import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/trailer_screen.dart';
import 'package:flix_app/widgets/embedded_youtube_player.dart';

void main() {
  testWidgets('trailer route gốc luôn có thể quay về trang chủ',
      (tester) async {
    const movie = Movie(
      id: 'local-movie',
      title: 'Phim kiểm thử',
      genres: ['Hành động'],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Mô tả kiểm thử',
      imageUrl: '',
      trailerKey: 'test-video',
      videos: [
        MovieVideo(
          key: 'test-video',
          name: 'Trailer chính thức',
          type: 'Trailer',
        ),
        MovieVideo(
          key: 'behind-scenes',
          name: 'Hậu trường',
          type: 'Clip',
        ),
        MovieVideo(key: 'teaser-1', name: 'Teaser 1', type: 'Teaser'),
        MovieVideo(key: 'teaser-2', name: 'Teaser 2', type: 'Teaser'),
        MovieVideo(key: 'clip-2', name: 'Clip 2', type: 'Clip'),
        MovieVideo(key: 'clip-3', name: 'Clip 3', type: 'Clip'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const TrailerScreen(movie: movie),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.home) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Trang chủ kiểm thử')),
            );
          }
          return null;
        },
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Quay lại'), findsOneWidget);
    expect(find.text('Video liên quan'), findsOneWidget);
    expect(find.text('Trailer chính thức'), findsOneWidget);
    expect(find.text('Hậu trường'), findsOneWidget);
    expect(find.text('Xem tất cả'), findsOneWidget);
    expect(find.text('Clip 3'), findsNothing);
    expect(find.text('Mở trên YouTube'), findsOneWidget);
    final player = tester.getSize(find.byType(EmbeddedYoutubePlayer));
    expect(player.width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio);
    expect(player.height, greaterThanOrEqualTo(240));
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Trang chủ kiểm thử'), findsOneWidget);
  });

  testWidgets('lọc và chọn video từ danh sách đầy đủ', (tester) async {
    const movie = Movie(
      id: 'local-movie',
      title: 'Phim kiểm thử',
      genres: ['Hành Động'],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Mô tả kiểm thử',
      imageUrl: '',
      trailerKey: 'main',
      videos: [
        MovieVideo(key: 'main', name: 'Trailer chính', type: 'Trailer'),
        MovieVideo(key: 'teaser-1', name: 'Teaser 1', type: 'Teaser'),
        MovieVideo(key: 'teaser-2', name: 'Teaser 2', type: 'Teaser'),
        MovieVideo(key: 'clip-1', name: 'Clip 1', type: 'Clip'),
        MovieVideo(key: 'clip-2', name: 'Clip 2', type: 'Clip'),
        MovieVideo(key: 'clip-3', name: 'Clip 3', type: 'Clip'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: TrailerScreen(movie: movie)),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Xem tất cả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Tất cả video'), findsOneWidget);

    final clipFilter = find.byWidgetPredicate(
      (widget) =>
          widget is ChoiceChip &&
          widget.label is Text &&
          (widget.label as Text).data == 'Clip',
    );
    await tester.ensureVisible(clipFilter);
    await tester.tap(clipFilter);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Trailer chính')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Clip 3')),
      findsOneWidget,
    );

    await tester.tap(find.text('Clip 3'));
    await tester.pumpAndSettle();
    expect(find.text('Tất cả video'), findsNothing);
    expect(find.text('Clip 3'), findsOneWidget);
    expect(find.byType(EmbeddedYoutubePlayer), findsOneWidget);
  });
}
