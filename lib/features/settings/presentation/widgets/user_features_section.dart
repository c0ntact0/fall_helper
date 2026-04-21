import 'package:flutter/material.dart';

import 'settings_section.dart';

class UserFeaturesSection extends StatelessWidget {
  final bool showFallDetectionButton;
  final bool showPanicButton;
  final ValueChanged<bool> onShowFallDetectionButtonChanged;
  final ValueChanged<bool> onShowPanicButtonChanged;

  const UserFeaturesSection({
    super.key,
    required this.showFallDetectionButton,
    required this.showPanicButton,
    required this.onShowFallDetectionButtonChanged,
    required this.onShowPanicButtonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Funcionalidades do utente',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar botão de ligar e desligar alertas'),
            value: showFallDetectionButton,
            onChanged: onShowFallDetectionButtonChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar botão de pânico'),
            value: showPanicButton,
            onChanged: onShowPanicButtonChanged,
          ),
        ],
      ),
    );
  }
}
