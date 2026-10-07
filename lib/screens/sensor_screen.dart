import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/mbot_service.dart';
import '../widgets/sensor_card.dart';

class SensorScreen extends StatelessWidget {
  const SensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mbot = Provider.of<MBotService>(context);
    final ble = Provider.of<BluetoothService>(context);
    final sensors = mbot.sensorData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 0,
        title: const Text("mBot Sensorlar Paneli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 5,
                  backgroundColor: ble.isConnected ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  ble.isConnected ? "Ulangan" : "Uzilgan",
                  style: TextStyle(
                    fontSize: 12,
                    color: ble.isConnected ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ultratovush datchigi (Masofa)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      sensors.isObstacleDanger
                          ? Colors.red.shade900.withOpacity(0.4)
                          : const Color(0xFF1E293B),
                      const Color(0xFF1E293B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sensors.isObstacleDanger
                        ? Colors.redAccent
                        : (sensors.isObstacleWarning ? Colors.amberAccent : Colors.white12),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.radar, color: Color(0xFF818CF8), size: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("ULTRATONIK SENSOR", style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                                Text("Port 3 (Ultrasonic)", style: TextStyle(fontSize: 11, color: Colors.white38)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sensors.isObstacleDanger
                                ? Colors.red.withOpacity(0.2)
                                : (sensors.isObstacleWarning ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sensors.isObstacleDanger
                                ? "XAVF!"
                                : (sensors.isObstacleWarning ? "OGOHLANTIRISH" : "XAVFSIZ"),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: sensors.isObstacleDanger
                                  ? Colors.redAccent
                                  : (sensors.isObstacleWarning ? Colors.amberAccent : Colors.greenAccent),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${sensors.distanceCm} cm",
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: sensors.isObstacleDanger
                            ? Colors.redAccent
                            : (sensors.isObstacleWarning ? Colors.amberAccent : Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sensors.isObstacleDanger
                          ? "Masofa < 15 cm: Avtomatik tormoz faol!"
                          : "Old masofa xavfsiz holatda",
                      style: TextStyle(
                        fontSize: 12,
                        color: sensors.isObstacleDanger ? Colors.redAccent : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (sensors.distanceCm / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                          sensors.isObstacleDanger
                              ? Colors.redAccent
                              : (sensors.isObstacleWarning ? Colors.amberAccent : Colors.greenAccent),
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Chiziq datchigi (Line Follower)
              SensorCard(
                icon: Icons.alt_route,
                title: "CHIZIQ SENSORI (Line Follower - Port 2)",
                value: sensors.lineStatusText,
                accentColor: Colors.cyanAccent,
                trailing: Row(
                  children: [
                    _buildLineSensorIndicator("Chap", sensors.leftLineSensor),
                    const SizedBox(width: 8),
                    _buildLineSensorIndicator("O'ng", sensors.rightLineSensor),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Robot Harakat Holati
              SensorCard(
                icon: Icons.directions_run,
                title: "ROBOT HARAKATI",
                value: sensors.motionStateText,
                accentColor: Colors.amberAccent,
              ),

              const SizedBox(height: 12),

              // 4. Dvigatel va Tezlik
              SensorCard(
                icon: Icons.speed,
                title: "MOTOR TEZLIGI",
                value: "${mbot.speedPercentage}% (${mbot.currentPwmSpeed} PWM)",
                accentColor: Colors.purpleAccent,
                trailing: IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 30),
                  onPressed: () => mbot.stopMotors(),
                  tooltip: "To'xtatish",
                ),
              ),

              const SizedBox(height: 12),

              // 5. Yorug'lik sensori
              SensorCard(
                icon: Icons.wb_sunny,
                title: "YORUG'LIK SENSORI (Light Sensor)",
                value: "${sensors.lightLevel} %",
                accentColor: Colors.orangeAccent,
              ),

              const SizedBox(height: 24),

              // 6. Test va Aktuatorlar
              const Text(
                "AKTUATORLAR VA SINOV",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white60, letterSpacing: 1),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => mbot.playBuzzerTone(523, 250),
                      icon: const Icon(Icons.volume_up, color: Colors.amberAccent),
                      label: const Text("Buzzer Sinov"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        // RGB LED ni ko'k rangda yoqish
                        mbot.setRgbLed(0, 0, 255);
                        Future.delayed(const Duration(milliseconds: 500), () {
                          mbot.setRgbLed(0, 0, 0);
                        });
                      },
                      icon: const Icon(Icons.lightbulb, color: Colors.blueAccent),
                      label: const Text("LED Sinov"),
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

  Widget _buildLineSensorIndicator(String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: active ? Colors.cyanAccent : Colors.white24,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: active ? Colors.cyanAccent : Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
