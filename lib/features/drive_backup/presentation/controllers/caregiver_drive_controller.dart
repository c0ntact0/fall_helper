import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/services/caregiver_google_auth_service.dart';
import '../../../../core/services/drive_folder_service.dart';
import '../../../../core/services/drive_session_store.dart';
import '../../../../core/services/drive_upload_service.dart';
import '../../domain/models/caregiver_drive_session.dart';
import '../../domain/models/drive_upload_item.dart';
import '../../domain/models/drive_upload_result.dart';

class CaregiverDriveController extends ChangeNotifier {
  CaregiverDriveController({
    required CaregiverGoogleAuthService googleAuthService,
    required DriveFolderService driveFolderService,
    required DriveUploadService driveUploadService,
    required DriveSessionStore driveSessionStore,
  }) : _googleAuthService = googleAuthService,
       _driveFolderService = driveFolderService,
       _driveUploadService = driveUploadService,
       _driveSessionStore = driveSessionStore;

  static const String defaultRootFolderName = 'Fall Helper Alerts';

  final CaregiverGoogleAuthService _googleAuthService;
  final DriveFolderService _driveFolderService;
  final DriveUploadService _driveUploadService;
  final DriveSessionStore _driveSessionStore;

  CaregiverDriveSession _session = const CaregiverDriveSession.empty();
  CaregiverDriveSession get session => _session;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isAuthorizing = false;
  bool get isAuthorizing => _isAuthorizing;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  DriveUploadResult? _lastUploadResult;
  DriveUploadResult? get lastUploadResult => _lastUploadResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await _googleAuthService.initialize();
    _session = await _driveSessionStore.load();
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> linkCaregiverDrive() async {
    if (_isAuthorizing) return;

    _isAuthorizing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _googleAuthService.authorizeDriveAccess();

      final rootFolderId = await _driveFolderService.getOrCreateRootFolder(
        accessToken: authResult.accessToken,
        folderName: defaultRootFolderName,
      );

      _session = CaregiverDriveSession(
        isAuthorized: true,
        caregiverGoogleEmail: authResult.googleEmail,
        caregiverDisplayName: authResult.displayName,
        rootFolderId: rootFolderId,
      );

      await _driveSessionStore.save(_session);
    } catch (e) {
      _errorMessage = 'Falha ao ligar Google Drive: $e';
    } finally {
      _isAuthorizing = false;
      notifyListeners();
    }
  }

  Future<void> unlinkCaregiverDrive() async {
    try {
      await _googleAuthService.signOut();
    } catch (_) {
      // Ignora erro de sign-out remoto e limpa estado local.
    }

    await _driveSessionStore.clear();
    _session = const CaregiverDriveSession.empty();
    _lastUploadResult = null;
    notifyListeners();
  }

  Future<DriveUploadResult?> uploadEvidenceFolder({
    required String evidenceFolderPath,
    required DateTime alertTime,
  }) async {
    if (_isUploading) return null;

    if (!_session.hasLinkedAccount) {
      _errorMessage = 'Google Drive do cuidador não está ligado.';
      notifyListeners();
      return null;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authResult = await _googleAuthService.authorizeDriveAccess();

      final alertFolderId = await _driveFolderService.createAlertFolder(
        accessToken: authResult.accessToken,
        rootFolderId: _session.rootFolderId!,
        folderName: alertTime.toIso8601String().replaceAll(':', '-'),
      );

      final items = await _collectUploadItems(evidenceFolderPath);

      final result = await _driveUploadService.uploadAlertFiles(
        accessToken: authResult.accessToken,
        parentFolderId: alertFolderId,
        items: items,
      );

      _lastUploadResult = result;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Falha no upload para Google Drive: $e';
      notifyListeners();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<List<DriveUploadItem>> _collectUploadItems(String folderPath) async {
    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      return const [];
    }

    final items = <DriveUploadItem>[];
    File? consolidatedVideo;

    await for (final entity in directory.list()) {
      if (entity is! File) continue;

      final filename = entity.uri.pathSegments.last;
      final lower = filename.toLowerCase();

      if (lower == 'alert_video.mp4') {
        consolidatedVideo = entity;
      } else if (lower.endsWith('.json')) {
        items.add(
          DriveUploadItem(
            localPath: entity.path,
            remoteName: filename,
            mimeType: 'application/json',
          ),
        );
      }
    }

    if (consolidatedVideo != null) {
      items.insert(
        0,
        DriveUploadItem(
          localPath: consolidatedVideo.path,
          remoteName: 'alert_video.mp4',
          mimeType: 'video/mp4',
        ),
      );
    }

    items.sort((a, b) => a.remoteName.compareTo(b.remoteName));
    return items;
  }
}
