import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/mbot_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/ai_service.dart';
import '../widgets/microphone_button.dart';
import '../widgets/robot_control.dart';
import 'chat_screen.dart';
import 'control_screen.dart';
import 'sensor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String liveVoiceFeedback = "Ovozli buyruq berish uchun mikrofonni bosing";

  @override
  void initState() {
    super.initState();

    // Xavfsizlik hodisasini ulash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mbot = Provider.of<MBotService>(context, listen: false);
      final tts = Provider.of<TtsService>(context, listen: false);
      mbot.onSafetyTriggered = (reason) {
        tts.speak(reason);
        setState(() {
          liveVoiceFeedback = reason;
        });
      };
    });
  }

  void _handleVoiceInput() async {
    final speech = Provider.of<SpeechService>(context, listen: false);
    final ai = Provider.of<AiService>(context, listen: false);
    final mbot = Provider.of<MBotService>(context, listen: false);
    final tts = Provider.of<TtsService>(context, listen: false);

    if (speech.isListening) {
      await speech.stopListening();
      return;
    }

    setState(() {
      liveVoiceFeedback = "Tinglayapman...";
    });

    await speech.startListening(
      onResultText: (text) async {
        setState(() {
          liveVoiceFeedback = "Siz: \"$text\"";
        });

        // AI tahlili
        final response = await ai.processUserInput(
          userText: text,
          currentSensors: mbot.sensorData,
        );

        setState(() {
          liveVoiceFeedback = "Robot: ${response.speechReply}";
        });

        // Ovozli javob
        await tts.speak(response.speechReply);

        // Buyruqni mBot'da bajarish
        if (response.command != null) {
          await mbot.executeCommand(response.command!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BluetoothService>(context);
    final mbot = Provider.of<MBotService>(context);
    final speech = Provider.of<SpeechService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            const Text("AI mBot Brain", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // 1. Bluetooth Aloqa Holati
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ble.isConnected ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ble.isConnected ? Colors.green.withOpacity(0.4) : Colors.amber.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 6,
                      backgroundColor: ble.isConnected ? Colors.greenAccent : Colors.amberAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ble.isConnected ? "mBot ulangan (${ble.connectedDevice?.platformName ?? ''})" : "mBot ulanmagan",
                        style: TextStyle(
                          color: ble.isConnected ? Colors.greenAccent : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: ble.isConnected ? Colors.red.withOpacity(0.2) : const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (ble.isConnected) {
                          ble.disconnect();
                        } else {
                          ble.startScan();
                        }
                      },
                      icon: Icon(ble.isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching, size: 16),
                      label: Text(ble.isConnected ? "Uzish" : "Ulash", style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Robot Holati va Datchik Mini Paneli
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ROBOT HOLATI", style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              mbot.sensorData.motionStateText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: mbot.sensorData.isObstacleDanger ? Colors.redAccent : Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("MASOFA (ULTRASONIC)", style: TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              "${mbot.sensorData.distanceCm} cm",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: mbot.sensorData.isObstacleDanger
                                    ? Colors.redAccent
                                    : (mbot.sensorData.isObstacleWarning ? Colors.amberAccent : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (mbot.sensorData.distanceCm / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          mbot.sensorData.isObstacleDanger
                              ? Colors.redAccent
                              : (mbot.sensorData.isObstacleWarning ? Colors.amberAccent : Colors.greenAccent),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. AI Ovozli Boshqaruv Markazi (Katta Mikrofon)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E1B4B), const Color(0xFF0F172A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    MicrophoneButton(
                      isListening: speech.isListening,
                      onTap: _handleVoiceInput,
                      size: 90,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      liveVoiceFeedback,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: speech.isListening ? Colors.pinkAccent : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. Tezkor Rejimlar Tugmalari
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mbot.isAutonomousMode ? Colors.amber.shade700 : const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => mbot.toggleAutonomousMode(),
                      icon: Icon(mbot.isAutonomousMode ? Icons.pause_circle : Icons.explore, size: 20),
                      label: Text(
                        mbot.isAutonomousMode ? "Avtonom Stop" : "Avtonom Rejim",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                      icon: const Icon(Icons.chat, size: 20),
                      label: const Text("AI Suhbat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Tezkor D-Pad boshqaruv
              RobotControlWidget(mbotService: mbot, buttonSize: 72),

              const SizedBox(height: 14),

              // 6. Sensorlar va Boshqaruv menyulari
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ControlScreen())),
                      icon: const Icon(Icons.gamepad, size: 18),
                      label: const Text("Qo'lda Boshqarish", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SensorScreen())),
                      icon: const Icon(Icons.sensors, size: 18),
                      label: const Text("Sensorlar", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
