import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../auth/presentation/pages/pin_login_page.dart';
import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';

class SettingsHostPage extends StatelessWidget {
  final LightSensorController lightSensorController;
  final CaregiverDriveController caregiverDriveController;
  final AppLogger logger;

  const SettingsHostPage({
    super.key,
    required this.lightSensorController,
    required this.caregiverDriveController,
    required this.logger,
  });

  @override
  Widget build(BuildContext context) {
    return PinLoginPage(
      lightSensorController: lightSensorController,
      caregiverDriveController: caregiverDriveController,
      logger: logger,
    );
  }
}
