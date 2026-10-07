import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';
import '../services/mbot_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final aiService = Provider.of<AiService>(context, listen: false);
    _apiKeyController.text = aiService.geminiApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BluetoothService>(context);
    final mbot = Provider.of<MBotService>(context);
    final speech = Provider.of<SpeechService>(context);
    final tts = Provider.of<TtsService>(context);
    final ai = Provider.of<AiService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        title: const Text("Sozlamalar va Aloqa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. BLUETOOTH QURILMALAR BOSHQARUVI
            _buildSectionHeader("BLUETOOTH VA mBot BOG'LANISHI", Icons.bluetooth),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 6,
                            backgroundColor: ble.isConnected ? Colors.greenAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ble.connectionStatus,
                            style: TextStyle(
                              color: ble.isConnected ? Colors.greenAccent : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ble.isScanning ? Colors.redAccent : const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (ble.isScanning) {
                            ble.stopScan();
                          } else {
                            ble.startScan();
                          }
                        },
                        icon: Icon(ble.isScanning ? Icons.stop : Icons.search, size: 18),
                        label: Text(ble.isScanning ? "To'xtatish" : "Qidirish"),
                      ),
                    ],
                  ),
                  if (ble.isScanning) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(color: Color(0xFF6366F1)),
                    const SizedBox(height: 8),
                    const Text("Yaqin atrofdagi Makeblock va mBot qurilmalari qidirilmoqda...",
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                  if (ble.connectedDevice != null) ...[
                    const Divider(color: Colors.white12, height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(
                        ble.connectedDevice!.platformName.isNotEmpty
                            ? ble.connectedDevice!.platformName
                            : "Makeblock mBot",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(ble.connectedDevice!.remoteId.str, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () => ble.disconnect(),
                        child: const Text("Uzish"),
                      ),
                    ),
                  ],
                  if (ble.scanResults.isNotEmpty && !ble.isConnected) ...[
                    const Divider(color: Colors.white12, height: 24),
                    const Text("Topilgan Qurilmalar:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...ble.scanResults.map((result) {
                      final name = result.device.platformName;
                      final isMakeblock = name.contains("Makeblock") || name.contains("mBot") || name.contains("Codey");
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMakeblock ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isMakeblock ? const Color(0xFF6366F1).withOpacity(0.4) : Colors.white10),
                        ),
                        child: ListTile(
                          title: Text(
                            name.isNotEmpty ? name : "Noma'lum qurilma",
                            style: TextStyle(
                              color: isMakeblock ? Colors.white : Colors.white70,
                              fontWeight: isMakeblock ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text("${result.device.remoteId.str} | RSSI: ${result.rssi} dBm",
                              style: const TextStyle(fontSize: 11, color: Colors.white38)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMakeblock ? const Color(0xFF6366F1) : const Color(0xFF334155),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => ble.connectToDevice(result.device),
                            child: const Text("Ulanish"),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. GEMINI AI MIYASI SOZLAMALARI
            _buildSectionHeader("GOOGLE GEMINI AI SOZLAMALARI", Icons.psychology),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gemini API Kaliti (Tabiiy suhbat va AI aql uchun):",
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "AIzaSy...",
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureApiKey ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                        onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ai.geminiApiKey.isNotEmpty ? "✓ Kalit faollashtirilgan" : "Lokal offline rejimda",
                        style: TextStyle(
                          fontSize: 11,
                          color: ai.geminiApiKey.isNotEmpty ? Colors.greenAccent : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ai.updateApiKey(_apiKeyController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Gemini API kaliti muvaffaqiyatli saqlandi!")),
                          );
                        },
                        child: const Text("Saqlash"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. TIL VA OVOZ SOZLAMALARI
            _buildSectionHeader("TIL VA OVOZ (STT / TTS)", Icons.record_voice_over),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Asosiy Muloqot Tili:", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildLangChoiceChip("O'zbek", "uz_UZ", "uz-UZ", speech, tts),
                      const SizedBox(width: 8),
                      _buildLangChoiceChip("Русский", "ru_RU", "ru-RU", speech, tts),
                      const SizedBox(width: 8),
                      _buildLangChoiceChip("English", "en_US", "en-US", speech, tts),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      tts.speak("Salom! Men mBot aqlli robotiman. Sizni tinglayapman.");
                    },
                    icon: const Icon(Icons.volume_up, size: 18, color: Colors.cyanAccent),
                    label: const Text("Ovozni Sinab Ko'rish"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. TEZLIK VA XAVFSIZLIK
            _buildSectionHeader("ROBOT TEZLIGI VA XAVFSIZLIGI", Icons.security),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Standart Harakat Tezligi: ${mbot.speedPercentage}%",
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Slider(
                    value: mbot.speedPercentage.toDouble(),
                    min: 20,
                    max: 100,
                    divisions: 4,
                    activeColor: const Color(0xFF6366F1),
                    inactiveColor: Colors.white12,
                    label: "${mbot.speedPercentage}%",
                    onChanged: (val) {
                      mbot.setSpeedPercentage(val.toInt());
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "To'siq masofasi < 15 cm bo'lganda robot avtomatik favqulodda to'xtaydi.",
                            style: TextStyle(fontSize: 11, color: Colors.amberAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                "mBot AI Android Controller v1.0.0\nMakeblock BLE + Google Gemini AI",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF818CF8)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF818CF8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChoiceChip(
    String label,
    String sttCode,
    String ttsCode,
    SpeechService speech,
    TtsService tts,
  ) {
    final isSelected = speech.currentLocaleId.startsWith(sttCode.substring(0, 2));
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF0F172A),
      onSelected: (selected) {
        if (selected) {
          speech.setLocale(sttCode);
          tts.setLanguage(ttsCode);
        }
      },
    );
  }
}
