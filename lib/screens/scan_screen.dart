import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../controllers/bluetooth_controller.dart';

class ScanScreen extends StatefulWidget {
  final BluetoothController controller;
  final String expectedName; // "ESP32_BT"

  const ScanScreen({super.key, required this.controller, required this.expectedName});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => scanning = true);
    await widget.controller.startScan(seconds: 4);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => scanning = false);
  }

  Future<void> _tryConnect(ScanResult r) async {
    final name = r.device.name.isNotEmpty ? r.device.name : r.device.remoteId.id;
    if (name != widget.expectedName) {
      // quick check: show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Este no es el dispositivo de la pulsera.')),
      );
      return;
    }

    // attempt connection
    final ok = await widget.controller.connectToDevice(r, widget.expectedName);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se pudo conectar.')),
      );
      return;
    }

    // success -> go back to home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Conectado correctamente')),
    );

    // return to previous screen
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.controller.foundDevices;
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar dispositivos')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: scanning ? null : _startScan,
            icon: const Icon(Icons.search),
            label: Text(scanning ? 'Buscando...' : 'Buscar dispositivos'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text('No se encontraron dispositivos'))
                : ListView.separated(
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final r = devices[i];
                      final name = r.device.name.isNotEmpty ? r.device.name : r.device.remoteId.id;
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(r.device.remoteId.id),
                        trailing: ElevatedButton(
                          onPressed: () => _tryConnect(r),
                          child: const Text('Conectar'),
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
