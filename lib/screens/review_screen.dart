// lib/screens/review_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/movie_model.dart';
import '../data/mock_data.dart';
import '../widgets/flix_network_image.dart';
import '../data/user_data_repository.dart';
import '../core/app_session.dart';
import '../routes/app_routes.dart';

class ReviewScreen extends StatefulWidget {
  final Movie? movie;

  const ReviewScreen({
    super.key,
    this.movie,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Movie _targetMovie;
  int _rating = 0; // 0: chưa chọn, 1-5: số sao đã chọn
  bool _hasSpoiler = false;
  bool _hasAttachedImage = false;
  bool _isSubmitting = false;

  final TextEditingController _reviewController = TextEditingController();
  final Set<String> _selectedQuickTags = {};

  final List<String> _quickTags = [
    'Kịch bản hay',
    'Diễn xuất tốt',
    'Kỹ xảo đỉnh',
    'Âm nhạc hay',
    'Hơi dài',
    'Cốt truyện lôi cuốn',
  ];

  @override
  void initState() {
    super.initState();
    _targetMovie = widget.movie ?? mockMovies.first;
    _reviewController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  /// Trả về mô tả cảm xúc tương ứng với số sao đã chọn
  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Rất tệ 😞';
      case 2:
        return 'Không hay 😐';
      case 3:
        return 'Bình thường 🙂';
      case 4:
        return 'Hay 😃';
      case 5:
        return 'Xuất sắc! 🔥';
      default:
        return 'Chạm để chọn đánh giá sao';
    }
  }

  /// Toggle chọn Quick Tag
  void _toggleQuickTag(String tag) {
    setState(() {
      if (_selectedQuickTags.contains(tag)) {
        _selectedQuickTags.remove(tag);
      } else {
        _selectedQuickTags.add(tag);
      }
    });
  }

  /// Xử lý gửi đánh giá với loading animation & Success Dialog
  void _submitReview() async {
    if (_rating == 0) return;

    if (!AppSession.instance.isAuthenticated) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final tags = _selectedQuickTags.isEmpty ? '' : '\n${_selectedQuickTags.join(', ')}';
      await UserDataRepository().saveReview(
        _targetMovie.id,
        _rating,
        '${_reviewController.text.trim()}$tags'.trim(),
        _hasSpoiler,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cảm ơn bạn đã đánh giá!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đánh giá của bạn đã được đóng góp cho cộng đồng người xem FLIX.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyText,
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pop(context); // Tắt dialog
      Navigator.pop(context); // Quay lại màn hình trước
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _targetMovie;
    final textLength = _reviewController.text.length;
    final isSubmitEnabled = _rating > 0 && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Viết Đánh Giá Phim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Card Thông Tin Phim Đang Đánh Giá ──────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: FlixNetworkImage(
                      movie.imageUrl,
                      width: 55,
                      height: 75,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${movie.year} • ${movie.genreText}',
                          style: AppTheme.smallText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.accentGold, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              movie.ratingText,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Phần Chấm Sao Chuyển Động & Nhãn Cảm Xúc ────────────
            const Text('Đánh giá của bạn', style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= _rating;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = starIndex;
                          });
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isSelected ? 1.2 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isSelected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isSelected
                                  ? AppTheme.accentGold
                                  : AppTheme.textMuted,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Nhãn cảm xúc + Số điểm hiển thị
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getRatingLabel(_rating),
                        style: TextStyle(
                          color: _rating > 0
                              ? AppTheme.accentGold
                              : AppTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_rating > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '($_rating.0 / 5)',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Phần Chip Cảm Nhận Nhanh (Quick Tags) ────────────────
            const Text('Cảm nhận nhanh', style: AppTheme.headingSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTags.map((tag) {
                final selected = _selectedQuickTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  selectedColor: AppTheme.primaryRed,
                  backgroundColor: AppTheme.cardBg,
                  side: BorderSide(
                      color: selected ? AppTheme.primaryRed : Colors.white12),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textLight,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) => _toggleQuickTag(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ─── Phần Ô Nhập Viết Đánh Giá Nâng Cấp ────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nội dung đánh giá', style: AppTheme.headingSmall),
                Text(
                  '$textLength / 500',
                  style: TextStyle(
                    color: textLength > 450
                        ? AppTheme.primaryRed
                        : AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 500,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Chia sẻ cảm nghĩ của bạn về diễn xuất, kịch bản, âm nhạc...',
                hintStyle:
                    const TextStyle(color: Color(0x80E9BCB6), fontSize: 13),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryRed, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Nút đính kèm ảnh placeholder + Checkbox Spoiler
            Row(
              children: [
                OutlinedButton.icon(
                  style: AppTheme.outlinedButtonStyle(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8)),
                  onPressed: () {
                    setState(() {
                      _hasAttachedImage = !_hasAttachedImage;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_hasAttachedImage
                            ? 'Đã đính kèm ảnh minh họa'
                            : 'Đã hủy đính kèm ảnh'),
                      ),
                    );
                  },
                  icon: Icon(
                    _hasAttachedImage
                        ? Icons.image_rounded
                        : Icons.add_a_photo_outlined,
                    color: _hasAttachedImage
                        ? AppTheme.accentGold
                        : AppTheme.textMuted,
                    size: 18,
                  ),
                  label: Text(
                    _hasAttachedImage ? 'Đã chọn ảnh' : 'Đính kèm ảnh',
                    style: TextStyle(
                        color: _hasAttachedImage
                            ? AppTheme.accentGold
                            : AppTheme.textMuted,
                        fontSize: 12),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Checkbox(
                      value: _hasSpoiler,
                      activeColor: AppTheme.primaryRed,
                      onChanged: (val) {
                        setState(() {
                          _hasSpoiler = val ?? false;
                        });
                      },
                    ),
                    const Text('Tiết lộ nội dung (Spoiler)',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── Nút Gửi Đánh Giá với Trạng thái Disabled & Loading ─────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSubmitEnabled ? AppTheme.primaryRed : Colors.white12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  elevation: isSubmitEnabled ? 6 : 0,
                ),
                onPressed: isSubmitEnabled ? _submitReview : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Gửi Đánh Giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isSubmitEnabled ? Colors.white : Colors.white38,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 36),

            // ─── Đánh Giá Từ Người Dùng Khác (Review Mẫu) ───────────────
            const Text('Đánh giá từ người xem khác',
                style: AppTheme.headingSmall),
            const SizedBox(height: 12),
            Column(
              children: movie.reviews.map((rev) {
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
                            radius: 16,
                            backgroundImage: NetworkImage(rev.userAvatar),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rev.userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.accentGold, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                '${rev.rating}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(rev.comment, style: AppTheme.bodyText),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
