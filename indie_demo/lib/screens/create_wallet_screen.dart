import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_dialog/progress_dialog.dart';
import '../config/check_permissions.dart';
import 'connect_mediator_screen.dart';
import 'package:AriesFlutterMobileAgent/AriesAgent.dart';

class CreateWalletScreen extends StatefulWidget {
  @override
  _CreateWalletScreenState createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  ProgressDialog progressIndicator;
  TextEditingController walletNameController = TextEditingController();
  TextEditingController walletKeyController = TextEditingController();
  // ignore: unused_field
  String _did = "";
  Future<void> _createWallet() async {
    List<dynamic> createWalletData;
    var arrayData;

    //await getStringData("http://192.168.88.95:3000/connection/init");

    try {
      var permission = await CheckPermissions.requestStoragePermission();

      
      print('Permission ? $permission');

      if (permission) {
        progressIndicator.show();
        createWalletData = await AriesFlutterMobileAgent.createWallet(
          {'id': walletNameController.text},
          {'key': walletKeyController.text},
          walletNameController.text,
        );

        print('Create wallet data => $createWalletData');


        arrayData = List<String>.from(createWalletData);
        setState(() {
          _did = arrayData[0];
          progressIndicator.hide();
        });

        print('SUCCESS');

        Navigator.pushNamed(context, ConnectMediatorScreen.routeName);
      } else {
        progressIndicator.hide();
        setState(() {
          _did = "Storage permission not Granted";
        });
      }
    } on PlatformException catch (err) {

      print('Error bl blblblblblblblblbl  =>  $err');

      progressIndicator.hide();
      if (err.code == '203') {
        setState(() {
          _did = "Wallet Already Exists";
        });
      }
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
        title: const Text('Aries Flutter Agent'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.asset(
              'assets/images/AyanWorks.jpg',
              width: 300,
              height: 150,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              height: 50,
              child: TextField(
                controller: walletNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Wallet Name',
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              height: 50,
              child: TextField(
                controller: walletKeyController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Wallet Key',
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              height: 50,
              child: TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () async {
                  if (walletNameController.text != '' &&
                      walletKeyController.text != '') {
                    _createWallet();
                  }
                },
                child: Text(
                  'Create Wallet and Did',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
