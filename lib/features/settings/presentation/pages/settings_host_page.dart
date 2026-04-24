import 'package:flutter/material.dart';

import '../../../auth/presentation/pages/pin_login_page.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';

class SettingsHostPage extends StatelessWidget {
  final LightSensorController lightSensorController;

  const SettingsHostPage({super.key, required this.lightSensorController});

  @override
  Widget build(BuildContext context) {
    return PinLoginPage(lightSensorController: lightSensorController);
  }
}
