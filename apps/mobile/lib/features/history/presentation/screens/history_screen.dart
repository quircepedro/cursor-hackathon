import 'package:flutter/material.dart';

import '../../../../shared/widgets/feedback/empty_state_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const EmptyStateWidget(
        title: 'No entries yet',
        subtitle: 'Your voice journals will appear here after you record one.',
        icon: Icons.history_rounded,
      ),
    );
  }
}
