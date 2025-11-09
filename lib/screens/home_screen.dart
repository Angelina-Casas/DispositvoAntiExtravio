import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../controllers/bluetooth_controller.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final BluetoothController controller;
  final String expectedName;
  const HomeScreen({super.key, required this.controller, required this.expectedName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterLocalNotificationsPlugin _notifier;
  KidState currentState = KidState.unknown;
  StreamSubscription<KidState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _stateSub = widget.controller.stateStream.listen((s) {
      setState(() => currentState = s);
      _applySideEffects(s);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    _notifier = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifier.initialize(initSettings);
  }

  Future<void> _showSoundNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alert_channel', 'Alertas', channelDescription: 'Alertas de la pulsera',
      importance: Importance.high, priority: Priority.high, playSound: true);
    const details = NotificationDetails(android: androidDetails);
    await _notifier.show(0, title, body, details);
  }

  Future<void> _applySideEffects(KidState s) async {
    if (s == KidState.gettingAway) {
      // Play sound only
      await _showSoundNotification('Cuidado', 'El niño se está alejando. Por favor supervisar.');
    } else if (s == KidState.veryFar) {
      // Play sound + vibrate
      await _showSoundNotification('¡ALERTA!', 'Niño muy lejos. Buscar ahora.');
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 800);
      }
    }
  }

  Color _stateColor() {
    switch (currentState) {
      case KidState.near:
        return Colors.green;
      case KidState.gettingAway:
        return Colors.orange;
      case KidState.veryFar:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _stateText() {
    switch (currentState) {
      case KidState.near:
        return 'El niño está cerca';
      case KidState.gettingAway:
        return 'El niño se está alejando. Por favor supervisar.';
      case KidState.veryFar:
        return '¡ALERTA! Niño muy lejos. Buscar ahora.';
      default:
        return 'Desconectado / esperando datos';
    }
  }

  Future<void> _openScan() async {
    // open scan screen. if user connected, we pop with true
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(controller: widget.controller, expectedName: widget.expectedName),
      ),
    );

    // If connected (res == true) we can update UI; controller.stateStream will update state
    if (res == true) {
      setState(() {});
    }
  }

  Future<void> _disconnect() async {
    await widget.controller.disconnect();
    setState(() => currentState = KidState.unknown);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔴 Dispositivo desconectado')));
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.controller.connectedDevice != null;
    final deviceName = connected
        ? (widget.controller.connectedDevice!.name.isNotEmpty
            ? widget.controller.connectedDevice!.name
            : widget.controller.connectedDevice!.id)
        : 'Ninguno';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dispositivo Antiextravio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8BBCCC), Color.fromARGB(255, 171, 217, 255)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 120),

              // Estado y dispositivo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: _stateColor(),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      connected ? 'Conectado a: $deviceName' : 'Sin conexión',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stateText(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: _stateColor()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _openScan,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar dispositivo'),
                  ),
                  const SizedBox(width: 12),
                  if (connected)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: _disconnect,
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Desconectar'),
                    ),
                ],
              ),

              const Spacer(),

              // Indicador visual grande
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  color: _stateColor().withOpacity(.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.child_care, size: 70, color: Colors.white),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
