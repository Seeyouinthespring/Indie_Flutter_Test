import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionInterface.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionMessages.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/InvitationInterface.dart';
import 'package:AriesFlutterMobileAgent/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'CustomExceptions.dart';

MethodChannel channel = const MethodChannel('AriesFlutterMobileAgent');

encodeBase64(String data) {
  List<int> bytes = utf8.encode(data);
  var base64Str = base64.encode(bytes);
  return base64Str;
}

String decodeBase64(String base64Data) {
  final List<int> res = base64.decode(base64Data);
  final decodedData = utf8.decode(res);
  return decodedData;
}

enum RecordType {
  Connection,
  TrustPing,
  BasicMessage,
  Credential,
  Presentation,
  MediatorAgent,
  SSIMessage,
}

String encodeInvitationFromObject(
  Object invitation,
  String serviceEndpoint,
) {
  String result = jsonEncode(invitation);
  List<int> bytes = utf8.encode(result);
  String encodedInvitation = base64.encode(bytes);
  String encodedUrl = serviceEndpoint + '?c_i=' + encodedInvitation;
  return encodedUrl;
}

String decodeInvitationFromUrl(String invitationUrl) {
  //final List<String> encodedInvitation = invitationUrl.split('c_i=');
  final List<String> encodedInvitation = invitationUrl.split(new RegExp(r'c_i=|",'));
  final List<int> result = base64.decode(encodedInvitation[1]);
  final invitation = utf8.decode(result);
  return invitation;
}

dynamic unPackMessage(
  String configJson,
  String credentialsJson,
  payload,
) async {
  try {
    var unPackMessage;

    if (Platform.isIOS) {
      unPackMessage = await channel.invokeMethod('unpackMessage', <String, dynamic>{
        'configJson': configJson,
        'credentialJson': credentialsJson,
        'payload': payload,
      });
      return unPackMessage;
    } else {
      Uint8List bytes = utf8.encode(jsonEncode(payload));
      unPackMessage =
          await channel.invokeMethod('unpackMessage', <String, dynamic>{
        'configJson': configJson,
        'credentialJson': credentialsJson,
        'payload': bytes,
      });
      var inboundPackedMessage = utf8.decode(unPackMessage?.cast<int>());
      return inboundPackedMessage;
    }
  } catch (exception) {
    throw exception;
  }
}

dynamic packMessage(
    String configJson,
    String credentialsJson,
    Map<String, dynamic> outboundMessage,
    Keys keys,
) async {
  try {
    var packedBufferMessage;
    var message;

    if (Platform.isIOS) {
      packedBufferMessage = await channel.invokeMethod('packMessage', <String, dynamic>{
        'configJson': configJson,
        'credentialsJson': credentialsJson,
        'payload': jsonEncode(outboundMessage),
        'recipientKeys': keys.recipientKeys,
        'senderVk': keys.senderVk,
      });
      message = packedBufferMessage;
    } else {
      Uint8List bytes = utf8.encode(jsonEncode(outboundMessage));
      packedBufferMessage =
          await channel.invokeMethod('packMessage', <String, dynamic>{
        'configJson': configJson,
        'credentialJson': credentialsJson,
        'payload': bytes,
        'recipientKeys': keys.recipientKeys,
        'senderVk': keys.senderVk,
      });
      var outboundPackedMessage = utf8.decode(packedBufferMessage?.cast<int>());
      message = outboundPackedMessage;
    }

    var forwardBufferMessage;

    if (keys.routingKeys != null && keys.routingKeys.isNotEmpty && outboundMessage['@type'] != MessageType.KeylistUpdateMessage) {
      print('WE ARE GOING TO OD FORWARD');
      for (var routingKey in keys.routingKeys) {

        Object forwardMessage = createForwardMessage(keys.recipientKeys[0], message);
        List<int> forwardMessageBuffer = utf8.encode(jsonEncode(forwardMessage));
        if (Platform.isIOS) {
          forwardBufferMessage = await channel.invokeMethod('packMessage', <String, dynamic>{
            'configJson': configJson,
            'credentialsJson': credentialsJson,
            'payload': jsonEncode(forwardMessage),
            'recipientKeys': [routingKey],
            'senderVk': keys.senderVk,
          });
          return message = forwardBufferMessage;
        } else {
          forwardBufferMessage = await channel.invokeMethod('packMessage', <String, dynamic>{
            'configJson': configJson,
            'credentialJson': credentialsJson,
            'payload': forwardMessageBuffer,
            'recipientKeys': [routingKey],
            'senderVk': keys.senderVk,
          });
          var message = utf8.decode(packedBufferMessage?.cast<int>());
          return message;
        }
      }
    } else {
      return message;
    }
  } catch (exception) {
    throw exception;
  }
}

