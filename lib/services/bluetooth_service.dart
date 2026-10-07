import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;

  bool isScanning = false;
  bool isConnected = false;
  String connectionStatus = "Ulanmagan";
  List<ScanResult> scanResults = [];

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  final StreamController<List<int>> _incomingDataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get incomingDataStream => _incomingDataController.stream;

  BluetoothService() {
    // Bluetooth holatini kuzatish
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        // Bluetooth yoqilgan
      } else {
        disconnect();
      }
    });
  }

  /// BLE qurilmalarni qidirishni boshlash
  Future<void> startScan({int timeoutSeconds = 8}) async {
    if (isScanning || isConnected) return;

    scanResults.clear();
    isScanning = true;
    connectionStatus = "mBot qidirilmoqda...";
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: timeoutSeconds),
      );

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();

        // Agar Makeblock yoki mBot nomi uchrasa avtomatik ulanish
        for (ScanResult r in results) {
          final name = r.device.platformName;
          if (name.contains("Makeblock") || name.contains("mBot") || name.contains("Codey")) {
            stopScan();
            connectToDevice(r.device);
            break;
          }
        }
      });
    } catch (e) {
      isScanning = false;
      connectionStatus = "Qidiruvda xatolik: $e";
      notifyListeners();
    }
  }

  /// Qidiruvni to'xtatish
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  /// Tanlangan qurilmaga ulanish
  Future<bool> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    connectionStatus = "${device.platformName} ga ulanmoqda...";
    notifyListeners();

    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;

      _connSub = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.connected) {
          isConnected = true;
          connectionStatus = "mBot ulangan";
          await _discoverGattServices(device);
          notifyListeners();
        } else if (state == BluetoothConnectionState.disconnected) {
          isConnected = false;
          connectedDevice = null;
          writeCharacteristic = null;
          notifyCharacteristic = null;
          connectionStatus = "Robot bilan aloqa uzildi";
          notifyListeners();
        }
      });

      return true;
    } catch (e) {
      isConnected = false;
      connectionStatus = "Ulanishda xato: $e";
      notifyListeners();
      return false;
    }
  }

  /// GATT servislarni kashf qilish va Makeblock xarakteristikalarini topish
  Future<void> _discoverGattServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      for (final char in service.characteristics) {
        // Buyruq yuborish kanali (Write)
        if (char.properties.write || char.properties.writeWithoutResponse) {
          writeCharacteristic = char;
        }

        // Sensor ma'lumotlarini qabul qilish kanali (Notify/Read)
        if (char.properties.notify || char.properties.indicate) {
          notifyCharacteristic = char;
          await char.setNotifyValue(true);
          _notifySub = char.onValueReceived.listen((bytes) {
            _incomingDataController.add(bytes);
          });
        }
      }
    }
  }

  /// mBot'ga baytlar yuborish
  Future<bool> sendBytes(List<int> bytes) async {
    if (writeCharacteristic == null || !isConnected) return false;
    try {
      await writeCharacteristic!.write(bytes, withoutResponse: true);
      return true;
    } catch (e) {
      debugPrint("BLE yozishda xato: $e");
      return false;
    }
  }

  /// Aloqani uzish
  Future<void> disconnect() async {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
    }
    connectedDevice = null;
    writeCharacteristic = null;
    notifyCharacteristic = null;
    isConnected = false;
    connectionStatus = "Ulanmagan";
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingDataController.close();
    disconnect();
    super.dispose();
  }
}
