import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/alert_settings.dart';
import '../../domain/models/caregiver.dart';
import '../../domain/models/user_feature_settings.dart';
import '../widgets/alert_settings_section.dart';
import '../widgets/caregiver_section.dart';
import '../widgets/user_features_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();

  late final TextEditingController _caregiverNameController;
  late final TextEditingController _caregiverEmailController;
  late final TextEditingController _caregiverPhoneController;
  late final TextEditingController _pinController;

  bool _isLoading = true;
  bool _isSaving = false;

  bool _makePhoneCall = true;
  bool _sendSms = false;
  bool _sendGps = false;
  bool _recordAndSendVideo = false;
  double _circularRecordingMinutes = 15;

  bool _showFallDetectionButton = true;
  bool _showPanicButton = true;

  @override
  void initState() {
    super.initState();

    _caregiverNameController = TextEditingController();
    _caregiverEmailController = TextEditingController();
    _caregiverPhoneController = TextEditingController();
    _pinController = TextEditingController();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final caregiver = await _storageService.loadCaregiver();
    final alertSettings = await _storageService.loadAlertSettings();
    final userFeatureSettings = await _storageService.loadUserFeatureSettings();

    if (!mounted) return;

    _caregiverNameController.text = caregiver.name;
    _caregiverEmailController.text = caregiver.email;
    _caregiverPhoneController.text = caregiver.phoneNumber;
    _pinController.text = caregiver.pin;

    setState(() {
      _makePhoneCall = alertSettings.makePhoneCall;
      _sendSms = alertSettings.sendSms;
      _sendGps = alertSettings.sendGps;
      _recordAndSendVideo = alertSettings.recordAndSendVideo;
      _circularRecordingMinutes = alertSettings.circularRecordingMinutes;
      _showFallDetectionButton = userFeatureSettings.showFallDetectionButton;
      _showPanicButton = userFeatureSettings.showPanicButton;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _caregiverPhoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<bool> _saveAndPop() async {
    if (_isSaving) return false;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrige os campos antes de sair.')),
      );
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    final caregiver = Caregiver(
      name: _caregiverNameController.text.trim(),
      email: _caregiverEmailController.text.trim(),
      phoneNumber: _caregiverPhoneController.text.trim(),
      pin: _pinController.text.trim(),
    );

    final alertSettings = AlertSettings(
      makePhoneCall: _makePhoneCall,
      sendSms: _sendSms,
      sendGps: _sendGps,
      recordAndSendVideo: _recordAndSendVideo,
      circularRecordingMinutes: _circularRecordingMinutes,
    );

    final userFeatureSettings = UserFeatureSettings(
      showFallDetectionButton: _showFallDetectionButton,
      showPanicButton: _showPanicButton,
    );

    await _storageService.saveCaregiver(caregiver);
    await _storageService.saveAlertSettings(alertSettings);
    await _storageService.saveUserFeatureSettings(userFeatureSettings);

    if (!mounted) return false;

    Navigator.pop(context, true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CaregiverSection(
                  nameController: _caregiverNameController,
                  emailController: _caregiverEmailController,
                  phoneController: _caregiverPhoneController,
                  pinController: _pinController,
                  validateName: (value) =>
                      AppValidators.requiredField(value, fieldName: 'Nome'),
                  validateEmail: AppValidators.email,
                  validatePhone: AppValidators.phone,
                  validatePin: AppValidators.pin4Digits,
                ),
                const SizedBox(height: 16),
                AlertSettingsSection(
                  makePhoneCall: _makePhoneCall,
                  sendSms: _sendSms,
                  sendGps: _sendGps,
                  recordAndSendVideo: _recordAndSendVideo,
                  circularRecordingMinutes: _circularRecordingMinutes,
                  onMakePhoneCallChanged: (value) {
                    setState(() {
                      _makePhoneCall = value;
                    });
                  },
                  onSendSmsChanged: (value) {
                    setState(() {
                      _sendSms = value;
                    });
                  },
                  onSendGpsChanged: (value) {
                    setState(() {
                      _sendGps = value;
                    });
                  },
                  onRecordAndSendVideoChanged: (value) {
                    setState(() {
                      _recordAndSendVideo = value;
                    });
                  },
                  onCircularRecordingMinutesChanged: (value) {
                    setState(() {
                      _circularRecordingMinutes = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                UserFeaturesSection(
                  showFallDetectionButton: _showFallDetectionButton,
                  showPanicButton: _showPanicButton,
                  onShowFallDetectionButtonChanged: (value) {
                    setState(() {
                      _showFallDetectionButton = value;
                    });
                  },
                  onShowPanicButtonChanged: (value) {
                    setState(() {
                      _showPanicButton = value;
                    });
                  },
                ),
                if (_isSaving) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
