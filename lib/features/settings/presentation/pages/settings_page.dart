import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/settings_controller.dart';
import '../widgets/alert_settings_section.dart';
import '../widgets/caregiver_section.dart';
import '../widgets/user_features_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
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

  Future<void> _saveAndPop() async {
    final didSave = await _controller.saveSettings();

    if (!mounted) return;

    if (didSave) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
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
                    AlertSettingsSection(
                      makePhoneCall: _controller.makePhoneCall,
                      sendSms: _controller.sendSms,
                      sendGps: _controller.sendGps,
                      recordAndSendVideo: _controller.recordAndSendVideo,
                      circularRecordingMinutes:
                          _controller.circularRecordingMinutes,
                      onMakePhoneCallChanged: _controller.setMakePhoneCall,
                      onSendSmsChanged: _controller.setSendSms,
                      onSendGpsChanged: _controller.setSendGps,
                      onRecordAndSendVideoChanged:
                          _controller.setRecordAndSendVideo,
                      onCircularRecordingMinutesChanged:
                          _controller.setCircularRecordingMinutes,
                    ),
                    const SizedBox(height: 16),
                    UserFeaturesSection(
                      showFallDetectionButton:
                          _controller.showFallDetectionButton,
                      showPanicButton: _controller.showPanicButton,
                      onShowFallDetectionButtonChanged:
                          _controller.setShowFallDetectionButton,
                      onShowPanicButtonChanged: _controller.setShowPanicButton,
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
