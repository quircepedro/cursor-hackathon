import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateProcessing();
  }

  Future<void> _simulateProcessing() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    context.pushReplacement(RouteNames.result);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Analysing your voice...', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('This will just take a moment'),
            ],
          ),
        ),
      ),
    );
  }
}
