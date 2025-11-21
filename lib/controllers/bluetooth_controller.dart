import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum KidState { unknown, near, gettingAway, veryFar, sos }

class BluetoothController {
  final List<ScanResult> foundDevices = [];
  BluetoothDevice? connectedDevice;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _charSub;
  Timer? _rssiTimer;

  final StreamController<KidState> _stateController = StreamController.broadcast();
  Stream<KidState> get stateStream => _stateController.stream;

  final StreamController<double> _distanceController = StreamController.broadcast();
  Stream<double> get distanceStream => _distanceController.stream;

  BluetoothCharacteristic? _notifyChar;

  Future<void> startScan({int seconds = 4}) async {
    foundDevices.clear();
    await FlutterBluePlus.startScan(timeout: Duration(seconds: seconds));

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      foundDevices
        ..clear()
        ..addAll(results);
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
  }

  Future<bool> connectToDevice(ScanResult result, String expectedName) async {
    final device = result.device;
    final name = device.name.isNotEmpty ? device.name : result.device.remoteId.id;

    if (name != expectedName) return false;

    try {
      await device.connect(timeout: const Duration(seconds: 8), autoConnect: false);
    } catch (e) {
      // ignorar
    }

    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    _notifyChar = null;

    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.notify) {
          _notifyChar ??= c;
        }
      }
    }

    if (_notifyChar != null) {
      try {
        await _notifyChar!.setNotifyValue(true);

        _charSub?.cancel();

        _charSub = _notifyChar!.value.listen((raw) {
          if (raw.isEmpty) return;

          String txt;
          try {
            txt = utf8.decode(raw).trim();
          } catch (_) {
            txt = raw.first.toString();
          }
          _handleIncoming(txt);
        });
      } catch (_) {
        // ignorar
      }
    }

    return true;
  }

  double _estimateDistance(int rssi) {
    const int txPower = -59;
    const double n = 2.0;
    return pow(10, ((txPower - rssi) / (10 * n))).toDouble();
  }

  void _handleIncoming(String txt) {
    if (txt.isEmpty) return;

    if (txt.startsWith("-")) {
      final int rssi = int.tryParse(txt) ?? -90;
      final double distance = _estimateDistance(rssi);

      _distanceController.add(distance);

      if (distance > 5) {
        _stateController.add(KidState.veryFar);
      } else if (distance > 3) {
        _stateController.add(KidState.gettingAway);
      } else {
        _stateController.add(KidState.near);
      }
      return;
    }

    if (txt.startsWith("S")) {
      _stateController.add(KidState.sos);
      return;
    }

    switch (txt[0]) {
      case '0':
        _stateController.add(KidState.near);
        break;
      case '1':
        _stateController.add(KidState.gettingAway);
        break;
      case '2':
        _stateController.add(KidState.veryFar);
        break;
      default:
        _stateController.add(KidState.unknown);
    }
  }

  Future<void> disconnect() async {
    _charSub?.cancel();
    _rssiTimer?.cancel();
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
    }
    connectedDevice = null;
    _notifyChar = null;
    _stateController.add(KidState.unknown);
  }

  void dispose() {
    _scanSub?.cancel();
    _charSub?.cancel();
    _rssiTimer?.cancel();
    _stateController.close();
    _distanceController.close();
  }
}
