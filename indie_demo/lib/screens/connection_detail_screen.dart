import 'dart:convert';

import 'package:AriesFlutterMobileAgent/Agent/AriesFlutterMobileAgent.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Presentation/PresentationInterface.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:flutter/material.dart';
import 'package:indie_demo/helpers/helpers.dart';
import 'package:indie_demo/widgets/credential_dialog.dart';

class ConnectionDetailScreen extends StatefulWidget {
  final ConnectionDetailArguments argument;

  const ConnectionDetailScreen({Key key, this.argument}) : super(key: key);

  @override
  _ConnectionDetailScreenState createState() => _ConnectionDetailScreenState();
}

class _ConnectionDetailScreenState extends State<ConnectionDetailScreen> {
  List<Presentation> credentialList = [];
  List<Presentation> presentationList = [];

  Future getAllCredentials() async {
    print('Connection details screen. getAllPresentations called');
    try {
      // List<dynamic> credentials = await AriesFlutterMobileAgent.listAllCredentials(filter: {});
      // var presentations = await AriesFlutterMobileAgent.getAllPresentations();
      // var creds = await AriesFlutterMobileAgent.getAllCredentials();

      //final ConnectionDetailArguments data = ModalRoute.of(context).settings.arguments;
      final connection = widget.argument;

      var pres = await AriesFlutterMobileAgent.getPresentationByConnectionId(connection.connection["verkey"]);

      // print('PRESENTATIONS LENGTH => ${presentations.length}');
      // print('CREDS LENGTH => ${creds.length}');
      // print('CREDENTIALS LENGTH => ${credentials.length}');


      pres.forEach((element) {
        presentationList.add(Presentation.fromJson(jsonDecode(element.presentation)));
      });

      setState(() {});
    } catch (exception) {
      print("error in get prsentations $exception");
      throw exception;
    }
  }

  @override
  void initState() {
    super.initState();
    getAllCredentials();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.argument.connection['theirLabel']}'),
        automaticallyImplyLeading: true,
      ),
      body: presentationList.length > 0
          ? Container(
              color: Colors.grey[200],
              padding: EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 0),
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.only(top: 5),
                itemCount: presentationList.length,
                itemBuilder: (BuildContext context, int index) {
                  var pres = presentationList[index];
                  var credName = 'sas';
                  if (presentationList.length == 0) {
                    return Center(
                      child: Text('No credentials'),
                    );
                  }
                  return

                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                    child: Column(
                      children: [
                        Text("${jsonDecode(pres.presentationRequest)['name']} - ${pres.state}"),
                        SizedBox(height: 20,),
                        TextButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return CredentialDialog(
                                connection: widget.argument.connection,
                                credential: pres,
                              );
                            },
                          ),
                          style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                            minimumSize: Size(150, 40),
                          ),
                          // height: 40,
                          // minWidth: 150,
                          child: Text('PROPOSAL', style: TextStyle(color: Colors.white),),
                          //color: Colors.blue,
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          : Text('No Credentials'),
    );
  }
}
