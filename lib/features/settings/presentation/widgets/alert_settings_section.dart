import 'package:flutter/material.dart';

import 'settings_section.dart';

class AlertSettingsSection extends StatelessWidget {
  final bool makePhoneCall;
  final bool sendSms;
  final bool sendGps;
  final bool recordAndSendVideo;
  final double circularRecordingMinutes;
  final ValueChanged<bool> onMakePhoneCallChanged;
  final ValueChanged<bool> onSendSmsChanged;
  final ValueChanged<bool> onSendGpsChanged;
  final ValueChanged<bool> onRecordAndSendVideoChanged;
  final ValueChanged<double> onCircularRecordingMinutesChanged;

  const AlertSettingsSection({
    super.key,
    required this.makePhoneCall,
    required this.sendSms,
    required this.sendGps,
    required this.recordAndSendVideo,
    required this.circularRecordingMinutes,
    required this.onMakePhoneCallChanged,
    required this.onSendSmsChanged,
    required this.onSendGpsChanged,
    required this.onRecordAndSendVideoChanged,
    required this.onCircularRecordingMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              Text('${circularRecordingMinutes.round()} min'),
            ],
          ),
          Slider(
            value: circularRecordingMinutes,
            min: 1,
            max: 30,
            divisions: 29,
            label: '${circularRecordingMinutes.round()} min',
            onChanged: onCircularRecordingMinutesChanged,
          ),
        ],
      ),
    );
  }
}
