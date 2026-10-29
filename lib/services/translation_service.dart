import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranslatorLanguage {
  final String code;
  final String label;
  final TranslateLanguage translationLanguage;
  final String speechLocale;
  final String ttsLocale;

  const TranslatorLanguage({
    required this.code,
    required this.label,
    required this.translationLanguage,
    required this.speechLocale,
    required this.ttsLocale,
  });

  static const vietnamese = TranslatorLanguage(
    code: 'vi',
    label: 'Tiếng Việt',
    translationLanguage: TranslateLanguage.vietnamese,
    speechLocale: 'vi_VN',
    ttsLocale: 'vi-VN',
  );
  static const english = TranslatorLanguage(
    code: 'en',
    label: 'English',
    translationLanguage: TranslateLanguage.english,
    speechLocale: 'en_US',
    ttsLocale: 'en-US',
  );
  static const japanese = TranslatorLanguage(
    code: 'ja',
    label: '日本語',
    translationLanguage: TranslateLanguage.japanese,
    speechLocale: 'ja_JP',
    ttsLocale: 'ja-JP',
  );
  static const korean = TranslatorLanguage(
    code: 'ko',
    label: '한국어',
    translationLanguage: TranslateLanguage.korean,
    speechLocale: 'ko_KR',
    ttsLocale: 'ko-KR',
  );
  static const chinese = TranslatorLanguage(
    code: 'zh',
    label: '中文',
    translationLanguage: TranslateLanguage.chinese,
    speechLocale: 'zh_CN',
    ttsLocale: 'zh-CN',
  );
  static const french = TranslatorLanguage(
    code: 'fr',
    label: 'Français',
    translationLanguage: TranslateLanguage.french,
    speechLocale: 'fr_FR',
    ttsLocale: 'fr-FR',
  );

  static const values = [
    vietnamese,
    english,
    japanese,
    korean,
    chinese,
    french,
  ];
}

class TranslationService {
  final ImagePicker _imagePicker = ImagePicker();
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  Future<String> translate({
    required String text,
    required TranslatorLanguage source,
    required TranslatorLanguage target,
  }) async {
    if (text.trim().isEmpty) return '';
    if (source.code == target.code) return text.trim();

    await _modelManager.downloadModel(source.translationLanguage.bcpCode);
    await _modelManager.downloadModel(target.translationLanguage.bcpCode);
    final translator = OnDeviceTranslator(
      sourceLanguage: source.translationLanguage,
      targetLanguage: target.translationLanguage,
    );
    try {
      return await translator.translateText(text.trim());
    } finally {
      translator.close();
    }
  }

  Future<String> recognizeImage(
    ImageSource source, {
    required TranslatorLanguage language,
  }) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) return '';
    final recognizer = TextRecognizer(script: _scriptFor(language));
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      return recognized.text.trim();
    } finally {
      await recognizer.close();
    }
  }

  TextRecognitionScript _scriptFor(TranslatorLanguage language) {
    switch (language.code) {
      case 'zh':
        return TextRecognitionScript.chinese;
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'ko':
        return TextRecognitionScript.korean;
      default:
        return TextRecognitionScript.latin;
    }
  }

  Future<bool> initializeSpeech({required void Function(String) onStatus}) {
    return speech.initialize(onStatus: onStatus);
  }

  Future<void> startSpeech({
    required String localeId,
    required void Function(String) onResult,
  }) {
    return speech.listen(
      listenOptions: SpeechListenOptions(localeId: localeId),
      onResult: (result) => onResult(result.recognizedWords),
    );
  }

  Future<void> stopSpeech() => speech.stop();

  Future<void> speak(String text, String locale) async {
    if (text.trim().isEmpty) return;
    await tts.setLanguage(locale);
    await tts.speak(text.trim());
  }

  Future<void> dispose() async {
    await speech.stop();
    await tts.stop();
  }
}
