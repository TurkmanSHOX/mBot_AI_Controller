import 'package:flutter/material.dart';
import '../services/mbot_service.dart';

class RobotControlWidget extends StatelessWidget {
  final MBotService mbotService;
  final double buttonSize;

  const RobotControlWidget({
    super.key,
    required this.mbotService,
    this.buttonSize = 75.0,
  });

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required VoidCallback onPress,
    required VoidCallback onRelease,
    Color bg = const Color(0xFF1E293B),
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPress(),
      onTapUp: (_) => onRelease(),
      onTapCancel: () => onRelease(),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: buttonSize * 0.42, color: iconColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: buttonSize * 0.13,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // OLDINGA
          _buildControlBtn(
            icon: Icons.arrow_upward,
            label: "OLDINGA",
            onPress: () => mbotService.forward(),
            onRelease: () => mbotService.stop(),
          ),
          const SizedBox(height: 10),
          // CHAPGA - STOP - O'NGGA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlBtn(
                icon: Icons.arrow_back,
                label: "CHAPGA",
                onPress: () => mbotService.turnLeft(),
                onRelease: () => mbotService.stop(),
              ),
              const SizedBox(width: 10),
              _buildControlBtn(
                icon: Icons.stop,
                label: "STOP",
                onPress: () => mbotService.stop(),
                onRelease: () {},
                bg: const Color(0xFFEF4444),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 10),
              _buildControlBtn(
                icon: Icons.arrow_forward,
                label: "O'NGGA",
                onPress: () => mbotService.turnRight(),
                onRelease: () => mbotService.stop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ORQAGA
          _buildControlBtn(
            icon: Icons.arrow_downward,
            label: "ORQAGA",
            onPress: () => mbotService.backward(),
            onRelease: () => mbotService.stop(),
          ),
        ],
      ),
    );
  }
}
