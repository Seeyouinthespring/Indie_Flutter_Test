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

      WalletData user = await DBServices.getWalletData();

      ConnectionData connectionDB = await DBServices.getConnection(user.defaultMediatorId);

      Connection connection = Connection.fromJson(jsonDecode(connectionDB.connection));

      Object message = createPickupMessage();

      Map<String, dynamic> outboundMessage = createOutboundMessage(connection, message, simplePayload: true);

      dynamic outboundPackMessage = await packMessage(user.walletConfig, user.walletCredentials, outboundMessage);

      Response response = await outboundAgentMessagePost(
        outboundMessage['endpoint'],
        outboundPackMessage,
      );
      dynamic unpacked = await unPackMessage(
        user.walletConfig,
        user.walletCredentials,
        response.body,
      );
      print('PICKED UP MESSAGE UNPACKED => ${jsonDecode(unpacked)}');

      return jsonDecode(unpacked);
    } catch (e){
      print('Error  $e' );
      return false;
    }
  }
}
