import 'package:flutter/material.dart';
import '../widgets/nasa_apod_widget.dart';

class NasaScreen extends StatelessWidget {
  const NasaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NASA Space Center')),
      body: ListView(
        children: const [
          NasaApodWidget(),
          // Add more NASA widgets here (e.g., Mars Rover, news)
        ],
      ),
    );
  }
}
