import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool isListening = false;
  bool isAvailable = false;
  String lastWords = "";
  String currentLocaleId = "uz_UZ";

  SpeechService() {
    initSpeech();
  }

  /// Mikrofonni tayyorlash va ruxsatlarni tekshirish
  Future<bool> initSpeech() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      isAvailable = false;
      notifyListeners();
      return false;
    }

    try {
      isAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            isListening = false;
          }
          notifyListeners();
        },
        onError: (val) {
          isListening = false;
          debugPrint("STT Xato: ${val.errorMsg}");
          notifyListeners();
        },
      );

      // Tilni tekshirish
      if (isAvailable) {
        var locales = await _speech.locales();
        var uzLocale = locales.firstWhere(
          (loc) => loc.localeId.startsWith("uz"),
          orElse: () => locales.firstWhere(
            (loc) => loc.localeId.startsWith("ru"),
            orElse: () => locales.first,
          ),
        );
        currentLocaleId = uzLocale.localeId;
      }

      notifyListeners();
      return isAvailable;
    } catch (e) {
      isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// Tinglashni boshlash
  Future<void> startListening({required Function(String text) onResultText}) async {
    if (!isAvailable) {
      final ok = await initSpeech();
      if (!ok) return;
    }

    lastWords = "";
    isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        lastWords = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          onResultText(result.recognizedWords);
        }
      },
      localeId: currentLocaleId,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Tinglashni to'xtatish
  Future<void> stopListening() async {
    await _speech.stop();
    isListening = false;
    notifyListeners();
  }

  void setLocale(String localeId) {
    currentLocaleId = localeId;
    notifyListeners();
  }
}
