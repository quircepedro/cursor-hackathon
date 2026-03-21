import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/goals_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addGoal() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(goalsProvider.notifier).addGoal(text);
    _controller.clear();
  }

  Future<void> _removeGoal(String id) async {
    await ref.read(goalsProvider.notifier).removeGoal(id);
  }

  Future<void> _editGoal(String id, String currentTitle) async {
    final editController = TextEditingController(text: currentTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('Editar objetivo',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          maxLength: 100,
          decoration: InputDecoration(
            counterStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
    editController.dispose();

    if (result != null && result.isNotEmpty && result != currentTitle) {
      await ref.read(goalsProvider.notifier).updateGoal(id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final goals = goalsState.goals;
    final canAdd = goals.length < 4;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mis Objetivos',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${goals.length}/4 objetivos activos',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Add new goal
              if (canAdd) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Nuevo objetivo...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF151518),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                        onSubmitted: (_) => _addGoal(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addGoal,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Goals list
              Expanded(
                child: ListView.separated(
                  itemCount: goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final canRemove = goals.length > 2;
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
                              color:
                                  const Color(0xFF6366F1).withValues(alpha: 0.15),
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
                              goal.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _editGoal(goal.id, goal.title),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.edit_outlined,
                                  color: Colors.grey[500], size: 18),
                            ),
                          ),
                          if (canRemove)
                            GestureDetector(
                              onTap: () => _removeGoal(goal.id),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(Icons.close,
                                    color: Colors.grey[600], size: 18),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
