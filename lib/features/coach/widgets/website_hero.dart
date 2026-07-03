import 'package:flutter/material.dart';

class WebsiteHero extends StatelessWidget {
  const WebsiteHero({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: const Center(
        child: Text(
          'SMART COACH DASHBOARD',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
