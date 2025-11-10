import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum KidState { unknown, near, gettingAway, veryFar, sos }

class BluetoothController {
  final List<ScanResult> foundDevices = [];
  BluetoothDevice? connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _charSub;
  final StreamController<KidState> _stateController = StreamController.broadcast();
  Stream<KidState> get stateStream => _stateController.stream;

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

  /// Connects ONLY if the device name matches expectedName.
  /// Returns true if connected, false otherwise.
  Future<bool> connectToDevice(ScanResult result, String expectedName) async {
    final device = result.device;

    final name = device.name.isNotEmpty ? device.name : result.device.remoteId.id;
    if (name != expectedName) {
      // not the expected device
      return false;
    }

    try {
      await device.connect(timeout: const Duration(seconds: 8), autoConnect: false);
    } catch (e) {
      // ignore if already connected or throw other
    }

    connectedDevice = device;

    // discover services and subscribe to first NOTIFY characteristic
    List<BluetoothService> services = await device.discoverServices();
    BluetoothCharacteristic? notifyChar;

    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.properties.notify == true) {
          notifyChar = c;
          break;
        }
      }
      if (notifyChar != null) break;
    }

    if (notifyChar != null) {
      // enable notifications
      try {
        await notifyChar.setNotifyValue(true);
        _charSub?.cancel();
        _charSub = notifyChar.value.listen((raw) {
          if (raw.isEmpty) return;
          // try parse as ascii/utf8 number or single byte
          String txt;
          try {
            txt = utf8.decode(raw);
          } catch (e) {
            txt = raw.first.toString();
          }
          txt = txt.trim();
          _handleIncoming(txt);
        });
      } catch (e) {
        // if setNotifyValue fails, still ok
      }
    } else {
      // no notify char: try to periodically read RSSI? we won't implement here
    }

    return true;
  }

  void _handleIncoming(String txt) {
    if (txt.isEmpty) return;
    final token = txt[0];

    if (token == 'S') {
      // BOTON SOS PRESIONADO
      _stateController.add(KidState.sos);
      return;
    }

    switch (token) {
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
    _charSub = null;
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (e) {}
      connectedDevice = null;
    }
    _stateController.add(KidState.unknown);
  }

  void dispose() {
    _scanSub?.cancel();
    _charSub?.cancel();
    _stateController.close();
  }
}
