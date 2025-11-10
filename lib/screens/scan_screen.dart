import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../controllers/bluetooth_controller.dart';

class ScanScreen extends StatefulWidget {
  final BluetoothController controller;
  final String expectedName;

  const ScanScreen({super.key, required this.controller, required this.expectedName});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsThenScan();
  }

  Future<void> _requestPermissionsThenScan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    await ensureBluetoothOn();
    await ensureGpsOn();
    _startScan();
  }

  Future<void> ensureGpsOn() async {
    Location location = Location();
    bool enabled = await location.serviceEnabled();
    if (!enabled) await location.requestService();
  }

  Future<void> ensureBluetoothOn() async {
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn(); 
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Este no es el dispositivo correcto.')),
      );
      return;
    }

    final ok = await widget.controller.connectToDevice(r, widget.expectedName);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se pudo conectar.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Conectado correctamente')),
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.controller.foundDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Dispositivos'), 
        centerTitle: true,
        backgroundColor:const Color(0xFF8BBCCC),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFD6E9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: scanning ? null : _startScan,
              icon: const Icon(Icons.search),
              label: Text(scanning ? 'Buscando...' : 'Actualizar lista'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: const Color(0xFF8BBCCC),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            if (scanning)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),

            Expanded(
              child: devices.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron dispositivos',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (_, i) {
                        final r = devices[i];
                        final name = r.device.name.isNotEmpty
                            ? r.device.name
                            : r.device.remoteId.id;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth, color: Color.fromARGB(255, 3, 123, 179), size: 32),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(r.device.remoteId.id),
                            trailing: ElevatedButton(
                              onPressed: () => _tryConnect(r),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Conectar'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
