import 'dart:convert';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionInterface.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionMessages.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/InvitationInterface.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:AriesFlutterMobileAgent/Utils/Helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

import '../../Pool/Pool.dart';
import 'KeylistUpdateMessages.dart';

class KeylistUpdateService {
  Type get runtimeType => String;

  static Future<dynamic> sendKeylistUpdateRequest(WalletData user, Connection connection, {InvitationDetails invitation, String verkey = ''}) async {
    try{

      print('KEY LIST UPDATE CALLED');

      Map<String, dynamic> keylistUpdateMessage = createKeylistUpdateMessage(verkey.isEmpty ? connection.verkey: verkey);
      //Map<String, dynamic> outboundKeylistUpdateMessage = createOutboundMessage(connection, keylistUpdateMessage, simplePayload: true, invitation: invitation);
      //print('Outbound keylist message => ${jsonEncode(outboundKeylistUpdateMessage)}');

      Keys keys = getKeys(connection, invitation: invitation);


      // print('KEY LIST UPDATE keys  recipirnt keys=> ${keys.recipientKeys}');
      // print('KEY LIST UPDATE keys routing keys => ${keys.routingKeys}');
      // print('KEY LIST UPDATE keys endpoint => ${keys.endpoint}');
      // print('KEY LIST UPDATE keys senderVk => ${keys.senderVk}');


      var outboundPackKeylistUpdateMessage = await packMessage(
        user.walletConfig,
        user.walletCredentials,
        keylistUpdateMessage,
        keys,
      );

      Response keylistUpdateResponse = await outboundAgentMessagePost(
        keys.endpoint,
        outboundPackKeylistUpdateMessage,
      );

      print('KEY LIST UPDATE RESPONSE => ${keylistUpdateResponse.statusCode}');

      // if (keylistUpdateResponse.statusCode == 200){
      //   var unpacked = await unPackMessage(
      //     user.walletConfig,
      //     user.walletCredentials,
      //     keylistUpdateResponse.body,
      //   );
      //   print('UNPACKED => ${jsonDecode(unpacked)}');
      // }
    } catch (e){
      print('Error  $e' );
      return false;
    }
  }

  static Future<dynamic> sendMediateRequest(WalletData user, Connection connection, {InvitationDetails invitation, String verkey = ''}) async {
    try{

      print('MEDIATE REQUEST CALLED');

      Map<String, dynamic> mediateRequestMessage = createMediateRequestMessage();// createKeylistUpdateMessage(verkey.isEmpty ? connection.verkey: verkey);
      //Map<String, dynamic> outboundMediateRequestMessage = createOutboundMessage(connection, mediateRequestMessage, simplePayload: true, invitation: invitation);
      //print('Outbound mediate request message => ${jsonEncode(outboundMediateRequestMessage)}');

      Keys keys = getKeys(connection, invitation: invitation);

      var outboundPackMediateRequestMessage = await packMessage(
        user.walletConfig,
        user.walletCredentials,
        mediateRequestMessage,
        keys
      );

      Response keylistUpdateResponse = await outboundAgentMessagePost(
        keys.endpoint,
        outboundPackMediateRequestMessage,
      );

      print('MEDIATE REQUEST RESPONSE => ${keylistUpdateResponse.statusCode}');

      // if (keylistUpdateResponse.statusCode == 200){
      //   var unpacked = await unPackMessage(
      //     user.walletConfig,
      //     user.walletCredentials,
      //     keylistUpdateResponse.body,
      //   );
      //   print('UNPACKED => ${jsonDecode(unpacked)}');
      // }
    } catch (e){
      print('Error  $e' );
      return false;
    }
  }

}