import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/alert_settings_section.dart';
import '../widgets/caregiver_section.dart';
import '../widgets/user_features_section.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/services/location_service.dart';

class SettingsPage extends StatefulWidget {
  final LightSensorController? lightSensorController;
  final CaregiverDriveController? caregiverDriveController;
  final AppLogger? logger;

  const SettingsPage({
    super.key,
    this.lightSensorController,
    this.caregiverDriveController,
    this.logger,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
  
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;
  late final LocationService _locationService;
  late final _logger = widget.logger!;

  @override
  void initState() {
    super.initState();

    _locationService = LocationService();
    _controller = SettingsController(
      storageService: StorageService(),
      logger: widget.logger!);

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

  Future<void> _ensureBackgroundLocationForAlerts() async {
    final status = await _locationService.ensureBackgroundLocationPermission();

    if (!mounted) return;

    switch (status) {
      case BackgroundLocationStatus.ready:
        return;

      case BackgroundLocationStatus.locationServicesDisabled:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Os serviços de localização estão desligados. '
              'Sem isso, o envio da localização pode falhar.',
            ),
          ),
        );
        await _locationService.openLocationSettings();
        return;

      case BackgroundLocationStatus.needsForegroundPermission:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A permissão de localização foi negada. '
              'Sem localização, o alerta pode ser enviado sem coordenadas.',
            ),
          ),
        );
        return;

      case BackgroundLocationStatus.needsBackgroundPermission:
        final bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Permissão de localização em segundo plano'),
              content: const Text(
                'Para enviar a localização quando a aplicação não estiver em '
                'primeiro plano, o FallHelper precisa de acesso à localização '
                'sempre. Sem essa permissão, o alerta pode ser enviado sem '
                'localização.\n\n'
                'Deseja abrir as definições da aplicação agora?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Agora não'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abrir definições'),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          await _locationService.openAppSettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A aplicação continuará a funcionar, mas poderá não conseguir '
                'enviar a localização se estiver em segundo plano.',
              ),
            ),
          );
        }
        return;

      case BackgroundLocationStatus.deniedForever:
        final bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Permissão negada permanentemente'),
              content: const Text(
                'A permissão de localização foi negada permanentemente. '
                'Para permitir o envio da localização com a app em segundo plano, '
                'é necessário alterar a permissão nas definições da aplicação.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Agora não'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abrir definições'),
                ),
              ],
            );
          },
        );

        if (openSettings == true) {
          await _locationService.openAppSettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sem a permissão "sempre", o envio da localização pode falhar '
                'quando a aplicação não estiver em primeiro plano.',
              ),
            ),
          );
        }
        return;
    }
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
    await _logger.logUserAction(module: 'settings_page', action: 'arrow_back_pressed');

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
                            await _logger.logUserAction(
                                module: 'settings_page',
                                action: 'link_caregiver_drive_pressed',
                              );
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
                            await _logger.logUserAction(
                                module: 'settings_page',
                                action: 'unlink_caregiver_drive_pressed',
                              );
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
                      logger: _logger,
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
                      onSendGpsChanged: (value) async {
                        _controller.setSendGps(value);

                        if (value) {
                          await _ensureBackgroundLocationForAlerts();
                        }
                      },
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
                      showSimulateFallButton:
                          _controller.showSimulateFallButton,
                      enableAutomaticFlashlightMode:
                          _controller.enableAutomaticFlashlightMode,
                      flashlightDarknessThresholdLux:
                          _controller.flashlightDarknessThresholdLux,
                      currentLux: widget.lightSensorController?.currentLux,
                      onShowFallDetectionButtonChanged:
                          _controller.setShowFallDetectionButton,
                      onShowPanicButtonChanged: _controller.setShowPanicButton,
                      onShowSimulateFallButtonChanged:
                          _controller.setShowSimulateFallButton,
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


