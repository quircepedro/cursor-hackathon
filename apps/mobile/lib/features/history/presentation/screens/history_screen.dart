import 'package:flutter/material.dart';

import '../../../../shared/widgets/feedback/empty_state_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const EmptyStateWidget(
        title: 'No entries yet',
        subtitle: 'Your voice journals will appear here after you record one.',
        icon: Icons.history_rounded,
      ),
    );
  }
}
