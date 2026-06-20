import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        scopes: const ['https://www.googleapis.com/auth/calendar.readonly'],
      );

  final GoogleSignIn _googleSignIn;

  Future<GoogleSignInAccount?> signInSilently() async {
    return _googleSignIn.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() async {
    return _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<String?> getAccessToken(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    return auth.accessToken;
  }
}
