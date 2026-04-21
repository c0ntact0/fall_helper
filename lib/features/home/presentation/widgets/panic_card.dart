import 'package:flutter/material.dart';
import '../../../../shared/widgets/action_card.dart';

class PanicCard extends StatelessWidget {
  final String caregiverName;
  final bool isInProgress;
  final double progress;
  final VoidCallback onTap;

  const PanicCard({
    super.key,
    required this.caregiverName,
    required this.isInProgress,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      title: 'Pânico',
      status: isInProgress ? 'A fazer chamada para o cuidador' : 'Cuidador: $caregiverName',
      instruction: isInProgress ? '' : 'Pressione para alertar o cuidador',
      backgroundColor: isInProgress ? Colors.green : Colors.lightBlue,
      onTap: onTap,
      bottomChild: isInProgress
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : null,
    );
  }
}
