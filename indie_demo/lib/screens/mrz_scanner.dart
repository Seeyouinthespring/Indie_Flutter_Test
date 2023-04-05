import 'dart:convert';

import 'package:AriesFlutterMobileAgent/Agent/AriesFlutterMobileAgent.dart';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Credential/CredentialMessages.dart';
import 'package:AriesFlutterMobileAgent/Storage/Models/ConnectionModel/connectiondata.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrz_scanner/mrz_scanner.dart';

import '../helpers/helpers.dart';
import '../routes.dart';

class MRZScannerScreen extends StatefulWidget{
  final ConnectionDetailArguments2 argument;

  const MRZScannerScreen({Key key, this.argument}) : super(key: key);

  @override
  MRZScannerScreenState createState() => MRZScannerScreenState();
}

class MRZScannerScreenState extends State<MRZScannerScreen>{

  final MRZController controller = MRZController();

  issueDocument(MRZResult mrzResult) async {


    //await progressIndicator.show();
    //List<dynamic> templates = jsonDecode(await getStringData("https://test.prove.api.ledgerleopard.com/api/document-templates/schemas")) as List<dynamic>;
    List<dynamic> templates = jsonDecode(await getStringData("https://develop.prove.api.ledgerleopard.com/api/document-templates/schemas")) as List<dynamic>;

    print(templates);

    var template = templates.firstWhere((element) => element['name'] == 'MRZ Passport');

    print('TEMPLATE => ${template}');

    var attributes = [];
    for (int i = 0; i < template["attributeFields"].length; i++){
      attributes.add({
        "name": template["attributeFields"][i]["name"],
        "mime-type": "text/plan",
        "value": getAttributeValue(mrzResult, template["attributeFields"][i]["name"]),
      });
    }

    print('ATTRIBUTES => ${attributes}');

    var schema = template['schemaId'].split(':');
    var message = await AriesFlutterMobileAgent.sendCredentialProposal(
        widget.argument.connection.connectionId,
        credentialPreviewMessage(attributes),
        template['schemaId'],
        "${schema[0]}:3:CL:1510:TAG1",
        "Document name"
      //issuerDid
    );
    //await progressIndicator.hide();

    print('message => $message');
    print('result => $schema');
    Navigator.of(context).pushReplacementNamed(Routes.connections);
  }

  String getAttributeValue(MRZResult result, String fieldName){
    switch (fieldName){
      case 'document type':
        return result.documentType;
      case 'document number':
        return result.documentNumber;
      case 'name':
        return result.givenNames;
      case 'surname':
        return result.surnames;
      case 'country':
        return result.countryCode;
      case 'nationality':
        return result.nationalityCountryCode;
      case 'birth date':
        return DateFormat('yyyyMMdd').format(result.birthDate);
      case 'sex':
        return result.sex.name;
      case 'expiration date':
        return DateFormat('yyyyMMdd').format(result.expiryDate);
      case 'personal number':
        return result.personalNumber;
      case 'personal number 2':
        return result.personalNumber2 ?? "";
      default:
        return "";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner'),
        automaticallyImplyLeading: true,
      ),
      body: Builder(builder: (context) {

        //return Container();
        return MRZScanner(
          controller: controller,
          onSuccess: (mrzResult) async {
            await showDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 10),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          //controller = MRZController();
                          //setState(() {

                          //});
                          controller.currentState?.resetScanning();
                        },
                        child: const Text('Reset Scanning'),
                      ),
                      Text('Document type : ${mrzResult.documentType}'),
                      Text('Document number : ${mrzResult.documentNumber}'),
                      Text('Name : ${mrzResult.givenNames}'),
                      Text('Surnames : ${mrzResult.surnames}'),
                      Text('Gender : ${mrzResult.sex.name}'),
                      Text('Country code : ${mrzResult.countryCode}'),
                      Text('Nationality : ${mrzResult.nationalityCountryCode}'),
                      Text('Date of Birth : ${mrzResult.birthDate}'),
                      Text('Expiry Date : ${mrzResult.expiryDate}'),
                      Text('Personal number : ${mrzResult.personalNumber}'),
                      Text('Personal number 2 : ${mrzResult.personalNumber2}'),
                      TextButton(
                        child: Text('Issue document'),
                        onPressed: () async {
                          await issueDocument(mrzResult);
                        },
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}