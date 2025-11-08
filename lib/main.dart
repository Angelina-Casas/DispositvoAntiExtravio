import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PulseraApp());
}

class PulseraApp extends StatelessWidget {
  const PulseraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}