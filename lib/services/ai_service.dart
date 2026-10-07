import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/robot_command.dart';
import '../models/sensor_data.dart';

class AiServiceResponse {
  final String speechReply;
  final RobotCommand? command;

  AiServiceResponse({required this.speechReply, this.command});
}

class AiService extends ChangeNotifier {
  String _geminiApiKey = "";
  final String _geminiModel = "gemini-1.5-flash";

  String get geminiApiKey => _geminiApiKey;

  AiService() {
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
  }

  void updateApiKey(String key) {
    _geminiApiKey = key;
    notifyListeners();
  }

  /// Foydalanuvchi nutqini tahlil qilish (AI Qaror qabul qilish markazi)
  Future<AiServiceResponse> processUserInput({
    required String userText,
    required SensorData currentSensors,
  }) async {
    final lower = userText.toLowerCase().trim();

    // 1. TEZ VA ANIQ QOIDALAR (Lokal tezkor tahlil - Offline rejimda ham 100% ishlaydi)
    final localResult = _classifyLocally(lower, currentSensors);
    if (localResult != null) {
      return localResult;
    }

    // 2. AGAR MAXSUS SUHBAT BO'LSA: GEMINI AI orqali chuqur tahlil
    if (_geminiApiKey.isNotEmpty && _geminiApiKey != "YOUR_GEMINI_API_KEY_HERE") {
      try {
        final geminiResult = await _queryGemini(userText, currentSensors);
        if (geminiResult != null) {
          return geminiResult;
        }
      } catch (e) {
        debugPrint("Gemini so'rov xatosi: $e");
      }
    }

    // 3. Fallback oddiy do'stona javob
    return AiServiceResponse(
      speechReply: "Sizni eshitdim. Buyruqni qaytadan aniqroq bering.",
      command: null,
    );
  }

  /// Lokal qoidalar tahlilchisi (Tezkor va xatosiz)
  AiServiceResponse? _classifyLocally(String text, SensorData sensors) {
    // Vaqtni aniqlash ("3 soniya", "2 sekund", "5 sekund")
    int duration = _extractDuration(text);

    // 1. OLDINGA HARAKAT
    if (text.contains("oldinga") || text.contains("vpered") || text.contains("forward") || text.contains("yur")) {
      if (text.contains("orqaga")) {
        // orqaga tushib qolmasligi uchun
      } else if (!text.contains("buril")) {
        // Xavfsizlik tekshiruvi: Oldinda to'siq bormi?
        if (sensors.isObstacleDanger) {
          return AiServiceResponse(
            speechReply: "Oldimda to'siq juda yaqin (${sensors.distanceCm.toInt()} santimetr). Xavfsizlik uchun oldinga yura olmayman.",
            command: RobotCommand(type: CommandType.stop),
          );
        }

        String reply = duration > 0 ? "$duration soniya oldinga yuraman." : "Mayli, oldinga yuraman.";
        return AiServiceResponse(
          speechReply: reply,
          command: RobotCommand(type: CommandType.forward, durationSeconds: duration),
        );
      }
    }

    // 2. ORQAGA HARAKAT
    if (text.contains("orqaga") || text.contains("qayt") || text.contains("nazad") || text.contains("backward")) {
      String reply = duration > 0 ? "$duration soniya orqaga qaytaman." : "Orqaga yuryapman.";
      return AiServiceResponse(
        speechReply: reply,
        command: RobotCommand(type: CommandType.backward, durationSeconds: duration),
      );
    }

    // 3. CHAPGA BURILISH
    if (text.contains("chapga") || text.contains("chap") || text.contains("left") || text.contains("nalevo")) {
      String reply = duration > 0 ? "$duration soniya chapga burilaman." : "Chap tomonga burilyapman.";
      return AiServiceResponse(
        speechReply: reply,
        command: RobotCommand(type: CommandType.left, durationSeconds: duration > 0 ? duration : 1),
      );
    }

    // 4. O'NGGA BURILISH
    if (text.contains("o'ngga") || text.contains("ongga") || text.contains("right") || text.contains("napravo")) {
      String reply = duration > 0 ? "$duration soniya o'ngga burilaman." : "O'ng tomonga burilyapman.";
      return AiServiceResponse(
        speechReply: reply,
        command: RobotCommand(type: CommandType.right, durationSeconds: duration > 0 ? duration : 1),
      );
    }

    // 5. TO'XTASH
    if (text.contains("to'xta") || text.contains("toxta") || text.contains("stop") || text.contains("stoy")) {
      return AiServiceResponse(
        speechReply: "To'xtadim.",
        command: RobotCommand(type: CommandType.stop),
      );
    }

    // 6. AVTOMATIK REJIM (AVTONOM QIDIRUV)
    if (text.contains("avtomatik") || text.contains("xonani aylan") || text.contains("o'zing yur") || text.contains("to'siqdan qoch")) {
      return AiServiceResponse(
        speechReply: "Avtomatik qidiruv rejimini yoqdim. To'siqlardan o'zim aylanib o'taman.",
        command: RobotCommand(type: CommandType.autonomous),
      );
    }

    // 7. RAQS TUSHISH
    if (text.contains("raqs") || text.contains("o'yna") || text.contains("dance")) {
      return AiServiceResponse(
        speechReply: "Albatta, siz uchun raqsga tushib beraman!",
        command: RobotCommand(type: CommandType.dance),
      );
    }

    // 8. TEZLIKNI SOZLASH
    if (text.contains("tezroq") || text.contains("bistro")) {
      return AiServiceResponse(
        speechReply: "Tezlikni oshirdim.",
        command: RobotCommand(type: CommandType.forward, speed: 220),
      );
    }
    if (text.contains("sekinroq") || text.contains("medlenno")) {
      return AiServiceResponse(
        speechReply: "Sekinroq harakatlanaman.",
        command: RobotCommand(type: CommandType.forward, speed: 100),
      );
    }

    // 9. DATCHIKLAR VA MASOFA HAQIDA SO'ROV
    if (text.contains("oldingda nima bor") || text.contains("masofa") || text.contains("qanchaga yaqin")) {
      if (sensors.distanceCm < 30) {
        return AiServiceResponse(
          speechReply: "Oldimda taxminan ${sensors.distanceCm.toInt()} santimetr masofada to'siq bor.",
          command: null,
        );
      } else {
        return AiServiceResponse(
          speechReply: "Oldim ochiq, eng yaqin to'siqqacha ${sensors.distanceCm.toInt()} santimetr.",
          command: null,
        );
      }
    }

    // 10. SALOMLASHISH VA HOL-AHVOL
    if (text.contains("salom") || text.contains("privet") || text.contains("hello")) {
      return AiServiceResponse(
        speechReply: "Salom! Men sizning aqlli mBot robotingizman. Sizga qanday yordam beray?",
        command: RobotCommand(type: CommandType.beep, freq: 523, durationMs: 200),
      );
    }

    if (text.contains("qalaysan") || text.contains("qandaysan") || text.contains("ahvoling")) {
      return AiServiceResponse(
        speechReply: "Yaxshiman, rahmat! Buyruqlaringizni bajarishga tayyorman.",
        command: null,
      );
    }

    if (text.contains("sen kimsan") || text.contains("otang kim")) {
      return AiServiceResponse(
        speechReply: "Men sun'iy intellekt orqali boshqariladigan mBot roboti bo'laman.",
        command: null,
      );
    }

    return null;
  }

