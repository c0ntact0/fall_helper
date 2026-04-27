import 'package:flutter/material.dart';

import 'settings_section.dart';

class AlertSettingsSection extends StatelessWidget {
  final bool makePhoneCall;
  final bool sendSms;
  final bool sendGps;
  final bool recordAndSendVideo;
  final int circularRecordingSeconds;
  final ValueChanged<bool> onMakePhoneCallChanged;
  final ValueChanged<bool> onSendSmsChanged;
  final ValueChanged<bool> onSendGpsChanged;
  final ValueChanged<bool> onRecordAndSendVideoChanged;
  final ValueChanged<int> onCircularRecordingSecondsChanged;

  const AlertSettingsSection({
    super.key,
    required this.makePhoneCall,
    required this.sendSms,
    required this.sendGps,
    required this.recordAndSendVideo,
    required this.circularRecordingSeconds,
    required this.onMakePhoneCallChanged,
    required this.onSendSmsChanged,
    required this.onSendGpsChanged,
    required this.onRecordAndSendVideoChanged,
    required this.onCircularRecordingSecondsChanged,
  });

  static const List<int> _allowedValues = [30, 60, 90, 120];

  String _formatSeconds(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (remainingSeconds == 0) {
      return '$minutes min';
    }

    return '$minutes min ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _allowedValues.indexOf(circularRecordingSeconds);
    final sliderIndex = currentIndex >= 0 ? currentIndex.toDouble() : 1.0;

    return SettingsSection(
      title: 'Configuração de alertas',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fazer chamada'),
            value: makePhoneCall,
            onChanged: onMakePhoneCallChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enviar SMS'),
            value: sendSms,
            onChanged: onSendSmsChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enviar localização GPS'),
            value: sendGps,
            onChanged: onSendGpsChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gravar e enviar vídeo'),
            value: recordAndSendVideo,
            onChanged: onRecordAndSendVideoChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Tempo gravação circular')),
              Text(_formatSeconds(circularRecordingSeconds)),
            ],
          ),
          Slider(
            value: sliderIndex,
            min: 0,
            max: (_allowedValues.length - 1).toDouble(),
            divisions: _allowedValues.length - 1,
            label: _formatSeconds(circularRecordingSeconds),
            onChanged: (value) {
              onCircularRecordingSecondsChanged(_allowedValues[value.round()]);
            },
          ),
        ],
      ),
    );
  }
}
