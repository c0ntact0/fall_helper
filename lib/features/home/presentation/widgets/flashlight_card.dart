import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_card.dart';

class FlashlightCard extends StatelessWidget {
  final bool isActive;
  final bool isAvailable;
  final bool autoModeEnabled;
  final bool manualOverrideActive;
  final VoidCallback onTap;

  const FlashlightCard({
    super.key,
    required this.isActive,
    required this.isAvailable,
    required this.autoModeEnabled,
    required this.manualOverrideActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String status;
    final String instruction;
    final Color backgroundColor;

    if (!isAvailable) {
      status = 'Indisponível';
      instruction = 'Sem suporte no dispositivo';
      backgroundColor = Colors.grey;
    } else {
      if (autoModeEnabled) {
        status = isActive
            ? (manualOverrideActive ? 'Ativa (Manual)' : 'Ativa (Auto)')
            : (manualOverrideActive ? 'Desativa (Manual)' : 'Desativa (Auto)');
      } else {
        status = isActive ? 'Ativa' : 'Desativa';
      }

      if (autoModeEnabled && manualOverrideActive) {
        instruction = 'Automático temporariamente suspenso';
      } else {
        instruction = isActive
            ? 'Pressione para desativar'
            : 'Pressione para ativar';
      }

      backgroundColor = isActive ? Colors.amber : Colors.red;
    }

    return ActionCard(
      title: 'Lanterna',
      status: status,
      instruction: instruction,
      backgroundColor: backgroundColor,
      onTap: isAvailable ? onTap : () {},
    );
  }
}
