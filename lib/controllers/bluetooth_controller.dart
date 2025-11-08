import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothController {
  List<ScanResult> foundDevices = [];
  BluetoothDevice? connectedDevice;

  // Escanear dispositivos
  Future<List<ScanResult>> scanDevices() async {
    foundDevices.clear();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      foundDevices = results;
    });

    await Future.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();
    return foundDevices;
  }

  // Conectar
  Future<bool> connectDevice(ScanResult result) async {
    try {
      await result.device.connect(timeout: const Duration(seconds: 8));
      connectedDevice = result.device;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Desconectar
  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
  }
}
