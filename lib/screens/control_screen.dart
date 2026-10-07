import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mbot_service.dart';
import '../widgets/robot_control.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mbot = Provider.of<MBotService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        title: const Text("Qo'lda Boshqarish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // D-PAD
            RobotControlWidget(mbotService: mbot, buttonSize: 85),

            const SizedBox(height: 20),

            // TEZLIK PRESETLARI (20%, 40%, 60%, 80%, 100%)
            Container(
              padding: const EdgeInsets.all(14),
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
                      const Text("TEZLIK DARAJASI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                      Text("${mbot.speedPercentage}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [20, 40, 60, 80, 100].map((percent) {
                      final isSelected = mbot.speedPercentage == percent;
                      return ChoiceChip(
                        label: Text("$percent%"),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => mbot.setSpeedPercentage(percent),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // RAQS VA SIGNAL
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => mbot.dance(),
                    icon: const Icon(Icons.music_note),
                    label: const Text("Raqs Tush!", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => mbot.beep(freq: 700, durationMs: 200),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text("Signal (Beep)", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // RGB CHIROQLAR PALITRASI
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RGB CHIROQLAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLedBtn(Colors.red, "Qizil", () => mbot.setLed(255, 0, 0)),
                      _buildLedBtn(Colors.green, "Yashil", () => mbot.setLed(0, 255, 0)),
                      _buildLedBtn(Colors.blue, "Ko'k", () => mbot.setLed(0, 0, 255)),
                      _buildLedBtn(Colors.purple, "Siyohrang", () => mbot.setLed(255, 0, 255)),
                      _buildLedBtn(Colors.amber, "Sariq", () => mbot.setLed(255, 200, 0)),
                      _buildLedBtn(Colors.grey, "O'chirish", () => mbot.setLed(0, 0, 0)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedBtn(Color color, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: color,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
