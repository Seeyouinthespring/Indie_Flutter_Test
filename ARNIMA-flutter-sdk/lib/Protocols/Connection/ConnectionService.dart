/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'dart:convert';

import 'package:AriesFlutterMobileAgent/Agent/AriesFlutterMobileAgent.dart';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Protocols/TrustPing/TrustPingMessages.dart';
import 'package:AriesFlutterMobileAgent/Protocols/TrustPing/TrustPingState.dart';
import 'package:AriesFlutterMobileAgent/Storage/DBModels.dart';
import 'package:AriesFlutterMobileAgent/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'ConnectionInterface.dart';
import 'ConnectionMessages.dart';
import 'ConnectionStates.dart';

class ConnectionService {
  static Future createInvitation(
    configJson,
    credentialsJson,
    didJson,
  ) async {
    try {
      WalletData user = await DBServices.getWalletData();
      Connection connection = await createConnection(
        configJson,
        credentialsJson,
        didJson,
        '',
      );
      await DBServices.saveConnections(
        ConnectionData(
          connection.verkey,
          jsonEncode(connection),
        ),
      );

      var invitation = createInvitationMessage(
        connection,
        user.label,
      );

      connection.connection_state = ConnectionStates.INVITED.state;
      String serviceEndpoint = await DBServices.getServiceEndpoint();
      String encodedUrl =
          encodeInvitationFromObject(invitation, serviceEndpoint);
      return encodedUrl;
    } catch (exception) {
      throw exception;
    }
  }

  static Future acceptInvitation(
    configJson,
    credentialsJson,
    didJson,
    invite,
  ) async {
    try {

      print('Accept invitation step 1');

      var user = await DBServices.getWalletData();
      print('Accept invitation step 2');
      var invitation = jsonDecode(invite);
      print('Accept invitation step 3');
      Connection connection = await createConnection(
        configJson,
        credentialsJson,
        didJson,
        invitation['label'],
      );
      print('Accept invitation step 4');
      var connectionRequest = createConnectionRequestMessage(
        connection,
        user.label,
      );
      print('Accept invitation step 5');
      connection.connection_state = ConnectionStates.REQUESTED.state;
      var outboundMessage = createOutboundMessage(
        connection,
        connectionRequest,
        invitation,
      );
      print('Accept invitation step 6');

      var outboundPackMessage = await packMessage(configJson, credentialsJson, outboundMessage);

      print('Accept invitation step 7');

      Response response = await outboundAgentMessagePost(
        invitation['serviceEndpoint'],
        outboundPackMessage,
      );

      print('Accept invitation step 8');

      await DBServices.saveConnections(
        ConnectionData(
          connection.verkey,
          jsonEncode(connection),
        ),
      );


      print('RESPONSE TO CONNECTION REQUEST => ${response.body}');
      print('RESPONSE status code TO CONNECTION REQUEST => ${response.statusCode}');

      if (response.statusCode == 204)
        return false;


      await DBServices.updateWalletData(
        WalletData(
          user.walletConfig,
          user.walletCredentials,
          user.label,
          user.publicDid,
          user.verkey,
          user.masterSecretId,
          user.serviceEndpoint,
          user.routingKey,
          connection.verkey,
          //incomingRouterResponse['serviceEndpoint'],
          //incomingRouterResponse['routingKeys'],
        ),
      );


      var unpacked = await unPackMessage(
        user.walletConfig,
        user.walletCredentials,
        response.body,
      );

      print('UNPACKED => ${jsonDecode(unpacked)}');

      var b = await AriesFlutterMobileAgent.connectionRsponseType(user, jsonDecode(unpacked));


      return true;
    } catch (exception) {
      throw exception;
    }
  }

  static Future<bool> acceptResponse(
    String configJson,
    String credentialsJson,
    InboundMessage inboundMessage,
  ) async {
    try {
      var typeMessageObj = jsonDecode(inboundMessage.message);

      if (!typeMessageObj.containsKey('connection~sig')) {
        throw new ErrorDescription('message is not valid!');
      }

      var typeMessage = Message(
        typeMessageObj['@id'],
        typeMessageObj['@type'],
        jsonEncode(typeMessageObj['connection~sig']),
      );

      ConnectionData connectionDb =
          await DBServices.getConnection(inboundMessage.recipientVerkey);

      if (connectionDb.connectionId.isEmpty) {
        throw ErrorDescription(
            'Connection for verKey ${inboundMessage.recipientVerkey} not found!');
      }

      Connection connection =
          Connection.fromJson(jsonDecode(connectionDb.connection));

      var receivedMessage = await verify(
        configJson,
        credentialsJson,
        typeMessage,
        'connection',
      );

      var receivedDetails = jsonDecode(receivedMessage['connection']);

      connection.theirDid = receivedDetails['DID'];
      DidDoc didDocValue = DidDoc.convertToObject(receivedDetails['DIDDoc']);
      connection.theirDidDoc = didDocValue;

      var now = new DateTime.now().toString();
      connection.state = ConnectionStates.COMPLETE.state;
      connection.updatedAt = now;

      if (connection.theirDidDoc.service[0].recipientKeys[0].isEmpty) {
        throw ErrorDescription(
            'Connection Data with verKey ${connection.verkey} has no recipient keys.');
      }

      String trustPingMessage = createTrustPingMessage();

      var outboundMessage = createOutboundMessage(connection, trustPingMessage);

      var outboundPackMessage = await packMessage(
        configJson,
        credentialsJson,
        outboundMessage,
      );

      Response r = await outboundAgentMessagePost(
        jsonDecode(outboundMessage)['endpoint'],
        outboundPackMessage,
      );

      await DBServices.updateConnection(
        ConnectionData(
          connectionDb.connectionId,
          jsonEncode(connection),
        ),
      );

      await DBServices.storeTrustPing(
        TrustPingData(
          connectionDb.connectionId,
          jsonDecode(trustPingMessage)['@id'],
          trustPingMessage,
          TrustPingState.SENT.state,
        ),
      );
      return true;
    } catch (exception) {
      throw exception;
    }
  }

