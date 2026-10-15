import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/message.dart';
import 'attachment_sheet.dart';

enum _RecordingPhase { idle, recording, paused, reviewing }

const _maxUploadBytes = 8 * 1024 * 1024;
const _maxVoiceSeconds = 600;

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
  AudioPlayer? _previewPlayer;
  _RecordingPhase _phase = _RecordingPhase.idle;
  String? _recordedPath;

  bool get _isRecording => _phase != _RecordingPhase.idle;

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
    _previewPlayer?.dispose();
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
    setState(() => _phase = _RecordingPhase.recording);
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    _recordingClock.stop();
    setState(() => _phase = _RecordingPhase.paused);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    _recordingClock.start();
    setState(() => _phase = _RecordingPhase.recording);
  }

  Future<void> _reviewRecording() async {
    _recordingTicker?.cancel();
    _recordingClock.stop();
    final path = await _recorder.stop();
    if (path == null) {
      _endRecording();
      return;
    }

    final player = _previewPlayer ??= AudioPlayer();
    await player.setFilePath(path);
    setState(() {
      _recordedPath = path;
      _phase = _RecordingPhase.reviewing;
    });
    await player.play();
  }

  Future<void> _togglePreview() async {
    final player = _previewPlayer;
    if (player == null) return;

    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.play();
    }
  }

  void _endRecording() {
    _recordingTicker?.cancel();
    _recordingClock.stop();
    setState(() {
      _phase = _RecordingPhase.idle;
      _recordedPath = null;
    });
  }

  Future<void> _sendRecording() async {
    final seconds = _recordingClock.elapsed.inSeconds;
    final reviewedPath = _recordedPath;
    _endRecording();
    await _previewPlayer?.stop();
    final path = reviewedPath ?? await _recorder.stop();
    if (path != null && seconds > 0) widget.onSendVoice(path, seconds);
  }

  Future<void> _cancelRecording() async {
    final reviewedPath = _recordedPath;
    _endRecording();
    if (reviewedPath == null) {
      await _recorder.cancel();
      return;
    }

    await _previewPlayer?.stop();
    try {
      await File(reviewedPath).delete();
    } on FileSystemException catch (_) {}
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendText(text);
    _controller.clear();
    setState(() => _isComposing = false);
    widget.onTyping(false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _fitsUploadLimit(String path) async {
    if (await File(path).length() <= _maxUploadBytes) return true;
    _showMessage('Attachments must be 8 MB or smaller.');
    return false;
  }

  Future<void> _showAttachmentOptions() async {
    final option = await AttachmentSheet.show(context);
    switch (option) {
      case AttachmentOption.gallery:
        await _pickImage(ImageSource.gallery);
      case AttachmentOption.camera:
        await _pickImage(ImageSource.camera);
      case AttachmentOption.audio:
        await _pickAudio();
      case null:
        break;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image;
    try {
      image = await _picker.pickImage(source: source, imageQuality: 80);
    } on PlatformException {
      _showMessage(
        source == ImageSource.camera
            ? 'Allow camera access to take photos.'
            : 'Allow photo access to send pictures.',
      );
      return;
    }
    if (image == null || !await _fitsUploadLimit(image.path)) return;
    widget.onSendImage(image.path);
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
    );
    final path = result?.files.single.path;
    if (path == null || !await _fitsUploadLimit(path)) return;

    final player = AudioPlayer();
    final Duration? duration;
    try {
      duration = await player.setFilePath(path);
    } on PlayerException {
      _showMessage("That audio file couldn't be read.");
      return;
    } finally {
      await player.dispose();
    }

    final seconds = ((duration?.inMilliseconds ?? 0) / 1000).ceil();
    if (seconds == 0) {
      _showMessage("That audio file couldn't be read.");
    } else if (seconds > _maxVoiceSeconds) {
      _showMessage('Audio must be 10 minutes or shorter.');
    } else {
      widget.onSendVoice(path, seconds);
    }
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
                          onTap: _showAttachmentOptions,
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
                }
                widget.onTyping(composing);
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
    final fg = Theme.of(context).colorScheme.onSurface;

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
      child: _phase == _RecordingPhase.reviewing
          ? _buildPreviewControls(fg)
          : _buildRecordingControls(fg),
    );
  }

  Widget _buildRecordingControls(Color fg) {
    final isPaused = _phase == _RecordingPhase.paused;

    return Row(
      children: [
        if (isPaused)
          _IndicatorButton(
            icon: Icons.play_arrow_rounded,
            color: fg,
            onTap: _reviewRecording,
          )
        else
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
          _formatDuration(_recordingClock.elapsed),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isPaused ? 'Paused' : 'Recording...',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textingTimestamp,
            ),
          ),
        ),
        _IndicatorButton(
          icon: isPaused ? Icons.mic_rounded : Icons.pause_rounded,
          color: isPaused ? AppTheme.red : fg,
          onTap: isPaused ? _resumeRecording : _pauseRecording,
        ),
      ],
    );
  }

  Widget _buildPreviewControls(Color fg) {
    final player = _previewPlayer!;

    return Row(
      children: [
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final isPlaying =
                state != null &&
                state.playing &&
                state.processingState != ProcessingState.completed;
            return _IndicatorButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: fg,
              onTap: _togglePreview,
            );
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final total = player.duration ?? _recordingClock.elapsed;
              final position = snapshot.data ?? Duration.zero;
              final progress = total.inMilliseconds == 0
                  ? 0.0
                  : position.inMilliseconds / total.inMilliseconds;
              return Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      color: fg,
                      backgroundColor: AppTheme.grayBg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(total - position),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$seconds';
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

class _IndicatorButton extends StatelessWidget {
  const _IndicatorButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 40,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
