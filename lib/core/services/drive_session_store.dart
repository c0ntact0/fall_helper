import 'package:shared_preferences/shared_preferences.dart';

import '../../features/drive_backup/domain/models/caregiver_drive_session.dart';

class DriveSessionStore {
  static const _isAuthorizedKey = 'drive_is_authorized';
  static const _googleEmailKey = 'drive_google_email';
  static const _googleDisplayNameKey = 'drive_google_display_name';
  static const _rootFolderIdKey = 'drive_root_folder_id';

  Future<CaregiverDriveSession> load() async {
    final prefs = await SharedPreferences.getInstance();

    return CaregiverDriveSession(
      isAuthorized: prefs.getBool(_isAuthorizedKey) ?? false,
      caregiverGoogleEmail: prefs.getString(_googleEmailKey) ?? '',
      caregiverDisplayName: prefs.getString(_googleDisplayNameKey),
      rootFolderId: prefs.getString(_rootFolderIdKey),
    );
  }

  Future<void> save(CaregiverDriveSession session) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isAuthorizedKey, session.isAuthorized);
    await prefs.setString(_googleEmailKey, session.caregiverGoogleEmail);

    if (session.caregiverDisplayName == null ||
        session.caregiverDisplayName!.trim().isEmpty) {
      await prefs.remove(_googleDisplayNameKey);
    } else {
      await prefs.setString(
        _googleDisplayNameKey,
        session.caregiverDisplayName!,
      );
    }

    if (session.rootFolderId == null || session.rootFolderId!.trim().isEmpty) {
      await prefs.remove(_rootFolderIdKey);
    } else {
      await prefs.setString(_rootFolderIdKey, session.rootFolderId!);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isAuthorizedKey);
    await prefs.remove(_googleEmailKey);
    await prefs.remove(_googleDisplayNameKey);
    await prefs.remove(_rootFolderIdKey);
  }
}
