import 'package:flutter/material.dart';
import 'main_shell.dart';
import 'theme/dfc_theme.dart';

void main() {
  runApp(const DfcApp());
}

class DfcApp extends StatelessWidget {
  const DfcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DataFight Central',
      debugShowCheckedModeBanner: false,
      theme: buildDfcTheme(),
      routerConfig: dfcRouter,
    );
  }
}
