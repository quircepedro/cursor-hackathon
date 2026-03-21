import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/providers/goals_provider.dart';

class GoalsOnboardingScreen extends ConsumerStatefulWidget {
  const GoalsOnboardingScreen({super.key});

  @override
  ConsumerState<GoalsOnboardingScreen> createState() =>
      _GoalsOnboardingScreenState();
}

class _GoalsOnboardingScreenState extends ConsumerState<GoalsOnboardingScreen> {
  final _controller = TextEditingController();
  final _goals = <String>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addGoal() {
    final text = _controller.text.trim();
    if (text.isEmpty || _goals.length >= 4) return;
    setState(() {
      _goals.add(text);
      _controller.clear();
    });
  }

  void _removeGoal(int index) {
    setState(() => _goals.removeAt(index));
  }

  Future<void> _submit() async {
    if (_goals.length < 2 || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(goalsProvider.notifier);
      for (final title in _goals) {
        await notifier.addGoal(title);
      }
      if (mounted) context.go(RouteNames.home);
    } catch (e) {
      if (mounted) {
        final message = switch (e) {
          DioException(:final error) when error is AppException => error.message,
          AppException(:final message) => message,
          _ => e.toString(),
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Que quieres conseguir?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Define entre 2 y 4 objetivos personales. La IA analizara tu progreso diario.',
                style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Ej: Ir al gimnasio',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF151518),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                        ),
                      ),
                      onSubmitted: (_) => _addGoal(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _goals.length < 4 ? _addGoal : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _goals.length < 4
                            ? const Color(0xFF6366F1)
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goals list
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151518),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _goals[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _removeGoal(index),
                            child: Icon(Icons.close,
                                color: Colors.grey[600], size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Status text
              if (_goals.isNotEmpty && _goals.length < 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Anade al menos ${2 - _goals.length} objetivo${_goals.length == 1 ? "" : "s"} mas',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),

              // Continue button
              ElevatedButton(
                onPressed: _goals.length >= 2 && !_isSubmitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[800],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Continuar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
