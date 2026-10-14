import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/message.dart';

class TextingComposer extends StatefulWidget {
  const TextingComposer({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
    required this.onTyping,
    required this.onOpenAura,
    this.replyingTo,
    this.onCancelReply,
    this.initialDraft = '',
  });

  final ValueChanged<String> onSendText;
  final ValueChanged<String> onSendImage;
  final Function(String path, int durationSec) onSendVoice;
  final ValueChanged<bool> onTyping;
  final VoidCallback onOpenAura;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final String initialDraft;

  @override
  State<TextingComposer> createState() => _TextingComposerState();
}

class _TextingComposerState extends State<TextingComposer> {
  late final TextEditingController _controller;
  bool _isComposing = false;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final Stopwatch _recordingClock = Stopwatch();
  Timer? _recordingTicker;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDraft);
    _isComposing = widget.initialDraft.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _recorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allow microphone access to record voice notes.'),
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    _recordingClock
      ..reset()
      ..start();
    _recordingTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    setState(() => _isRecording = true);
  }

  void _endRecording() {
    _recordingTicker?.cancel();
    _recordingClock.stop();
    setState(() => _isRecording = false);
  }

  Future<void> _sendRecording() async {
    final seconds = _recordingClock.elapsed.inSeconds;
    _endRecording();
    final path = await _recorder.stop();
    if (path != null && seconds > 0) widget.onSendVoice(path, seconds);
  }

  Future<void> _cancelRecording() async {
    _endRecording();
    await _recorder.cancel();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendText(text);
    _controller.clear();
    setState(() => _isComposing = false);
    widget.onTyping(false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        widget.onSendImage(image.path);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null) _buildReplyPreview(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _isRecording
                      ? _CircleButton(
                          onTap: _cancelRecording,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppTheme.red,
                          ),
                        )
                      : _CircleButton(
                          onTap: _pickImage,
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: AppTheme.textingSendBtn,
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isRecording
                        ? _buildRecordingIndicator()
                        : _buildInput(),
                  ),
                  const SizedBox(width: 8),
                  if (_isComposing || _isRecording)
                    _CircleButton(
                      onTap: _isRecording ? _sendRecording : _handleSend,
                      child: SvgPicture.asset(
                        'assets/svgs/send_icon.svg',
                        width: 18,
                        height: 18,
                      ),
                    )
                  else
                    _CircleButton(
                      onTap: _startRecording,
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 22,
                        color: AppTheme.textingSendBtn,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    onTap: widget.onOpenAura,
                    child: SvgPicture.asset(
                      'assets/svgs/aura_active_icon.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkTextingInputBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.grayBg,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: SvgPicture.asset(
              'assets/svgs/emoji_button_icon.svg',
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: 12,
                height: 20 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              onChanged: (text) {
                final composing = text.trim().isNotEmpty;
                if (composing != _isComposing) {
                  setState(() => _isComposing = composing);
                  widget.onTyping(composing);
                }
              },
              decoration: InputDecoration(
                hintText: 'Type something lovely...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elapsed = _recordingClock.elapsed;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkTextingInputBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.grayBg,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${elapsed.inMinutes}:$seconds',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Recording...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textingTimestamp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.darkSurface2 : AppTheme.surface2,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.replyingTo!.isMe ? 'You' : 'Reply',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.red,
                  ),
                ),
                Text(
                  widget.replyingTo!.content.isNotEmpty
                      ? widget.replyingTo!.content
                      : widget.replyingTo!.type.name,
                  style: AppTextStyle.bodySecondary.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppTheme.darkSurface2 : AppTheme.insideGrey,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
  }
}
