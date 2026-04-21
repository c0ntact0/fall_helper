import 'package:flutter/material.dart';
import '../../../../shared/widgets/action_card.dart';

class FlashlightCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const FlashlightCard({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      title: 'Lanterna',
      status: isActive ? 'Ativa' : 'Desativa',
      instruction: isActive
          ? 'Pressione para desativar'
          : 'Pressione para ativar',
      backgroundColor: isActive ? Colors.green : Colors.red,
      onTap: onTap,
    );
  }
}
