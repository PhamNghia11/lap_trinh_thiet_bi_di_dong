import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../theme/app_theme.dart';
import '../core/media_url.dart';
import 'flix_network_image.dart';

class UserReviewCard extends StatefulWidget {
  final UserReview review;

  const UserReviewCard({super.key, required this.review});

  @override
  State<UserReviewCard> createState() => _UserReviewCardState();
}

class _UserReviewCardState extends State<UserReviewCard> {
  static const _collapsedLines = 5;
  static const _longReviewCharacters = 260;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final isLong = review.comment.trim().length > _longReviewCharacters;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.inputBg,
                backgroundImage: review.userAvatar.isEmpty
                    ? null
                    : NetworkImage(resolveImageUrl(review.userAvatar)),
                child: review.userAvatar.isEmpty
                    ? const Icon(Icons.person,
                        color: AppTheme.textMuted, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(review.date, style: AppTheme.smallText),
                  ],
                ),
              ),
              if (review.rating > 0)
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppTheme.accentGold, size: 16),
                    const SizedBox(width: 2),
                    Text('${review.rating}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: AppTheme.bodyText,
            maxLines: isLong && !_expanded ? _collapsedLines : null,
            overflow: isLong && !_expanded
                ? TextOverflow.ellipsis
                : TextOverflow.clip,
          ),
          if (isLong)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(top: 6, right: 8)),
                child: Text(_expanded ? 'Thu gọn' : 'Đọc thêm',
                    style: const TextStyle(color: AppTheme.primaryRed)),
              ),
            ),
          if (review.imageUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: FlixNetworkImage(review.imageUrl!,
                  width: double.infinity, height: 180),
            ),
          ],
        ],
      ),
    );
  }
}