  /// Matndan son / soniyani ajratib olish (masalan "3 soniya")
  int _extractDuration(String text) {
    final reg = RegExp(r'(\d+)\s*(soniya|sekund|sek|second|sec)');
    final match = reg.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1) ?? "0") ?? 0;
    }
    return 0;
  }

  /// Gemini AI orqali tahlil qilish
  Future<AiServiceResponse?> _queryGemini(String userPrompt, SensorData sensors) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey",
    );

    final systemInstruction = """
Siz Makeblock mBot robotining aqlli miyasisiz. 
Siz Android telefonida turibsiz, mBot esa sizning jismoniy tanangiz.
Siz o'zbek tilida gaplashasiz, do'stona va chaqqonsiz.

Hozirgi sensor holati:
- Oldingizdagi to'siqqacha masofa: ${sensors.distanceCm} sm
- Chiziq holati: ${sensors.lineStatusText}
- Robotning hozirgi holati: ${sensors.motionStateText}

Siz foydalanuvchining gapiga javob berishingiz va agar kerak bo'lsa robot buyrug'ini JSON formatida berishingiz kerak.
Format:
{
  "reply": "O'zbek tilida qisqa va aniq ovozli javob",
  "command": "FORWARD | BACKWARD | LEFT | RIGHT | STOP | DANCE | AUTONOMOUS | NONE",
  "duration": soniya (agar buyruqda vaqt aytilgan bo'lsa, aks holda 0)
}
Faqat toza JSON qaytaring.
""";

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": "$systemInstruction\n\nFoydalanuvchi dedi: \"$userPrompt\""}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 200,
      }
    });

    final res = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];
      rawText = rawText.replaceAll("```json", "").replaceAll("```", "").trim();

      final parsed = jsonDecode(rawText);
      String reply = parsed['reply'] ?? "Buyruq tushunildi.";
      String cmdStr = (parsed['command'] ?? "NONE").toString().toUpperCase();
      int dur = int.tryParse(parsed['duration'].toString()) ?? 0;

      RobotCommand? cmd;
      if (cmdStr == "FORWARD") {
        cmd = RobotCommand(type: CommandType.forward, durationSeconds: dur);
      } else if (cmdStr == "BACKWARD") {
        cmd = RobotCommand(type: CommandType.backward, durationSeconds: dur);
      } else if (cmdStr == "LEFT") {
        cmd = RobotCommand(type: CommandType.left, durationSeconds: dur);
      } else if (cmdStr == "RIGHT") {
        cmd = RobotCommand(type: CommandType.right, durationSeconds: dur);
      } else if (cmdStr == "STOP") {
        cmd = RobotCommand(type: CommandType.stop);
      } else if (cmdStr == "DANCE") {
        cmd = RobotCommand(type: CommandType.dance);
      } else if (cmdStr == "AUTONOMOUS") {
        cmd = RobotCommand(type: CommandType.autonomous);
      }

      return AiServiceResponse(speechReply: reply, command: cmd);
    }
    return null;
  }
}
