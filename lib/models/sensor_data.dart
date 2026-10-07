enum RobotMotionState {
  stopped,
  movingForward,
  movingBackward,
  turningLeft,
  turningRight,
  dancing,
  autonomousExploration,
  obstacleDetected
}

class SensorData {
  double distanceCm;
  bool leftLineSensor;
  bool rightLineSensor;
  int lightLevel;
  RobotMotionState motionState;
  int currentSpeed;

  SensorData({
    this.distanceCm = 100.0,
    this.leftLineSensor = false,
    this.rightLineSensor = false,
    this.lightLevel = 50,
    this.motionState = RobotMotionState.stopped,
    this.currentSpeed = 150,
  });

  bool get isObstacleDanger => distanceCm < 15.0;
  bool get isObstacleWarning => distanceCm >= 15.0 && distanceCm < 30.0;

  String get lineStatusText {
    if (leftLineSensor && rightLineSensor) return "To'liq chiziqda";
    if (leftLineSensor) return "Chap chiziqda";
    if (rightLineSensor) return "O'ng chiziqda";
    return "Chiziq yo'q";
  }

  String get motionStateText {
    switch (motionState) {
      case RobotMotionState.stopped:
        return "TO'XTAGAN";
      case RobotMotionState.movingForward:
        return "OLDINGA HARAKATLANMOQDA";
      case RobotMotionState.movingBackward:
        return "ORQAGA QAYTMOQDA";
      case RobotMotionState.turningLeft:
        return "CHAPGA BURILMOQDA";
      case RobotMotionState.turningRight:
        return "O'NGGA BURILMOQDA";
      case RobotMotionState.dancing:
        return "RAQSGA TUSHMOQDA";
      case RobotMotionState.autonomousExploration:
        return "AVTOMATIK QIDIRUVDA";
      case RobotMotionState.obstacleDetected:
        return "TO'SIQ ANIQLANDI!";
    }
  }
}
