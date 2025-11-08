import 'package:flutter/material.dart';
import 'package:flutter_application_2/controllers/bluetooth_controller.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BluetoothController bluetooth = BluetoothController();
  bool scanning = false;

  void startScan() async {
    setState(() => scanning = true);
    await bluetooth.scanDevices();
    setState(() => scanning = false);
  }

  void connect(ScanResult result) async {
    bool ok = await bluetooth.connectDevice(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "✅ Conectado" : "❌ Error al conectar")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar Dispositivo")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: scanning ? null : startScan,
            child: Text(scanning ? "Buscando..." : "Buscar Dispositivos"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bluetooth.foundDevices.length,
              itemBuilder: (_, i) {
                final d = bluetooth.foundDevices[i];
                return ListTile(
                  title: Text(d.device.platformName.isNotEmpty
                      ? d.device.platformName
                      : d.device.remoteId.str),
                  subtitle: Text(d.device.remoteId.str),
                  trailing: ElevatedButton(
                    child: const Text("Conectar"),
                    onPressed: () => connect(d),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
