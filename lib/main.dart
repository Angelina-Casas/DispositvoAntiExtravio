import 'package:flutter/material.dart';
import 'controllers/bluetooth_controller.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PulseraApp());
}

class PulseraApp extends StatelessWidget {
  const PulseraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothController = BluetoothController();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulsera Antiextravio',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(controller: bluetoothController, expectedName: 'ESP32_BT'),
    );
  }
}
