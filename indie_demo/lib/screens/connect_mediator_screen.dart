import 'dart:convert';

import 'package:AriesFlutterMobileAgent/AriesAgent.dart';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:flutter/material.dart';
import 'package:indie_demo/helpers/helpers.dart';
import 'package:progress_dialog/progress_dialog.dart';

import 'connection_screen.dart';

class ConnectMediatorScreen extends StatefulWidget {
  static const routeName = '/connectMediator';

  @override
  _ConnectMediatorScreenState createState() => _ConnectMediatorScreenState();
}

class _ConnectMediatorScreenState extends State<ConnectMediatorScreen> {
  ProgressDialog progressIndicator;
  String _status = "";

  Future<void> aaa() async {
    await getStringData("$MediatorAgentUrl/connection/init");
  }

  Future<void> connectWithMediator() async {
    try {
      progressIndicator.show();
      var user = await AriesFlutterMobileAgent.getWalletData();

      print('did -> ${user?.publicDid ?? 'null'}');
      print('varkey -> ${user?.verkey ?? 'null'}');
      print('label -> ${user?.label ?? 'null'}');

      var invitation = await AriesFlutterMobileAgent.connectWithMediator(
        "$MediatorAgentUrl/connection/init",
        jsonEncode({
          'myDid': user.publicDid,
          'verkey': user.verkey,
          'label': user.label,
        }),
        PoolConfig,
      );

      await AriesFlutterMobileAgent.acceptInvitation(
        {},
        invitation,
      );


      print('MEDIATOR => $invitation');




      if (invitation.isNotEmpty) {

        //AriesFlutterMobileAgent.initPolling();

        print('CONNECTED');
        this.setState(() {
          _status = "Connected";
        });
      }
      progressIndicator.hide();

      Navigator.pushNamed(context, ConnectionScreen.routeName);
    } catch (error) {

      print('ERROR => $error');

      progressIndicator.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    progressIndicator = new ProgressDialog(context);
    progressIndicator.style(
      message: '   Please wait ...',
      borderRadius: 10.0,
      backgroundColor: Colors.black54,
      progressWidget: CircularProgressIndicator(
        strokeWidth: 3,
      ),
      messageTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with mediater'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
                backgroundColor: Colors.green
            ),
            //color: Colors.green,
            onPressed: () async {
              await aaa();
            },
            child: Text(
              'Call request (trigger permissions)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.blue
                ),
                //color: Colors.blue,
                onPressed: () async {
                  await connectWithMediator();
                },
                child: Text(
                  'Connect with mediater',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'status : $_status',
            style: TextStyle(
              color: _status == "Connected" ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
