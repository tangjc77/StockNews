import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

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
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
