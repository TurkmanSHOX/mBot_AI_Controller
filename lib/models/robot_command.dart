enum CommandType {
  forward,
  backward,
  left,
  right,
  stop,
  dance,
  autonomous,
  beep,
  setLed,
  unknown
}

class RobotCommand {
  final CommandType type;
  final int durationSeconds;
  final int speed;
  final int? r;
  final int? g;
  final int? b;
  final int? freq;
  final int? durationMs;

  RobotCommand({
    required this.type,
    this.durationSeconds = 0,
    this.speed = 150,
    this.r,
    this.g,
    this.b,
    this.freq,
    this.durationMs,
  });

  String get displayName {
    switch (type) {
      case CommandType.forward:
        return durationSeconds > 0 ? "OLDINGA ($durationSeconds s)" : "OLDINGA";
      case CommandType.backward:
        return durationSeconds > 0 ? "ORQAGA ($durationSeconds s)" : "ORQAGA";
      case CommandType.left:
        return durationSeconds > 0 ? "CHAPGA ($durationSeconds s)" : "CHAPGA";
      case CommandType.right:
        return durationSeconds > 0 ? "O'NGGA ($durationSeconds s)" : "O'NGGA";
      case CommandType.stop:
        return "TO'XTASH";
      case CommandType.dance:
        return "RAQS TUSHISH";
      case CommandType.autonomous:
        return "AVTONOM REJIM";
      case CommandType.beep:
        return "SIGNAL (BEEP)";
      case CommandType.setLed:
        return "RGB CHIROQ";
      case CommandType.unknown:
        return "NOMA'LUM";
    }
  }
}
