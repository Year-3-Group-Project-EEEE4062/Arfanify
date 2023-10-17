import 'package:flutter/material.dart';

class AutonomousPage extends StatelessWidget {
  const AutonomousPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.map_outlined,
          color: Colors.white,
          size: 200,
        ),
      ],
    );
  }
}
