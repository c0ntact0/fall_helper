import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_card.dart';

class FlashlightCard extends StatelessWidget {
  final bool isActive;
  final bool isAvailable;
  final VoidCallback onTap;

  const FlashlightCard({
    super.key,
    required this.isActive,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      title: 'Lanterna',
      status: !isAvailable ? 'Indisponível' : (isActive ? 'Ativa' : 'Desativa'),
      instruction: !isAvailable
          ? 'Sem suporte no dispositivo'
          : (isActive ? 'Pressione para desativar' : 'Pressione para ativar'),
      backgroundColor: !isAvailable
          ? Colors.grey
          : (isActive ? Colors.amber : Colors.red),
      onTap: isAvailable ? onTap : () {},
    );
  }
}
