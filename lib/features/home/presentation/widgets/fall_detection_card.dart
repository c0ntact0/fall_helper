import 'package:flutter/material.dart';
import '../../../../shared/widgets/action_card.dart';

class FallDetectionCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const FallDetectionCard({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      title: 'Deteta Quedas',
      status: isActive ? 'Ativo' : 'Parado',
      instruction: isActive ? 'Pressione para parar' : 'Pressione para ativar',
      backgroundColor: isActive ? Colors.green : Colors.red,
      onTap: onTap,
    );
  }
}
