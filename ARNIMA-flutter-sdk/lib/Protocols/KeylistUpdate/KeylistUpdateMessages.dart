import 'package:AriesFlutterMobileAgent/Utils/MessageType.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

Object createKeylistUpdateMessage(String recipientKey){
  final data ={
    '@type': MessageType.KeylistUpdateMessage,
    '@id': uuid.v4(),
    'updates': [{
      'recipient_key': recipientKey,
      'action': "add",
    }],
    "~transport": {
      "return_route": "all"
    }
  };
  return data;
}

Object createMediateRequestMessage(){
  final data ={
    '@type': MessageType.MediateRequestMessage,
    '@id': uuid.v4(),
  };
  return data;
}
