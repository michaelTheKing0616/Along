import 'package:flutter/material.dart';

void main() {
  runApp(const AlongRiderApp());
}

class AlongRiderApp extends StatelessWidget {
  const AlongRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Along Rider')),
      ),
    );
  }
}
