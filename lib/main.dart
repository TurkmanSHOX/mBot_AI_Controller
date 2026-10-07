import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/bluetooth_service.dart';
import 'services/mbot_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'services/ai_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env faylini yuklash
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env faylini yuklashda xatolik (standart sozlamalar ishlatiladi): $e");
  }

  // Tizim UI panelini sozlash
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Servis instansiyalarini yaratish
  final bleService = BluetoothService();
  final mbotService = MBotService(bleService);
  final speechService = SpeechService();
  final ttsService = TtsService();
  final aiService = AiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BluetoothService>.value(value: bleService),
        ChangeNotifierProvider<MBotService>.value(value: mbotService),
        ChangeNotifierProvider<SpeechService>.value(value: speechService),
        ChangeNotifierProvider<TtsService>.value(value: ttsService),
        ChangeNotifierProvider<AiService>.value(value: aiService),
      ],
      child: const MBotApp(),
    ),
  );
}

class MBotApp extends StatelessWidget {
  const MBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI mBot Brain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
          background: Color(0xFF0F172A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1B4B),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
