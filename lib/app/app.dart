import 'package:flutter/material.dart';

import '../core/services/caregiver_google_auth_service.dart';
import '../core/services/drive_folder_service.dart';
import '../core/services/drive_session_store.dart';
import '../core/services/drive_upload_service.dart';
import '../features/drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../features/home/presentation/pages/home_page.dart';

class FallHelperApp extends StatelessWidget {
  FallHelperApp({super.key});

  final CaregiverDriveController caregiverDriveController =
      CaregiverDriveController(
        googleAuthService: CaregiverGoogleAuthServiceImpl(),
        driveFolderService: DriveFolderServiceImpl(),
        driveUploadService: DriveUploadServiceImpl(),
        driveSessionStore: DriveSessionStore(),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(caregiverDriveController: caregiverDriveController),
    );
  }
}