  static Future<bool> acceptRequest(
    String configJson,
    String credentialsJson,
    InboundMessage inboundMessage,
  ) async {
    try {
      ConnectionData connectionDB =
          await DBServices.getConnection(inboundMessage.recipientVerkey);
      var connection = jsonDecode(connectionDB.connection);

      if (!connection) {
        throw new ErrorDescription(
            'Connection for verkey ${inboundMessage.recipientVerkey} not found!');
      }

      var typeMessage = jsonDecode(inboundMessage.message);

      if (!typeMessage['connection']) {
        throw new ErrorDescription('Invalid message');
      }

      var requestConnection = typeMessage['connection'];

      connection.theirDid = requestConnection.DID;
      connection.theirDidDoc = requestConnection.DIDDoc;
      connection.theirLabel = typeMessage.label;
      connection.state = ConnectionStates.RESPONDED.state;
      connection.updatedAt = new DateTime.now();

      if (!connection.theirDidDoc.service[0].recipientKeys[0]) {
        throw new ErrorDescription(
            'Connection with verkey ${connection.verkey} has no recipient keys.');
      }

      ConnectionData storeDataintoDB = ConnectionData(
        connectionDB.connectionId,
        jsonEncode(connection),
      );

      var connectionResponse = createConnectionResponseMessage(
        connection,
        typeMessage['@id'],
      );

      var signedConnectionResponse = await sign(
        configJson,
        credentialsJson,
        connection.verkey,
        connectionResponse,
        'connection',
      );
      Map<String, dynamic> outboundMessage =
          createOutboundMessage(connection, signedConnectionResponse);
      var outboundPackMessage =
          await packMessage(configJson, credentialsJson, outboundMessage);
      await outboundAgentMessagePost(
        outboundMessage['endpoint'],
        jsonEncode(outboundPackMessage),
      );
      await DBServices.saveConnections(storeDataintoDB);
      return true;
    } catch (exception) {
      print('Error in Catch: acceptRequest:: $exception');
      throw exception;
    }
  }

  static Future createConnection(
    String configJson,
    String credentialsJson,
    Object didJson,
    String label,
  ) async {
    try {
      WalletData user = await DBServices.getWalletData();

      var createPairwiseDidResponse =
          await channel.invokeMethod('createAndStoreMyDids', <String, dynamic>{
        'configJson': configJson,
        'credentialJson': credentialsJson,
        'didJson': jsonEncode(didJson),
        'createMasterSecret': false,
      });

      var apibody = {
        'publicVerkey': user.verkey,
        'verkey': createPairwiseDidResponse[1]
      };

      final String url =
          user.serviceEndpoint.replaceAll(RegExp('endpoint'), '');

      // await postData(
      //   url + "verkey",
      //   jsonEncode(apibody),
      // );

      PublicKey publicKey = new PublicKey(
        id: createPairwiseDidResponse[0] + "#1",
        type: PublicKeyType.ED25519_SIG_2018.key,
        controller: createPairwiseDidResponse[0],
        publicKeyBase58: createPairwiseDidResponse[1],
      );

      Service service = new Service(
        id: createPairwiseDidResponse[0] + ";indy",
        type: 'IndyAgent',
        priority: 0,
        serviceEndpoint: 'didcomm:transport/queue', //user.serviceEndpoint,
        recipientKeys: [createPairwiseDidResponse[1]],
        routingKeys: user.routingKey == null ? [] : [user.routingKey],
      );

      Authentication auth = new Authentication(
        type: PublicKeyType.ED25519_SIG_2018.key,
        publicKey: publicKey.id,
      );

      DidDoc didDoc = new DidDoc(
        context: 'https://w3id.org/did/v1',
        id: createPairwiseDidResponse[0],
        publicKey: [publicKey],
        authentication: [auth],
        service: [service],
      );

      Connection connection = new Connection(
        did: createPairwiseDidResponse[0],
        didDoc: didDoc,
        verkey: createPairwiseDidResponse[1],
        state: ConnectionStates.INIT.state,
        theirLabel: label,
        createdAt: new DateTime.now().toString(),
        updatedAt: new DateTime.now().toString(),
      );

      return connection;
    } catch (exception) {
      print("Err in acceptInvitation $exception");
      throw exception;
    }
  }
}