Future verify(
  String configJson,
  String credentialsJson,
  Message message,
  String field,
) async {
  Map<String, dynamic> data = jsonDecode(message.data);

  var signerVerkey = data['signer'];
  var signedData = base64Decode(data['sig_data']);
  var signature = base64Decode(data['signature']);

  bool isValid;

  if (Platform.isIOS) {
    isValid = await channel.invokeMethod('cryptoVerify', <String, dynamic>{
      'configJson': configJson,
      'credentialJson': credentialsJson,
      'signVerkeyJson': signerVerkey,
      'messageJson': signedData,
      'signatureRawJson': signature
    });
  } else {
    isValid = await channel.invokeMethod('cryptoVerify', <String, dynamic>{
      'configJson': configJson,
      'credentialJson': credentialsJson,
      'signVerkey': signerVerkey,
      'messageRaw': signedData,
      'signatureRaw': signature
    });
  }

  String connectionInOriginalMessage =
      new String.fromCharCodes(signedData.sublist(8, signedData.length));

  if (isValid) {
    var originalMessage = {
      '@type': message.type,
      '@id': message.id,
      '$field': connectionInOriginalMessage,
    };
    return originalMessage;
  } else {
    throw ErrorDescription('Signature is not valid!');
  }
}

Uint8List timestamp() {
  var time = DateTime.now().millisecondsSinceEpoch;
  List<int> bytes = [];
  for (var i = 0; i < 8; i++) {
    var byte = time & 0xff;
    bytes.add(byte);
    time = ((time - byte) / 256) as int;
  }
  return Uint8List.fromList(bytes.reversed.toList());
}

dynamic sign(
  String configJson,
  String credentialsJson,
  String signerVerkey,
  message,
  field,
) async {
  try {
    Uint8List dataBuffer =
        timestamp() + utf8.encode(jsonEncode(message['$field']));
    var signatureBuffer;
    if (Platform.isIOS) {
      signatureBuffer =
          await channel.invokeMethod('cryptoSign', <String, dynamic>{
        'configJson': configJson,
        'credentialJson': credentialsJson,
        'signerVerkey': signerVerkey,
        'messageRaw': jsonEncode(message['$field']),
      });
    } else {
      signatureBuffer =
          await channel.invokeMethod('cryptoSign', <String, dynamic>{
        'configJson': configJson,
        'credentialJson': credentialsJson,
        'signerVerkey': signerVerkey,
        'messageRaw': dataBuffer,
      });
    }

    message.remove(field);

    var signedMessage = {
      '@type': message['@type'],
      '@id': message['@id'],
      ...message,
      ['$field~sig']: {
        '@type':
            'did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/signature/1.0/ed25519Sha512_single',
        'signature': base64Encode(signatureBuffer),
        'sig_data': base64Encode(dataBuffer),
        'signer': signerVerkey,
      }
    };
    return signedMessage;
  } catch (exception) {
    throw exception;
  }
}

Keys getKeys(Connection connection, {InvitationDetails invitation}){
  Keys keys = new Keys(
    recipientKeys: invitation?.recipientKeys != null
        ? invitation.recipientKeys
        : connection?.theirDidDoc?.service[0]?.recipientKeys ?? [],
    routingKeys: invitation?.routingKeys != null
        ? invitation.routingKeys
        : connection?.theirDidDoc?.service[0]?.routingKeys ?? [],
    endpoint: invitation?.serviceEndpoint != null
        ? invitation.serviceEndpoint
        : connection?.theirDidDoc?.service[0]?.serviceEndpoint ?? [],
    senderVk: connection.verkey,
  );
  return keys;
}
