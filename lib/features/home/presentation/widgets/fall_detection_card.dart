import 'package:flutter/material.dart';
import '../../../../shared/widgets/action_card.dart';

class FallDetectionCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final bool isDisabled;
  final String? disabledReason;

  const FallDetectionCard({
    super.key,
    required this.isActive,
    required this.onTap,
    required this.isDisabled,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final String status;
    final String instruction;
    final Color backgroundColor;

    if (isDisabled) {
      status = 'Indisponível';
      instruction = disabledReason ?? 'Função temporariamente desativada';
      backgroundColor = Colors.grey;
    } else {
      status = isActive ? 'Ativa' : 'Parada';
      instruction = isActive
          ? 'Pressione para parar'
          : 'Pressione para ativar';
      backgroundColor = isActive ? Colors.green : Colors.red;
    }
    return ActionCard(
      title: 'Deteta Quedas',
      status: status,
      instruction: instruction,
      backgroundColor: backgroundColor,
      onTap: isDisabled ? () {} : onTap,
    );
  }
}
