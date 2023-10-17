import 'package:flutter/material.dart';

class CloudBackupPage extends StatelessWidget {
  const CloudBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.cloud_done_outlined,
          color: Colors.white,
          size: 200,
        ),
      ],
    );
  }
}
