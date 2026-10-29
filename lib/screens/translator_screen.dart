import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/translation_service.dart';
import '../widgets/language_selector.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final _sourceController = TextEditingController();
  final _translationService = TranslationService();
  Timer? _debounce;
  TranslatorLanguage _source = TranslatorLanguage.vietnamese;
  TranslatorLanguage _target = TranslatorLanguage.english;
  String _translation = '';
  String _status = 'Nhập văn bản để bắt đầu dịch';
  bool _isTranslating = false;
  bool _isListening = false;
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _sourceController.dispose();
    _translationService.dispose();
    super.dispose();
  }

  void _scheduleTranslation() {
    _debounce?.cancel();
    final text = _sourceController.text;
    if (text.trim().isEmpty) {
      setState(() {
        _translation = '';
        _status = 'Nhập văn bản để bắt đầu dịch';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), _translate);
  }

  Future<void> _translate() async {
    final text = _sourceController.text.trim();
    final requestId = ++_requestId;
    setState(() {
      _isTranslating = true;
      _status = 'Đang dịch...';
    });
    try {
      final result = await _translationService.translate(
        text: text,
        source: _source,
        target: _target,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _translation = result;
        _status = 'Đã dịch';
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _status = 'Không thể dịch: ${_friendlyError(error)}');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isTranslating = false);
      }
    }
  }

  String _friendlyError(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('PlatformException(', '');

  void _swapLanguages() {
    final oldSource = _source;
    setState(() {
      _source = _target;
      _target = oldSource;
      final oldText = _sourceController.text;
      _sourceController.text = _translation;
      _translation = oldText;
    });
    _scheduleTranslation();
  }

  Future<void> _toggleSpeech() async {
    if (_isListening) {
      await _translationService.stopSpeech();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    try {
      final available = await _translationService.initializeSpeech(
        onStatus: (status) {
          if (mounted && status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      if (!available) {
        throw Exception('Thiết bị không hỗ trợ nhận diện giọng nói.');
      }
      setState(() => _isListening = true);
      await _translationService.startSpeech(
        localeId: _source.speechLocale,
        onResult: (words) {
          _sourceController.text = words;
          _sourceController.selection = TextSelection.fromPosition(
            TextPosition(offset: words.length),
          );
          _scheduleTranslation();
        },
      );
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    }
  }

  Future<void> _recognizeImage(ImageSource source) async {
    try {
      setState(() => _status = 'Đang nhận diện chữ trong ảnh...');
      final text = await _translationService.recognizeImage(
        source,
        language: _source,
      );
      if (!mounted) return;
      if (text.isEmpty) {
        _showMessage('Không tìm thấy văn bản trong ảnh.');
        setState(() => _status = 'Ảnh không có văn bản');
        return;
      }
      _sourceController.text = text;
      _sourceController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
      _scheduleTranslation();
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Realtime Translator'),
      actions: [
        IconButton(
          tooltip: 'Xóa',
          onPressed: () {
            _sourceController.clear();
            _scheduleTranslation();
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            'Dịch nhanh, nói tự nhiên',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dịch trên thiết bị, có thể cần tải mô hình ngôn ngữ lần đầu.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LanguageSelector(
                  value: _source,
                  onChanged: (value) {
                    setState(() => _source = value);
                    _scheduleTranslation();
                  },
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Hoán đổi ngôn ngữ',
                onPressed: _swapLanguages,
                icon: const Icon(Icons.swap_horiz),
              ),
              Expanded(
                child: LanguageSelector(
                  value: _target,
                  onChanged: (value) {
                    setState(() => _target = value);
                    _scheduleTranslation();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TextPanel(
            title: 'Văn bản gốc',
            icon: Icons.edit_note,
            footer: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: _isListening ? 'Dừng ghi âm' : 'Nói để dịch',
                  onPressed: _toggleSpeech,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  color: _isListening ? Colors.red : null,
                ),
                IconButton(
                  tooltip: 'Chụp ảnh',
                  onPressed: () => _recognizeImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
                IconButton(
                  tooltip: 'Chọn ảnh',
                  onPressed: () => _recognizeImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              ],
            ),
            child: TextField(
              controller: _sourceController,
              minLines: 5,
              maxLines: 9,
              onChanged: (_) => _scheduleTranslation(),
              decoration: const InputDecoration(
                hintText: 'Nhập hoặc nói nội dung cần dịch...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _TextPanel(
            title: 'Bản dịch',
            icon: Icons.translate,
            footer: Row(
              children: [
                if (_isTranslating)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Text(_status, style: const TextStyle(fontSize: 12)),
                ),
                IconButton(
                  tooltip: 'Đọc bản dịch',
                  onPressed: _translation.isEmpty
                      ? null
                      : () => _translationService.speak(
                          _translation,
                          _target.ttsLocale,
                        ),
                  icon: const Icon(Icons.volume_up_outlined),
                ),
                IconButton(
                  tooltip: 'Sao chép',
                  onPressed: _translation.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _translation),
                          );
                          if (mounted) _showMessage('Đã sao chép bản dịch.');
                        },
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            child: SelectableText(
              _translation.isEmpty
                  ? 'Bản dịch sẽ xuất hiện ở đây'
                  : _translation,
              style: TextStyle(
                fontSize: 17,
                color: _translation.isEmpty ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TextPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget footer;

  const _TextPanel({
    required this.title,
    required this.icon,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 4),
          footer,
        ],
      ),
    ),
  );
}
