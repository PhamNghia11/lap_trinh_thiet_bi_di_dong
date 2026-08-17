import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie_note.dart';
import '../theme/app_theme.dart';
import '../viewmodels/movie_note_view_model.dart';

enum MovieNoteSheetResult { saved, deleted }

class MovieNoteSheet extends StatefulWidget {
  const MovieNoteSheet({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  final String movieId;
  final String movieTitle;

  @override
  State<MovieNoteSheet> createState() => _MovieNoteSheetState();
}

class _MovieNoteSheetState extends State<MovieNoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  MovieNote? _initialNote;
  bool _seeded = false;
  bool _saving = false;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _initialNote = context.read<MovieNoteViewModel>().noteFor(widget.movieId);
    _controller.text = _initialNote?.content ?? '';
    _seeded = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final notes = context.read<MovieNoteViewModel>();
      if (!notes.isReady) await notes.initialize();
      await notes.saveNote(
        movieId: widget.movieId,
        movieTitle: widget.movieTitle,
        content: _controller.text,
      );
      if (mounted) Navigator.pop(context, MovieNoteSheetResult.saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = 'Không thể lưu ghi chú. Vui lòng thử lại.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: const Text(
          'Ghi chú này chỉ lưu trên thiết bị và không thể khôi phục sau khi xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await context.read<MovieNoteViewModel>().deleteNote(widget.movieId);
      if (mounted) Navigator.pop(context, MovieNoteSheetResult.deleted);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = 'Không thể xóa ghi chú. Vui lòng thử lại.';
        });
      }
    }
  }

  String _formatUpdatedAt(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}'
        ' · ${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space4,
        AppTheme.space20,
        AppTheme.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.primaryRedLight,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi chú riêng tư',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      widget.movieTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'Chỉ lưu trên thiết bị này, không hiển thị công khai.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          TextFormField(
            key: const Key('movie-note-field'),
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 7,
            maxLength: MovieNote.maxLength,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Cảm nhận của bạn',
              hintText: 'Ví dụ: đoạn kết đáng xem lại, chú ý phần nhạc phim...',
              alignLabelWithHint: true,
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Hãy nhập nội dung ghi chú.';
              if (text.length > MovieNote.maxLength) {
                return 'Ghi chú tối đa ${MovieNote.maxLength} ký tự.';
              }
              return null;
            },
          ),
          if (_initialNote != null) ...[
            const SizedBox(height: AppTheme.space4),
            Text(
              'Cập nhật ${_formatUpdatedAt(_initialNote!.updatedAt)}',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              _errorText!,
              key: const Key('movie-note-error'),
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space12,
        AppTheme.space20,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          if (_initialNote != null)
            TextButton.icon(
              key: const Key('movie-note-delete'),
              onPressed: _saving ? null : _delete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.danger,
              ),
              label: const Text(
                'Xóa',
                style: TextStyle(color: AppTheme.danger),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: AppTheme.space8),
          ElevatedButton.icon(
            key: const Key('movie-note-save'),
            style: AppTheme.primaryButtonStyle(),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white),
            label: Text(
              _initialNote == null ? 'Lưu ghi chú' : 'Lưu thay đổi',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxKeyboardInset = (screenHeight - 240).clamp(0.0, screenHeight);
    final bottomInset = MediaQuery.viewInsetsOf(context)
        .bottom
        .clamp(0.0, maxKeyboardInset)
        .toDouble();
    final sheetHeight =
        (screenHeight - bottomInset).clamp(240.0, 620.0).toDouble();
    return AnimatedPadding(
      duration: AppTheme.durationMedium,
      curve: AppTheme.curveEmphasized,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetHeight,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(child: _buildEditor()),
                    _buildActionBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
