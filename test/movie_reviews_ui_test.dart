import 'package:flix_app/models/movie_model.dart';
import 'package:flix_app/routes/app_routes.dart';
import 'package:flix_app/screens/movie_detail_screen.dart';
import 'package:flix_app/screens/movie_reviews_screen.dart';
import 'package:flix_app/viewmodels/movie_note_view_model.dart';
import 'package:flix_app/widgets/user_review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

UserReview review(String name, String comment) => UserReview(
      userName: name,
      userAvatar: '',
      rating: 5,
      date: '2026-08-11',
      comment: comment,
    );

void main() {
  testWidgets('bình luận dài có thể đọc thêm và thu gọn', (tester) async {
    final longComment = List.filled(80, 'nội dung').join(' ');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UserReviewCard(review: review('TMDB', longComment)),
      ),
    ));

    expect(find.text('Đọc thêm'), findsOneWidget);
    await tester.tap(find.text('Đọc thêm'));
    await tester.pump();
    expect(find.text('Thu gọn'), findsOneWidget);
  });

  testWidgets('chi tiết phim chỉ hiện ba đánh giá preview', (tester) async {
    final reviews = List.generate(
      4,
      (index) => review('Người dùng $index', 'Bình luận ngắn $index'),
    );
    final movie = Movie(
      id: 'local-review-test',
      title: 'Phim kiểm thử',
      genres: const [],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Nội dung kiểm thử',
      imageUrl: '',
      reviews: reviews,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MovieNoteViewModel(),
        child: MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: MovieDetailScreen(movie: movie),
        ),
      ),
    );
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -1700),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UserReviewCard), findsNWidgets(3));
    expect(find.text('Xem tất cả 4 đánh giá'), findsOneWidget);

    await tester.tap(find.text('Xem tất cả 4 đánh giá'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieReviewsScreen), findsOneWidget);
  });

  testWidgets('trang tất cả đánh giá lọc được nguồn TMDB', (tester) async {
    final movie = Movie(
      id: 'filter-test',
      title: 'Phim kiểm thử',
      genres: const [],
      year: 2026,
      rating: 8,
      duration: '120 phút',
      description: 'Nội dung kiểm thử',
      imageUrl: '',
      reviews: [
        review('Người dùng FLIX', 'Bình luận trong ứng dụng'),
        review('MovieGuys (TMDB)', 'Bình luận từ TMDB'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: MovieReviewsScreen(movie: movie)),
    );

    await tester.tap(find.text('Mọi nguồn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TMDB').last);
    await tester.pumpAndSettle();

    expect(find.text('MovieGuys (TMDB)'), findsOneWidget);
    expect(find.text('Người dùng FLIX'), findsNothing);
  });
}
