/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'dart:convert';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionInterface.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionMessages.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:AriesFlutterMobileAgent/Utils/Helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

import '../../Pool/Pool.dart';

class MessageService {
  Type get runtimeType => String;

  static const MethodChannel _channel = const MethodChannel('AriesFlutterMobileAgent');

  static Future<dynamic> pickupMessage() async {
    try{
      print('1');
      WalletData user = await DBServices.getWalletData();
      print('2');
      ConnectionData connectionDB = await DBServices.getConnection(user.defaultMediatorId);
      print('3');
      Connection connection = Connection.fromJson(jsonDecode(connectionDB.connection));
      print('4');
      Object message = createPickupMessage();
      print('5');
      Object outboundMessage = createOutboundMessage(connection, message);
      print('6');
      dynamic outboundPackMessage = await packMessage(user.walletConfig, user.walletCredentials, outboundMessage);
      print('7');
      Response response = await outboundAgentMessagePost(
        jsonDecode(outboundMessage)['endpoint'],
        outboundPackMessage,
      );
      print('8 ==> ${response.statusCode} --- ${response.body}');
      dynamic unpacked = await unPackMessage(
        user.walletConfig,
        user.walletCredentials,
        response.body,
      );
      print('9');
      print('PICKED UP MESSAGE UNPACKED => ${jsonDecode(unpacked)}');

      return jsonDecode(unpacked);
    } catch (e){
      print('Error  ${e}' );
      return false;
    }

  }
}
