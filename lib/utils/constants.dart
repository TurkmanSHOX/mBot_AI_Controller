import 'package:flutter/material.dart';

class AppConstants {
  // Ranglar
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color accentColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color backgroundColor = Color(0xFF0F172A);
  static const Color cardColor = Color(0xFF1E293B);

  // Bluetooth GATT UUIDs (Makeblock mBot / Codey Rocky)
  static const String makeblockServiceUuid = "ffe1";
  static const String makeblockWriteCharUuid = "ffe3";
  static const String makeblockReadCharUuid = "ffe2";

  // Standart xavfsizlik chegaralari
  static const double minObstacleDistanceCm = 15.0;
  static const double warningObstacleDistanceCm = 25.0;

  // mBot Portlar
  static const int portUltrasonic = 3;
  static const int portLineFollower = 2;
  static const int portLeftMotor = 9;
  static const int portRightMotor = 10;

  // Makeblock Protokol Headerlari
  static const int headerByte1 = 0xFF;
  static const int headerByte2 = 0x55;

  // Sukut bo'yicha motor tezligi
  static const int defaultSpeed = 150;
}
