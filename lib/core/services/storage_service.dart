import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/domain/models/alert_settings.dart';
import '../../features/settings/domain/models/caregiver.dart';
import '../../features/settings/domain/models/user_feature_settings.dart';

class StorageService {
  static const _caregiverNameKey = 'caregiver_name';
  static const _caregiverEmailKey = 'caregiver_email';
  static const _caregiverPhoneKey = 'caregiver_phone';
  static const _pinKey = 'settings_pin';

  static const _makePhoneCallKey = 'make_phone_call';
  static const _sendSmsKey = 'send_sms';
  static const _sendGpsKey = 'send_gps';
  static const _recordAndSendVideoKey = 'record_and_send_video';
  static const _circularRecordingMinutesKey = 'circular_recording_minutes';

  static const _showFallDetectionButtonKey = 'show_fall_detection_button';
  static const _showPanicButtonKey = 'show_panic_button';

  Future<Caregiver> loadCaregiver() async {
    final prefs = await SharedPreferences.getInstance();

    return Caregiver(
      name: prefs.getString(_caregiverNameKey) ?? 'Rui Loureiro',
      email: prefs.getString(_caregiverEmailKey) ?? 'rui@example.com',
      phoneNumber: prefs.getString(_caregiverPhoneKey) ?? '210430349',
      pin: prefs.getString(_pinKey) ?? '0000',
    );
  }

  Future<void> saveCaregiver(Caregiver caregiver) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_caregiverNameKey, caregiver.name);
    await prefs.setString(_caregiverEmailKey, caregiver.email);
    await prefs.setString(_caregiverPhoneKey, caregiver.phoneNumber);
    await prefs.setString(_pinKey, caregiver.pin);
  }

  Future<AlertSettings> loadAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AlertSettings(
      makePhoneCall: prefs.getBool(_makePhoneCallKey) ?? true,
      sendSms: prefs.getBool(_sendSmsKey) ?? false,
      sendGps: prefs.getBool(_sendGpsKey) ?? false,
      recordAndSendVideo: prefs.getBool(_recordAndSendVideoKey) ?? false,
      circularRecordingMinutes:
          prefs.getDouble(_circularRecordingMinutesKey) ?? 15,
    );
  }

  Future<void> saveAlertSettings(AlertSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_makePhoneCallKey, settings.makePhoneCall);
    await prefs.setBool(_sendSmsKey, settings.sendSms);
    await prefs.setBool(_sendGpsKey, settings.sendGps);
    await prefs.setBool(_recordAndSendVideoKey, settings.recordAndSendVideo);
    await prefs.setDouble(
      _circularRecordingMinutesKey,
      settings.circularRecordingMinutes,
    );
  }

  Future<UserFeatureSettings> loadUserFeatureSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return UserFeatureSettings(
      showFallDetectionButton:
          prefs.getBool(_showFallDetectionButtonKey) ?? true,
      showPanicButton: prefs.getBool(_showPanicButtonKey) ?? true,
    );
  }

  Future<void> saveUserFeatureSettings(UserFeatureSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _showFallDetectionButtonKey,
      settings.showFallDetectionButton,
    );
    await prefs.setBool(_showPanicButtonKey, settings.showPanicButton);
  }
}
