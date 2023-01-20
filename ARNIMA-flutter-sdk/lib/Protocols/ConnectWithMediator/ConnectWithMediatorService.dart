/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'dart:convert';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:AriesFlutterMobileAgent/Utils/Helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../Pool/Pool.dart';

class ConnectWithMediatorService {
  Type get runtimeType => String;

  static const MethodChannel _channel =
      const MethodChannel('AriesFlutterMobileAgent');

  static Future<String> connectWithMediator(   // it returned bool originally
    String url,
    String apiBody,
    String configJson,
    String credentialJson,
    String poolConfig,
  ) async {
    try {

      //var incomingRouterResponse = await postData(url, apiBody);// how it was

      String incomingRouterResponseString = await getStringData(url);
      var incomingRouterResponse =  jsonDecode(utf8.decode(base64.decode(base64.normalize(incomingRouterResponseString.split('=')[1]))));

      //var incomingRouterResponse = jsonDecode(await getData(url)); // how it can work

      var user = await DBServices.getWalletData();
      await DBServices.updateWalletData(
        WalletData(
          user.walletConfig,
          user.walletCredentials,
          user.label,
          user.publicDid,
          user.verkey,
          user.masterSecretId,
          incomingRouterResponse['serviceEndpoint'],
          incomingRouterResponse['routingKeys'],
        ),
      );
      var createPoolResponse = await Pool.createPool(poolConfig);
      if (!createPoolResponse) {
        throw false;
      }
      WalletData myWallet = await DBServices.getWalletData();
      var walletRecord = {
        'label': myWallet.label,
        'serviceEndpoint': myWallet.serviceEndpoint,
        'routingKey': myWallet.routingKey,
        'publicDid': myWallet.publicDid,
        'verKey': myWallet.verkey,
        'masterSecretId': myWallet.masterSecretId,
        'poolConfig': poolConfig,
      };

      final bool addRecordResponse = await _channel.invokeMethod(
        'addWalletRecord',
        <String, dynamic>{
          'configJson': configJson,
          'credentialJson': credentialJson,
          'type': describeEnum(RecordType.MediatorAgent),
          'id': '1',
          'value': jsonEncode(walletRecord),
          'tags': '{}',
        },
      );
      if (addRecordResponse){
        return incomingRouterResponseString;  // need to return string to accept invitation
      }
      return '';//addRecordResponse;
    } catch (exception) {
      throw exception;
    }
  }
}
