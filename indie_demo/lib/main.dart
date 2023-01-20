import 'dart:convert';

import 'package:AriesFlutterMobileAgent/Agent/AriesFlutterMobileAgent.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:flutter/material.dart';
import 'package:indie_demo/screens/connect_mediator_screen.dart';
import 'package:indie_demo/screens/connection_detail_screen.dart';
import 'package:indie_demo/screens/connection_screen.dart';
import 'package:indie_demo/screens/create_wallet_screen.dart';
import 'package:indie_demo/screens/qrcode_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await AriesFlutterMobileAgent.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loggedIn = false;

  void isValidUser() async {
    WalletData userData = await AriesFlutterMobileAgent.getWalletData();

    print('getWalletData => ${userData?.toString() ?? 'null'}');

    if (userData != null) {



      print('SET LOGGED IN -> true');
      setState(() {
        loggedIn = true;
      });
    }
  }

  void connectSocket() async {
    try {
      WalletData sdkDB = await AriesFlutterMobileAgent.getWalletData();
      print('getWalletData => ${sdkDB?.toString() ?? 'null'}');
      if (sdkDB != null) {
        AriesFlutterMobileAgent.socketInit();
      }
    } catch (exception) {
      print('Oops! Something went wrong. Please try again later. $exception');
      throw exception;
    }
  }

  @override
  void initState() {
    super.initState();
    connectSocket();
    isValidUser();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: loggedIn ?
      //ConnectMediatorScreen()
      ConnectionScreen()
          : CreateWalletScreen(),
      routes: {
        ConnectMediatorScreen.routeName: (ctx) => ConnectMediatorScreen(),
        ConnectionScreen.routeName: (ctx) => ConnectionScreen(),
        ConnectionDetailScreen.routeName: (ctx) => ConnectionDetailScreen(),
        QRcodeScreen.routeName: (ctx) => QRcodeScreen(),
      },
    );
  }
}














// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key key, this.title}) : super(key: key);
//
//   final String title;
//
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             OutlinedButton(
//               onPressed: () async {
//
//                 try{
//                   var response = await AriesFlutterMobileAgent.createWallet(
//                     {'id': 'Nicolay'},
//                     {'key': '123456'},
//                     'Test wallet for Nicolay',
//                   );
//
//                   print(response);
//
//                 } catch(e){
//                   print('ERROR => $e');
//                 }
//               },
//               child: Text('Create Wallet'),
//             ),
//             OutlinedButton(
//               onPressed: () async {
//
//                 try{
//
//
//
//                   String POOL_CONFIG = '{"reqSignature":{},"txn":{"data":{"data":{"alias":"Node1","blskey":"VDbHpzG3egPnmc8HSugm4iH2g7LWyS9whhSdiSms7JrEazB7HKwGFpXpib7ASaKY4Zxakqa7ihUYe2xHoqHLcS3p6Y1unv7yK6HWYuYpMcMGYtQCrk3i8yDXXHVmv7FB6D9mvYwQnPLcqYMCSByVqePGR5TqrFidcw8SfoDDbC5nxP","client_ip":"23.97.129.212","client_port":9702,"node_ip":"23.97.129.212","node_port":9701,"services":["VALIDATOR"]},"dest":"AB6ttBTNbrBU7guQnFuvJCpf4ifHpsp92LDJsLB7t8ER"},"metadata":{"from":"HqGoHVsbwvT9E5jduBoQT9"},"type":"0"},"txnMetadata":{"seqNo":1,"txnId":"fea82e10e894419fe2bea7d96296a6d46f50f93f9eeda954ec461b2ed2950b62"},"ver":"1"}{"reqSignature":{},"txn":{"data":{"data":{"alias":"Node2","blskey":"2hcDsJ5tamNHj9mMz5xzQ3EYxii7aisZciEDie5dRapLRDsMfbJmHtCGHhA9PJr2kGe6oV3tS9RWKkveyVDBVdiwLm2iu46yuhPXqi4ZZggPift2PTKtE2RkLuPNggaDBEe827riZo2e4SSvy5HcdwahAtZ4UwJhgrTKwytzRuAtafH","client_ip":"23.97.129.212","client_port":9704,"node_ip":"23.97.129.212","node_port":9703,"services":["VALIDATOR"]},"dest":"3wnq4paP7w3UGcjPESxamT3oG779h9fd8beaiwYTpFjd"},"metadata":{"from":"6QMhYZCFkHCtqejn7Y38sn"},"type":"0"},"txnMetadata":{"seqNo":2,"txnId":"1ac8aece2a18ced660fef8694b61aac3af08ba875ce3026a160acbc3a3af35fc"},"ver":"1"}{"reqSignature":{},"txn":{"data":{"data":{"alias":"Node3","blskey":"4XF5qZQuGHwyKoQQRfCqzRwAK5KmGfdix3UoQGxr5fPnfGP5N99VQLMazqg7DM1pu4FJcizS6q4VV3T5rSwU2TJNxenfaNxtvM6xVRSH24QuFazzJ3nUu7pE27GRcPBLsMGrzRLqCummMYJtH5XK3MYDYgFLLNEThGAiXKaySHAZFAC","client_ip":"23.97.129.212","client_port":9706,"node_ip":"23.97.129.212","node_port":9705,"services":["VALIDATOR"]},"dest":"8rQjcUhcxstQJt3myYzyZhVtMSTJXyrFFyVvmoPEzLUM"},"metadata":{"from":"FQZYf8Qy6VzQGKiSCcTifv"},"type":"0"},"txnMetadata":{"seqNo":3,"txnId":"1ac8aece2a18ced660fef869sdfscxcxzvvsdfdwerdf3026a160acbc3a3af35fc"},"ver":"1"}';
//                   String MEDIATOR_AGENT_URL = 'http://develop.indy-agent.prove.api.ledgerleopard.com';
//
//                   var response = await AriesFlutterMobileAgent.connectWithMediator(
//                     "$MEDIATOR_AGENT_URL/discover",
//                     jsonEncode({
//                       'myDid': "<WALLET_PUBLIC_DID>",
//                       'verkey': "<WALLET_VERIFIED_KEY>",
//                       'label': 'Test wallet for Nicolay',
//                     }),
//                     POOL_CONFIG,
//                   );
//
//
//                   print('RESPONSE ==> $response');
//
//                 } catch(e){
//                   print('ERROR => $e');
//                 }
//               },
//               child: Text('Connect Agent'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
