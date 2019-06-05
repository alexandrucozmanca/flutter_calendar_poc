import 'package:calendar_poc/models/user.dart';
import 'package:calendar_poc/pages/calendar_page.dart';
import 'package:calendar_poc/services/auth_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = new GlobalKey<FormState>();
  String _errorMessage;
  bool _isLoading;
  bool _isIos;
  User _user;

  @override
  void initState() {
    setState(() {
      _errorMessage = "";
      _isLoading = false;
    });
    super.initState();
  }

  /*

  UI Elements

  */

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
        appBar: new AppBar(
          title: new Text('Login'),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showBody() {
    return new Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          image: DecorationImage(
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.6), BlendMode.dstATop),
            image: AssetImage('res/images/mountains.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              Container(height: 50),
              _showLogo(),
              Container(height: 50),
              _showGoogleLogin(),
            ],
          ),
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor)));
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showLogo() {
    return new CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 48.0,
      child: Image.asset('res/images/trencadis-icon.png'),
    );
  }

  Widget _showGoogleLogin() {
    return new RaisedButton(
        padding: EdgeInsets.all(2),
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)),
        color: Colors.white,
        onPressed: () {
          _googleLogin();
        },
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 12.0,
              child: Image.asset('res/images/google-icon.png'),
            ),
            new Container(
              margin: EdgeInsets.only(left: 10),
            ),
            new Text('Sign in with Google!',
                style: new TextStyle(
                    fontSize: 20.0, color: Theme.of(context).primaryColor)),
          ],
        ));
  }

  /*

  Methods

  */

  _googleLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      User user = await authService.signInWithGoogle();

      if (user != null) {
        setState(() {
          _isLoading = false;
          _user = user;
        });
        print(_user);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => CalendarPage(user: _user)));
      } else {
        setState(() {
          _isLoading = false;
        });
        print("User could not be retrieved");
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        if (_isIos) {
          _errorMessage = e.details;
        } else
          _errorMessage = e.message;
      });
    }
  }
}
