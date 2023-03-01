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
import 'package:http/http.dart';

class MessageService {
  Type get runtimeType => String;

  static Future<dynamic> pickupMessage() async {
    try{

      WalletData user = await DBServices.getWalletData();

      ConnectionData connectionDB = await DBServices.getConnection(user.defaultMediatorId);

      Connection connection = Connection.fromJson(jsonDecode(connectionDB.connection));

      Object message = createPickupMessage();

      Keys keys = getKeys(connection);

      dynamic outboundPackMessage = await packMessage(user.walletConfig, user.walletCredentials, message, keys);

      Response response = await outboundAgentMessagePost(
        keys.endpoint,
        outboundPackMessage,
      );
      dynamic unpacked = await unPackMessage(
        user.walletConfig,
        user.walletCredentials,
        response.body,
      );

      return jsonDecode(unpacked);
    } catch (e){
      print('Error  $e' );
      return false;
    }
  }
}
