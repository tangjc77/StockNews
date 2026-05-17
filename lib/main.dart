import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const StockNewsApp());
}

class StockNewsApp extends StatelessWidget {
  const StockNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '股票披露',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB50005),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
