import 'package:calendar_poc/models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  GoogleSignIn _gSignIn;

  Future<User> signInWithGoogle() async {
    User user;
    _gSignIn = new GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events'
        ]
    );

    try {
      GoogleSignInAccount googleSignInAccount = await _gSignIn.signIn();

      GoogleSignInAuthentication authentication = await googleSignInAccount.authentication;

      user = new User(accessToken: authentication.accessToken, idToken: authentication.idToken, email: googleSignInAccount.email);
      return user;
    } catch (e) {
      print('Error: ' + e);
    }
    return user;
  }
}

final authService = AuthService();

