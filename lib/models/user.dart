class User{
  final String accessToken;
  final String idToken;
  final String email;

  User({this.accessToken, this.idToken, this.email});

  @override
  String toString() {
    return 'User{accessToken: $accessToken, idToken: $idToken, email: $email}';
  }
}


