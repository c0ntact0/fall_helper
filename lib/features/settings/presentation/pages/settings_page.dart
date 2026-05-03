import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/alert_settings_section.dart';
import '../widgets/caregiver_section.dart';
import '../widgets/user_features_section.dart';

class SettingsPage extends StatefulWidget {
  final LightSensorController? lightSensorController;
  final CaregiverDriveController? caregiverDriveController;

  const SettingsPage({
    super.key,
    this.lightSensorController,
    this.caregiverDriveController,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();

    _controller = SettingsController(storageService: StorageService());

    _controller.addListener(_onControllerChanged);
    widget.caregiverDriveController?.addListener(_onDriveControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    widget.caregiverDriveController?.removeListener(_onDriveControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final errorMessage = _controller.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _controller.clearError();
    }
  }

  void _onDriveControllerChanged() {
    final driveController = widget.caregiverDriveController;
    if (driveController == null) return;

    final errorMessage = driveController.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      driveController.clearError();
    }
  }

  Future<void> _saveAndPop() async {
    final didSave = await _controller.saveSettings();

    if (!mounted) return;

    if (didSave) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildDriveSection() {
    final driveController = widget.caregiverDriveController;

    if (driveController == null) {
      return const SizedBox.shrink();
    }

    final session = driveController.session;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Drive do cuidador',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              session.hasLinkedAccount
                  ? 'Ligado a: ${session.caregiverGoogleEmail}'
                  : 'Não ligado',
            ),
            if (session.rootFolderId != null) ...[
              const SizedBox(height: 8),
              const Text('Pasta configurada: Fall Helper Alerts'),
            ],
            const SizedBox(height: 12),
            if (driveController.isAuthorizing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: session.hasLinkedAccount
                          ? null
                          : () async {
                              await driveController.linkCaregiverDrive();
                            },
                      child: const Text('Ligar Google Drive'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: session.hasLinkedAccount
                          ? () async {
                              await driveController.unlinkCaregiverDrive();
                            }
                          : null,
                      child: const Text('Desligar'),
                    ),
                  ),
                ],
              ),
            if (driveController.isUploading) ...[
              const SizedBox(height: 12),
              const Text('Upload em curso...'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller,
        if (widget.lightSensorController != null) widget.lightSensorController!,
        if (widget.caregiverDriveController != null)
          widget.caregiverDriveController!,
      ]),
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _saveAndPop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Configuração'),
              leading: IconButton(
                onPressed: _saveAndPop,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: SafeArea(
              child: Form(
                key: _controller.formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CaregiverSection(
                      nameController: _controller.caregiverNameController,
                      emailController: _controller.caregiverEmailController,
                      phoneController: _controller.caregiverPhoneController,
                      pinController: _controller.pinController,
                      validateName: (value) =>
                          AppValidators.requiredField(value, fieldName: 'Nome'),
                      validateEmail: AppValidators.email,
                      validatePhone: AppValidators.phone,
                      validatePin: AppValidators.pin4Digits,
                    ),
                    const SizedBox(height: 16),
                    _buildDriveSection(),
                    const SizedBox(height: 16),
                    AlertSettingsSection(
                      makePhoneCall: _controller.makePhoneCall,
                      sendSms: _controller.sendSms,
                      sendGps: _controller.sendGps,
                      recordAndSendVideo: _controller.recordAndSendVideo,
                      circularRecordingSeconds:
                          _controller.circularRecordingSeconds,
                      isSendSmsForced: _controller.isSendSmsForced,
                      onMakePhoneCallChanged: _controller.setMakePhoneCall,
                      onSendSmsChanged: _controller.setSendSms,
                      onSendGpsChanged: _controller.setSendGps,
                      onRecordAndSendVideoChanged:
                          _controller.setRecordAndSendVideo,
                      onCircularRecordingSecondsChanged:
                          _controller.setCircularRecordingSeconds,
                    ),
                    const SizedBox(height: 16),
                    UserFeaturesSection(
                      showFallDetectionButton:
                          _controller.showFallDetectionButton,
                      showPanicButton: _controller.showPanicButton,
                      enableAutomaticFlashlightMode:
                          _controller.enableAutomaticFlashlightMode,
                      flashlightDarknessThresholdLux:
                          _controller.flashlightDarknessThresholdLux,
                      currentLux: widget.lightSensorController?.currentLux,
                      onShowFallDetectionButtonChanged:
                          _controller.setShowFallDetectionButton,
                      onShowPanicButtonChanged: _controller.setShowPanicButton,
                      onEnableAutomaticFlashlightModeChanged:
                          _controller.setEnableAutomaticFlashlightMode,
                      onFlashlightDarknessThresholdLuxChanged:
                          _controller.setFlashlightDarknessThresholdLux,
                    ),
                    if (_controller.isSaving) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
