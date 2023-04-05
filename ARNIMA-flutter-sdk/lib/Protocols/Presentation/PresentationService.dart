/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'dart:convert';

import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionInterface.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/ConnectionService.dart';
import 'package:AriesFlutterMobileAgent/Protocols/ProblemReport/ProblemReportMessages.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:AriesFlutterMobileAgent/Utils/utils.dart';
import 'package:http/http.dart';

import '../../Storage/DBModels.dart';
import 'PresentationInterface.dart';
import 'PresentationMessages.dart';
import 'PresentationState.dart';

class PresentationService {
  static Future<dynamic> receivePresentProofRequest(
    String messageId,
    InboundMessage inboundMessage,
  ) async {
    try {
      ConnectionData connectionDB = await DBServices.getConnection(inboundMessage.recipientVerkey);
      Connection connection = Connection.fromJson(jsonDecode(connectionDB.connection));

      var message = jsonDecode(inboundMessage.message);
      var presentationRequest = message['request_presentations~attach'];
      var proofRequest = decodeBase64(presentationRequest[0]['data']['base64']);

      Presentation presentproofRecord = new Presentation(
        connectionId: connectionDB.connectionId,
        theirLabel: connection.theirLabel,
        threadId: message['@id'],
        presentationRequest: proofRequest,
        state: PresentationState.STATE_PRESENTATION_RECEIVED.state,
        createdAt: new DateTime.now().toString(),
        updatedAt: new DateTime.now().toString(),
      );

      await DBServices.storePresentation(
        PresentationData(
          message['@id'],
          connection.verkey,
          jsonEncode(presentproofRecord),
        ),
      );

      inboundMessage.message = message;

      MessageData messageData = new MessageData(
        auto: false,
        connectionId: inboundMessage.recipientVerkey,
        isProcessed: true,
        messageId: messageId + '',
        messages: jsonEncode(inboundMessage),
        thId: message['@id'],
      );
      await DBServices.saveMessages(messageData);
      return connection;
    } catch (exception) {
      print("Err in receivePresentProofRequest$exception");
      throw exception;
    }
  }

  static Future<bool> declineProofRequest(InboundMessage inboundMessage) async {


    WalletData sdkDB = await DBServices.getWalletData();
    Connection connection = await ConnectionService.getConnection(inboundMessage.recipientVerkey);
    Keys keys = getKeys(connection);

    var creatPresentationMessageObject = createProblemReportMessage(
      "Proof request was reject",
      inboundMessage.message['@id'],
    );

    var outboundPackMessage = await packMessage(
      sdkDB.walletConfig,
      sdkDB.walletCredentials,
      creatPresentationMessageObject,
      keys,
    );
    Response r = await outboundAgentMessagePost(
      keys.endpoint,
      outboundPackMessage,
    );
    print("response => ${r.statusCode}");

    print('ID => ${inboundMessage.message['@id']}');

    PresentationData presentationData = await DBServices.getPresentationDataById(inboundMessage.message['@id']);
    Presentation presentation = Presentation.fromJson(jsonDecode(presentationData.presentation));

    presentation.isVerified = true;
    presentation.state = PresentationState.STATE_PRESENTATION_DECLINED.state;

    return await DBServices.storePresentation(
      PresentationData(
        presentationData.presentationId,
        presentationData.connectionId,
        jsonEncode(presentation),
      ),
    );

  }

  static Future<bool> createPresentProofRequest(InboundMessage inboundMessage) async {
    try {
      WalletData sdkDB = await DBServices.getWalletData();
      ConnectionData connectionDB = await DBServices.getConnection(inboundMessage.recipientVerkey);
      Connection connection = Connection.fromJson(jsonDecode(connectionDB.connection));

      var message = inboundMessage.message;

      var presentationRequest = message['request_presentations~attach'];

      var proofRequest = jsonDecode(decodeBase64(presentationRequest[0]['data']['base64']));

      var presentation = await channel.invokeMethod(
        'proverSearchCredentialsForProofReq',
        <String, dynamic>{
          'configJson': sdkDB.walletConfig,
          'credentialJson': sdkDB.walletCredentials,
          'proofRequest': jsonEncode(proofRequest),
          'did': sdkDB.publicDid,
          'masterSecretId': sdkDB.masterSecretId,
        },
      );
      //212

      var creatPresentationMessageObject;
      if (presentation == "false"){
        print('condition then');
        creatPresentationMessageObject = createProblemReportMessage("The requested credentials were not found", message['@id'],);
      } else {
        print('condition else');
        creatPresentationMessageObject = createPresentationMessage(presentation, '', message['@id'],);
      }

      print('??????????????? presentation => ${presentation}');

      Presentation presentproofRecord = Presentation(
        connectionId: connectionDB.connectionId,
        theirLabel: connection.theirLabel,
        threadId: message['@id'],
        presentationRequest: jsonEncode(proofRequest),
        presentation: jsonEncode(presentation),
        state: presentation == "false" ? PresentationState.STATE_PRESENTATION_DONE.state : PresentationState.STATE_PRESENTATION_SENT.state,
        createdAt: new DateTime.now().toString(),
        updatedAt: new DateTime.now().toString(),
      );

      Keys keys = getKeys(connection);

      print("CREATED MESSAGE => ${creatPresentationMessageObject}");

      var outboundPackMessage = await packMessage(
        sdkDB.walletConfig,
        sdkDB.walletCredentials,
        creatPresentationMessageObject,
        keys,
      );
      Response r = await outboundAgentMessagePost(
        keys.endpoint,
        outboundPackMessage,
      );
      print("response => ${r.statusCode}");

      await DBServices.storePresentation(
        PresentationData(
          message['@id'],
          connection.verkey,
          jsonEncode(presentproofRecord),
        ),
      );
      return true;
    } catch (exception) {
      print("Exception in createPresentProofRequest $exception");
      throw exception;
    }
  }

  static Future<void> handlePresentationAck(InboundMessage inboundMessage) async {

    var message = jsonDecode(inboundMessage.message);
    String id = message["~thread"]["thid"];
    PresentationData presentationData = await DBServices.getPresentationDataById(id);
    Presentation presentation = Presentation.fromJson(jsonDecode(presentationData.presentation));

    presentation.isVerified = true;
    presentation.state = PresentationState.STATE_PRESENTATION_DONE.state;

    await DBServices.storePresentation(
      PresentationData(
        presentationData.presentationId,
        presentationData.connectionId,
        jsonEncode(presentation),
      ),
    );
  }
}
