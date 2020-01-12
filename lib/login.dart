import 'dart:convert';

import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/settings.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  final void Function(String, String, String) callback;

  Login({this.callback});

  @override
  _LoginState createState() => _LoginState(this.callback);
}

class _LoginState extends State<Login> {
  final void Function(String, String, String) callback;
  final _formKey = GlobalKey<FormState>();
  final endpointController = TextEditingController(text: Settings.endpoint);
  final loginController = TextEditingController(text: Settings.login);
  final passwordController = TextEditingController(text: Settings.password);
  bool blockUI = false;

  _LoginState(this.callback);

  @override
  Widget build(BuildContext context) {
    if (blockUI) {
      return CircularProgressIndicator();
    }

    Form form = Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
                alignment: Alignment.topCenter,
                child: Text(
                  "Login Form",
                  style: TextStyle(fontSize: 30),
                )
            ),
            TextFormField(
              controller: endpointController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              decoration: InputDecoration(hintText: "http(s)://host:port"),
            ),
            TextFormField(
              controller: loginController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              decoration: InputDecoration(hintText: "login"),
            ),
            TextFormField(
              controller: passwordController,
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              decoration: InputDecoration(hintText: "password"),
              obscureText: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: RaisedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false
                  // otherwise.
                  onLoginButtonPressed(context);
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ));

    return Center(
        child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[form])));
  }

  void onLoginButtonPressed(BuildContext context) {
    if (_formKey.currentState.validate()) {
      setState(() {
        blockUI = true;
      });
      // If the form is valid, display a Snackbar.
      Flushbar(
        message: "Processing data",
        duration: Duration(seconds: 1),
      )..show(context);

      var url = endpointController.text + '/authenticate';

      Map data = {
        'username': loginController.text,
        'password': passwordController.text,
      };

      //encode Map to JSON
      var body = json.encode(data);

      var response = http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);

      response
          .then((response) {
            if (response.statusCode == 200) {
              String token = json.decode(response.body)["jwt"];
              print("new token: " + token);
              callback(endpointController.text, loginController.text, token);
            }
          })
          .timeout(const Duration(seconds: 5))
          .whenComplete(() {
            setState(() {
              blockUI = false;
            });
          })
          .catchError((e) {
            setState(() {
              blockUI = false;
            });
            Flushbar(
              message: 'Login error: $e',
              duration: Duration(seconds: 2),
            )..show(context);
            print('Login error: $e');
          });
    }
  }
}
