import 'package:flutter/material.dart';
import 'package:flutter_app/filemanager.dart';
import 'package:flutter_app/login.dart';
import 'package:flutter_app/settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote File Manager',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Remote File Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum OperationType { loading, login, loggedIn }

class _MyHomePageState extends State<MyHomePage> {

  // Create storage
  final storage = new FlutterSecureStorage();
  OperationType _operationType = OperationType.loading;

  Future<OperationType> init() async {
    Settings.endpoint = await storage.read(key: "endpoint");
    Settings.login = await storage.read(key: "login");
    //Settings.password = await storage.read(key: "password");
    String token = await storage.read(key: "token");

    print("fetchOperationType");
    if (await isTokenValid(token)) {
      Settings.token = token;
      _operationType = OperationType.loggedIn;
    } else {
      _operationType = OperationType.login;
    }

    return _operationType;
  }

  void authenticationError(){
    setState(() {
      _operationType = OperationType.login;
    });
  }

  void loginSuccess(String endpoint, String login, String token) {

    print("write data, endpoint:$endpoint login: $login token:$token");

    List<Future<void>> list = List();
    list.add(storage.write(key: "endpoint", value: endpoint));
    list.add(storage.write(key: "login", value: login));
    list.add(storage.write(key: "token", value: token));

    Future.wait(list).then((_) {
      setState(() {

        Settings.endpoint = endpoint;
        Settings.login = login;
        Settings.token = token;

        _operationType = OperationType.loggedIn;
      });
    });
  }

  Future<bool> isTokenValid(String token) async {
    print('checking token: $token');

    if (token == null || Settings.endpoint == null) {
      return false;
    }

    var url = '${Settings.endpoint}/authenticate/validate';

    try {
      var response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": 'Bearer $token'
        },
        //body: body
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      } else {
        print("validation, response code: " + response.statusCode.toString());
        print("validation, body: " + response.body.toString());
      }
    } catch (e) {
      print('Error: $e');
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<OperationType>(
          future: init(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return buildContentBody();
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            // By default, show a loading spinner.
            return CircularProgressIndicator();
          }),
    );
  }

  Widget buildContentBody() {
    if (_operationType == OperationType.loggedIn) {
      return new FileManager(authenticationError);
    } else if (_operationType == OperationType.loading) {
      return Text(
        'Loading...',
      );
    } else {
      return Login(callback: loginSuccess);;
    }
  }
}
