import 'package:flutter/material.dart';

class PatientFooterPage extends StatefulWidget {
  const PatientFooterPage({super.key});

  @override
  State<PatientFooterPage> createState() => _PatientFooterPageState();
}

class _PatientFooterPageState extends State<PatientFooterPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA), // Soft Whisper White
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () async {},
            icon: Icon(
              Icons.home,
              size: 30,
              color: const Color(0xFF6B9AC4),
            ), // Soft Azure
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.event_note_rounded,
              size: 30,
              color: const Color(0xFF6B9AC4),
            ), // Soft Azure
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.message_outlined,
              size: 30,
              color: const Color(0xFF6B9AC4),
            ), // Soft Azure
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.event_note_rounded,
              size: 30,
              color: const Color(0xFF6B9AC4),
            ), // Soft Azure
          ),
        ],
      ),
    );
  }
}
