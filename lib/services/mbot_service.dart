import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/robot_command.dart';
import '../utils/constants.dart';
import 'bluetooth_service.dart';

class MBotService extends ChangeNotifier {
  final BluetoothService _bleService;
  final SensorData sensorData = SensorData();

  Timer? _sensorPollTimer;
  Timer? _durationTimer;
  Timer? _autoModeTimer;

  bool isAutonomousMode = false;
  int speedPercentage = 60; // 20, 40, 60, 80, 100%

  int get currentPwmSpeed => (speedPercentage * 255 / 100).round();

  // Xavfsizlik hodisasi (Tinglovchilar uchun: masalan TTS ovoz chiqarishi uchun)
  Function(String reason)? onSafetyTriggered;

  MBotService(this._bleService) {
    // Sensor ma'lumotlarini qabul qilish
    _bleService.incomingDataStream.listen(_parseIncomingBytes);

    // Aloqa holati o'zgarganda datchiklarni so'rashni boshlash/to'xtatish
    _bleService.addListener(() {
      if (_bleService.isConnected) {
        _startSensorPolling();
      } else {
        _stopSensorPolling();
        isAutonomousMode = false;
        sensorData.motionState = RobotMotionState.stopped;
        notifyListeners();
      }
    });
  }

  /// Datchiklardan ma'lumotlarni so'rash taymeri (har 300 ms da)
  void _startSensorPolling() {
    _sensorPollTimer?.cancel();
    _sensorPollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_bleService.isConnected) return;
      _requestUltrasonicSensor();
      Future.delayed(const Duration(milliseconds: 60), () {
        if (_bleService.isConnected) _requestLineFollowerSensor();
      });
    });
  }

  void _stopSensorPolling() {
    _sensorPollTimer?.cancel();
    _sensorPollTimer = null;
  }

  /// Ultratovush datchigidan masofani so'rash
  void _requestUltrasonicSensor() {
    // ff 55 04 00 01 01 [port]
    final bytes = [
      AppConstants.headerByte1,
      AppConstants.headerByte2,
      0x04, 0x00, 0x01, 0x01,
      AppConstants.portUltrasonic,
    ];
    _bleService.sendBytes(bytes);
  }

  /// Chiziq datchigidan (Line Follower) holatni so'rash
  void _requestLineFollowerSensor() {
    // ff 55 04 00 01 11 [port]
    final bytes = [
      AppConstants.headerByte1,
      AppConstants.headerByte2,
      0x04, 0x00, 0x01, 0x11,
      AppConstants.portLineFollower,
    ];
    _bleService.sendBytes(bytes);
  }

  /// Qaytgan binar baytlarni tahlil qilish (0xFF 0x55 ...)
  void _parseIncomingBytes(List<int> bytes) {
    if (bytes.length < 4) return;
    if (bytes[0] != 0xff || bytes[1] != 0x55) return;

    // Masofa datchigi float qaytaradi (4 bayt)
    if (bytes.length >= 8 && bytes[3] == 0x02) {
      final buffer = Uint8List.fromList(bytes.sublist(4, 8));
      final byteData = ByteData.sublistView(buffer);
      double distance = byteData.getFloat32(0, Endian.little);

      if (distance >= 0 && distance <= 400) {
        sensorData.distanceCm = double.parse(distance.toStringAsFixed(1));

        // XAVFSIZLIK TIZIMI: Agar masofa 15 sm dan kam bo'lsa
        if (sensorData.isObstacleDanger && sensorData.motionState == RobotMotionState.movingForward) {
          emergencyStop("To'siq juda yaqin! Xavfsizlik uchun to'xtatildi.");
        }

        notifyListeners();
      }
    }

    // Chiziq datchigi 1 bayt qaytaradi
    if (bytes.length >= 5 && bytes[3] == 0x01) {
      int lineVal = bytes[4];
      // 0 = ikkala qora, 1 = chap qora, 2 = o'ng qora, 3 = ikkala oq
      sensorData.leftLineSensor = (lineVal == 0 || lineVal == 1);
      sensorData.rightLineSensor = (lineVal == 0 || lineVal == 2);
      notifyListeners();
    }
  }

  /// FAVQULODDA TO'XTASH (Xavfsizlik interlocki)
  void emergencyStop(String reason) {
    stop();
    sensorData.motionState = RobotMotionState.obstacleDetected;
    notifyListeners();
    beep(freq: 880, durationMs: 300);
    setLed(255, 0, 0); // Qizil chiroq
    if (onSafetyTriggered != null) {
      onSafetyTriggered!(reason);
    }
  }

  /// Motorlarni harakatlantirish
  Future<void> _setMotors(int leftSpd, int rightSpd) async {
    leftSpd = leftSpd.clamp(-255, 255);
    rightSpd = rightSpd.clamp(-255, 255);

    // Chap motor (Port 9 / M1)
    final bL = ByteData(2)..setInt16(0, -leftSpd, Endian.little);
    final cmdL = [0xff, 0x55, 0x06, 0x00, 0x02, 0x0a, AppConstants.portLeftMotor, bL.getUint8(0), bL.getUint8(1)];
    await _bleService.sendBytes(cmdL);

    await Future.delayed(const Duration(milliseconds: 5));

    // O'ng motor (Port 10 / M2)
    final bR = ByteData(2)..setInt16(0, rightSpd, Endian.little);
    final cmdR = [0xff, 0x55, 0x06, 0x00, 0x02, 0x0a, AppConstants.portRightMotor, bR.getUint8(0), bR.getUint8(1)];
    await _bleService.sendBytes(cmdR);
  }

  /// OLDINGA
  Future<bool> forward({int? durationSeconds, int? customSpeed}) async {
    // Xavfsizlik tekshiruvi: Oldinda to'siq bo'lsa oldinga yurmaslik
    if (sensorData.isObstacleDanger) {
      emergencyStop("Oldimda to'siq bor. Harakatni boshlamadim.");
      return false;
    }

    final spd = customSpeed ?? currentPwmSpeed;
    sensorData.motionState = RobotMotionState.movingForward;
    setLed(0, 255, 0); // Yashil chiroq
    notifyListeners();

    await _setMotors(spd, spd);

    if (durationSeconds != null && durationSeconds > 0) {
      _durationTimer?.cancel();
      _durationTimer = Timer(Duration(seconds: durationSeconds), () {
        stop();
      });
    }
    return true;
  }

  /// ORQAGA
  Future<void> backward({int? durationSeconds, int? customSpeed}) async {
    final spd = customSpeed ?? currentPwmSpeed;
    sensorData.motionState = RobotMotionState.movingBackward;
    setLed(255, 150, 0); // To'q sariq chiroq
    notifyListeners();

    await _setMotors(-spd, -spd);

    if (durationSeconds != null && durationSeconds > 0) {
      _durationTimer?.cancel();
      _durationTimer = Timer(Duration(seconds: durationSeconds), () {
        stop();
      });
    }
  }

  /// CHAPGA
  Future<void> turnLeft({int? durationSeconds, int? customSpeed}) async {
    final spd = customSpeed ?? currentPwmSpeed;
    sensorData.motionState = RobotMotionState.turningLeft;
    notifyListeners();

    await _setMotors(-spd, spd);

    if (durationSeconds != null && durationSeconds > 0) {
      _durationTimer?.cancel();
      _durationTimer = Timer(Duration(seconds: durationSeconds), () {
        stop();
      });
    }
  }

  /// O'NGGA
  Future<void> turnRight({int? durationSeconds, int? customSpeed}) async {
    final spd = customSpeed ?? currentPwmSpeed;
    sensorData.motionState = RobotMotionState.turningRight;
    notifyListeners();

    await _setMotors(spd, -spd);

    if (durationSeconds != null && durationSeconds > 0) {
      _durationTimer?.cancel();
      _durationTimer = Timer(Duration(seconds: durationSeconds), () {
        stop();
      });
    }
  }

  /// TO'XTASH
  Future<void> stop() async {
    _durationTimer?.cancel();
    sensorData.motionState = RobotMotionState.stopped;
    notifyListeners();
    await _setMotors(0, 0);
  }

  /// RAQS TUSHISH
  Future<void> dance() async {
    sensorData.motionState = RobotMotionState.dancing;
    notifyListeners();

    setLed(0, 0, 255);
    beep(freq: 523, durationMs: 150);
    await turnLeft(durationSeconds: 1);
    await Future.delayed(const Duration(milliseconds: 1100));

    setLed(255, 0, 255);
    beep(freq: 659, durationMs: 150);
    await turnRight(durationSeconds: 1);
    await Future.delayed(const Duration(milliseconds: 1100));

    setLed(0, 255, 255);
    beep(freq: 784, durationMs: 250);
    await forward(durationSeconds: 1);
    await Future.delayed(const Duration(milliseconds: 1100));

    await stop();
    setLed(0, 255, 0);
  }

  /// 5. AVTOMATIK HARAKAT (Obstacle Avoidance Autopilot)
  void toggleAutonomousMode() {
    if (isAutonomousMode) {
      stopAutonomousMode();
    } else {
      startAutonomousMode();
    }
  }

  void startAutonomousMode() {
    isAutonomousMode = true;
    sensorData.motionState = RobotMotionState.autonomousExploration;
    notifyListeners();

    _autoModeTimer?.cancel();
    _autoModeTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (!isAutonomousMode || !_bleService.isConnected) return;

      // Agar oldinda to'siq bo'lsa (< 25 sm)
      if (sensorData.distanceCm < AppConstants.warningObstacleDistanceCm) {
        // 1. To'xtash
        await stop();
        beep(freq: 700, durationMs: 100);
        setLed(255, 100, 0);

        // 2. Chap tomonni tekshirish uchun biroz burilish
        await _setMotors(-140, 140);
        await Future.delayed(const Duration(milliseconds: 400));
        await stop();
        await Future.delayed(const Duration(milliseconds: 150));

        // 3. Agar yo'l ochiq bo'lsa oldinga davom etish
        if (sensorData.distanceCm > AppConstants.warningObstacleDistanceCm) {
          await forward();
        } else {
          // O'ngga burilib ko'rish
          await _setMotors(140, -140);
          await Future.delayed(const Duration(milliseconds: 700));
          await stop();
          await Future.delayed(const Duration(milliseconds: 150));
          await forward();
        }
      } else {
        // Yo'l ochiq bo'lsa oldinga yurish
        if (sensorData.motionState != RobotMotionState.movingForward) {
          await forward();
        }
      }
    });
  }

  void stopAutonomousMode() {
    isAutonomousMode = false;
    _autoModeTimer?.cancel();
    _autoModeTimer = null;
    stop();
    notifyListeners();
  }

  /// Ovoz chiqarish (Buzzer)
  Future<void> beep({int freq = 587, int durationMs = 200}) async {
    final bFreq = ByteData(2)..setUint16(0, freq, Endian.little);
    final bDur = ByteData(2)..setUint16(0, durationMs, Endian.little);
    final bytes = [
      0xff, 0x55, 0x07, 0x00, 0x02, 0x22,
      bFreq.getUint8(0), bFreq.getUint8(1),
      bDur.getUint8(0), bDur.getUint8(1),
    ];
    await _bleService.sendBytes(bytes);
  }

  Future<void> playBuzzerTone(int freq, int durationMs) => beep(freq: freq, durationMs: durationMs);

  /// RGB chiroqlarni yoqish
  Future<void> setLed(int r, int g, int b, {int ledIdx = 0}) async {
    final bytes = [0xff, 0x55, 0x09, 0x00, 0x02, 0x08, 0x00, 0x02, ledIdx, r, g, b];
    await _bleService.sendBytes(bytes);
  }

  Future<void> setRgbLed(int r, int g, int b, {int ledIdx = 0}) => setLed(r, g, b, ledIdx: ledIdx);

  Future<void> stopMotors() => stop();

  /// Tezlik foizini sozlash
  void setSpeedPercentage(int percent) {
    speedPercentage = percent;
    sensorData.currentSpeed = currentPwmSpeed;
    notifyListeners();
  }

  /// Buyruq obyektini bajarish
  Future<void> executeCommand(RobotCommand cmd) async {
    switch (cmd.type) {
      case CommandType.forward:
        await forward(durationSeconds: cmd.durationSeconds, customSpeed: cmd.speed);
        break;
      case CommandType.backward:
        await backward(durationSeconds: cmd.durationSeconds, customSpeed: cmd.speed);
        break;
      case CommandType.left:
        await turnLeft(durationSeconds: cmd.durationSeconds, customSpeed: cmd.speed);
        break;
      case CommandType.right:
        await turnRight(durationSeconds: cmd.durationSeconds, customSpeed: cmd.speed);
        break;
      case CommandType.stop:
        await stop();
        break;
      case CommandType.dance:
        await dance();
        break;
      case CommandType.autonomous:
        toggleAutonomousMode();
        break;
      case CommandType.beep:
        await beep(freq: cmd.freq ?? 587, durationMs: cmd.durationMs ?? 200);
        break;
      case CommandType.setLed:
        if (cmd.r != null && cmd.g != null && cmd.b != null) {
          await setLed(cmd.r!, cmd.g!, cmd.b!);
        }
        break;
      case CommandType.unknown:
        break;
    }
  }

  @override
  void dispose() {
    _sensorPollTimer?.cancel();
    _durationTimer?.cancel();
    _autoModeTimer?.cancel();
    super.dispose();
  }
}
