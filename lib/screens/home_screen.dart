import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pulsera Antipérdida"),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.bluetooth_searching),
          label: const Text("Buscar Dispositivo"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            );
          },
        ),
      ),
    );
  }
}
