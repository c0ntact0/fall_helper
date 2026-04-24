import 'package:flutter/material.dart';

import 'settings_section.dart';

class UserFeaturesSection extends StatelessWidget {
  final bool showFallDetectionButton;
  final bool showPanicButton;
  final bool enableAutomaticFlashlightMode;
  final double flashlightDarknessThresholdLux;
  final int? currentLux;
  final ValueChanged<bool> onShowFallDetectionButtonChanged;
  final ValueChanged<bool> onShowPanicButtonChanged;
  final ValueChanged<bool> onEnableAutomaticFlashlightModeChanged;
  final ValueChanged<double> onFlashlightDarknessThresholdLuxChanged;

  const UserFeaturesSection({
    super.key,
    required this.showFallDetectionButton,
    required this.showPanicButton,
    required this.enableAutomaticFlashlightMode,
    required this.flashlightDarknessThresholdLux,
    required this.currentLux,
    required this.onShowFallDetectionButtonChanged,
    required this.onShowPanicButtonChanged,
    required this.onEnableAutomaticFlashlightModeChanged,
    required this.onFlashlightDarknessThresholdLuxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Funcionalidades do utente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ativar modo automático da lanterna'),
            value: enableAutomaticFlashlightMode,
            onChanged: onEnableAutomaticFlashlightModeChanged,
          ),
          if (enableAutomaticFlashlightMode) ...[
            const SizedBox(height: 8),
            Text(
              currentLux != null
                  ? 'Lux atual: $currentLux'
                  : 'Lux atual: sem leitura',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Limiar de escuridão da lanterna')),
                Text(
                  '${flashlightDarknessThresholdLux.toStringAsFixed(0)} lux',
                ),
              ],
            ),
            Slider(
              value: flashlightDarknessThresholdLux,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${flashlightDarknessThresholdLux.toStringAsFixed(0)} lux',
              onChanged: onFlashlightDarknessThresholdLuxChanged,
            ),
          ],
        ],
      ),
    );
  }
}
