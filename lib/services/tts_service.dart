import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool isSpeaking = false;
  String currentLanguage = "uz-UZ";

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(currentLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        isSpeaking = true;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        isSpeaking = false;
        debugPrint("TTS Xatolik: $msg");
        notifyListeners();
      });
    } catch (e) {
      debugPrint("TTS init xato: $e");
    }
  }

  /// Matnni ovoz chiqarib o'qish
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("TTS speak xato: $e");
    }
  }

  /// Ovozni to'xtatish
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      isSpeaking = false;
      notifyListeners();
    } catch (_) {}
  }

  /// Tilni o'zgartirish (uz-UZ, ru-RU, en-US)
  Future<void> setLanguage(String langCode) async {
    currentLanguage = langCode;
    await _flutterTts.setLanguage(langCode);
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
