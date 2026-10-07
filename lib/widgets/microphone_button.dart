import 'package:flutter/material.dart';

class MicrophoneButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final double size;

  const MicrophoneButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.size = 80.0,
  });

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = widget.isListening ? _scaleAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isListening
                      ? [const Color(0xFFEF4444), const Color(0xFFEC4899)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isListening ? Colors.redAccent : const Color(0xFF6366F1)).withOpacity(0.5),
                    blurRadius: widget.isListening ? 25 : 12,
                    spreadRadius: widget.isListening ? 6 : 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
