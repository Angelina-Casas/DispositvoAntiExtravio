import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const PulseraApp());
}

class PulseraApp extends StatelessWidget {
  const PulseraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulsera Antipérdida',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PulseraPage(),
    );
  }
}

class PulseraPage extends StatefulWidget {
  const PulseraPage({super.key});

  @override
  State<PulseraPage> createState() => _PulseraPageState();
}

class _PulseraPageState extends State<PulseraPage> {
  List<ScanResult> dispositivos = [];
  BluetoothDevice? dispositivoSeleccionado;
  bool escaneando = false;
  String estado = "Desconectado";
  Color colorEstado = Colors.redAccent;
  ScanResult? dispositivoElegido;

  // 🔍 Escanear dispositivos BLE
  Future<void> buscarDispositivos() async {
    setState(() {
      dispositivos.clear();
      escaneando = true;
      dispositivoElegido = null;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        dispositivos = results;
      });
    });

    await Future.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();

    setState(() {
      escaneando = false;
    });
  }

  // 🔗 Intentar conectar
  Future<void> conectarDispositivo() async {
    if (dispositivoElegido == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un dispositivo primero")),
      );
      return;
    }

    BluetoothDevice device = dispositivoElegido!.device;

    setState(() {
      estado = "Conectando...";
      colorEstado = Colors.yellow;
    });

    try {
      await device.connect(timeout: const Duration(seconds: 8));
      setState(() {
        dispositivoSeleccionado = device;
        estado = "Conectado con ${device.platformName}";
        colorEstado = Colors.green;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Conectado con ${device.platformName}")),
      );
    } catch (e) {
      setState(() {
        estado = "Error al conectar";
        colorEstado = Colors.redAccent;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ No se pudo conectar: $e")),
      );
    }
  }

  // 🔌 Desconectar
  Future<void> desconectar() async {
    if (dispositivoSeleccionado != null) {
      await dispositivoSeleccionado!.disconnect();
      setState(() {
        dispositivoSeleccionado = null;
        estado = "Desconectado";
        colorEstado = Colors.redAccent;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔴 Dispositivo desconectado")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 25),
              const Text(
                "Pulsera Antipérdida",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 25),

              // Estado de conexión
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.symmetric(horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      dispositivoSeleccionado != null
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: colorEstado,
                      size: 70,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      estado,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorEstado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón de escaneo
                    ElevatedButton.icon(
                      onPressed: escaneando ? null : buscarDispositivos,
                      icon: const Icon(Icons.search),
                      label: Text(
                        escaneando
                            ? "Buscando..."
                            : "Buscar dispositivos Bluetooth",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lista desplegable de dispositivos
                    if (!escaneando && dispositivos.isNotEmpty)
                      DropdownButtonFormField<ScanResult>(
                        value: dispositivoElegido,
                        hint: const Text("Selecciona un dispositivo"),
                        items: dispositivos.map((result) {
                          return DropdownMenuItem(
                            value: result,
                            child: Text(result.device.platformName.isNotEmpty
                                ? result.device.platformName
                                : result.device.remoteId.str),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            dispositivoElegido = value;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Botón de conectar
                    ElevatedButton.icon(
                      onPressed: conectarDispositivo,
                      icon: const Icon(Icons.bluetooth_connected),
                      label: const Text("Conectar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Botón de desconectar
              if (dispositivoSeleccionado != null)
                ElevatedButton.icon(
                  onPressed: desconectar,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: const Text("Desconectar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}