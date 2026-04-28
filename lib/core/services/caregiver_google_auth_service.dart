import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_drive_config.dart';

class CaregiverGoogleAuthResult {
  final String googleEmail;
  final String? displayName;
  final String accessToken;

  const CaregiverGoogleAuthResult({
    required this.googleEmail,
    required this.displayName,
    required this.accessToken,
  });
}

abstract class CaregiverGoogleAuthService {
  Future<void> initialize();
  Future<CaregiverGoogleAuthResult> authorizeDriveAccess();
  Future<void> signOut();
}

class CaregiverGoogleAuthServiceImpl implements CaregiverGoogleAuthService {
  CaregiverGoogleAuthServiceImpl();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _googleSignIn.initialize(
      serverClientId: GoogleDriveConfig.webOAuthClientId,
    );

    try {
      await _googleSignIn.attemptLightweightAuthentication();
    } catch (_) {
      // Ignora; voltamos a pedir interação quando necessário.
    }

    _initialized = true;
  }

  @override
  Future<CaregiverGoogleAuthResult> authorizeDriveAccess() async {
    await initialize();

    GoogleSignInAccount? user;

    try {
      user = await _googleSignIn.attemptLightweightAuthentication();
    } catch (_) {
      user = null;
    }

    user ??= await _googleSignIn.authenticate();

    final existingAuthorization = await user.authorizationClient
        .authorizationForScopes(GoogleDriveConfig.scopes);

    final authorization =
        existingAuthorization ??
        await user.authorizationClient.authorizeScopes(
          GoogleDriveConfig.scopes,
        );

    return CaregiverGoogleAuthResult(
      googleEmail: user.email,
      displayName: user.displayName,
      accessToken: authorization.accessToken,
    );
  }

  @override
  Future<void> signOut() async {
    await initialize();
    await _googleSignIn.disconnect();
  }
}
