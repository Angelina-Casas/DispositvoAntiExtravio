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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BBCCC),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1FAFA),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: bluetoothController, expectedName: 'ESP32_BT'),
    );
  }
}
