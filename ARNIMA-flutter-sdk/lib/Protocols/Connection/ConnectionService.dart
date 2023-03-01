/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'dart:convert';

import 'package:AriesFlutterMobileAgent/Agent/AriesFlutterMobileAgent.dart';
import 'package:AriesFlutterMobileAgent/NetworkServices/Network.dart';
import 'package:AriesFlutterMobileAgent/Protocols/Connection/InvitationInterface.dart';
import 'package:AriesFlutterMobileAgent/Protocols/KeylistUpdate/KeylistUpdateService.dart';
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
        didJson,
        null,
        user,
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

  static Future acceptInvitation(didJson, InvitationDetails invitation, WalletData user) async {
    try {
      Connection connection = await createConnection(
        didJson,
        invitation,
        user,
      );

      if (user.defaultMediatorId.isNotEmpty){
        ConnectionData connectionDB = await DBServices.getConnection(user.defaultMediatorId);
        Connection mediatorConnection = Connection.fromJson(jsonDecode(connectionDB.connection));
        await KeylistUpdateService.sendKeylistUpdateRequest(user, mediatorConnection, verkey: connection.verkey);
      }


      var connectionRequest = createConnectionRequestMessage(
        connection,
        user.label,
      );
      connection.connection_state = ConnectionStates.REQUESTED.state;

      Keys keys = getKeys(connection, invitation: invitation);
      var outboundPackMessage = await packMessage(user.walletConfig, user.walletCredentials, connectionRequest, keys);

      Response response = await outboundAgentMessagePost(
        invitation.serviceEndpoint,
        outboundPackMessage,
      );

      await DBServices.saveConnections(
        ConnectionData(
          connection.verkey,
          jsonEncode(connection),
        ),
      );

      List<ConnectionData> dbConnections = await DBServices.getAllConnections();
      List<Connection> connections = [];
      dbConnections.forEach((element) {
        connections.add(Connection.fromJson(jsonDecode(element.connection)));
      });

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
        ),
      );

      var unpacked = await unPackMessage(
        user.walletConfig,
        user.walletCredentials,
        response.body,
      );

      await AriesFlutterMobileAgent.connectionRsponseType(user, jsonDecode(unpacked));
      await KeylistUpdateService.sendMediateRequest(user, connection, invitation: invitation);

      var createPairwiseDidResponse = await channel.invokeMethod('createAndStoreMyDids', <String, dynamic>{
        'configJson': user.walletConfig,
        'credentialJson': user.walletCredentials,
        'didJson': jsonEncode(didJson),
        'createMasterSecret': false,
      });

      await KeylistUpdateService.sendKeylistUpdateRequest(user, connection, invitation: invitation, verkey: createPairwiseDidResponse[1]);

      return true;
    } catch (exception) {
      throw exception;
    }
  }

  static Future<bool> acceptResponse(
    WalletData user,
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

      ConnectionData connectionDb = await DBServices.getConnection(inboundMessage.recipientVerkey);
      if (connectionDb.connectionId.isEmpty) {
        throw ErrorDescription('Connection for verKey ${inboundMessage.recipientVerkey} not found!');
      }
      Connection connection = Connection.fromJson(jsonDecode(connectionDb.connection));

      var receivedMessage = await verify(
        user.walletConfig,
        user.walletCredentials,
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
      Keys keys = getKeys(connection);

      var outboundPackMessage = await packMessage(
        user.walletConfig,
        user.walletCredentials,
        jsonDecode(trustPingMessage),
        keys
      );

      Response r = await outboundAgentMessagePost(
        keys.endpoint,
        outboundPackMessage,
      );

      await DBServices.updateConnection(
        ConnectionData(
          connectionDb.connectionId,
          jsonEncode(connection),
        ),
      );

      if (r.statusCode == 204)
        return true;

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
      Keys keys = getKeys(connection);
      var outboundPackMessage = await packMessage(configJson, credentialsJson, signedConnectionResponse, keys);
      await outboundAgentMessagePost(
        keys.endpoint,
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
    Object didJson,
    InvitationDetails invitation,
    WalletData user,
  ) async {
    try {

      var createPairwiseDidResponse =
          await channel.invokeMethod('createAndStoreMyDids', <String, dynamic>{
        'configJson': user.walletConfig,
        'credentialJson': user.walletCredentials,
        'didJson': jsonEncode(didJson),
        'createMasterSecret': false,
      });

      PublicKey publicKey = new PublicKey(
        id: createPairwiseDidResponse[0] + "#1",
        type: PublicKeyType.ED25519_SIG_2018.key,
        controller: createPairwiseDidResponse[0],
        publicKeyBase58: createPairwiseDidResponse[1],
      );

      Service service = new Service(
        id: createPairwiseDidResponse[0] + "#IndyAgentService",
        type: 'IndyAgent',
        priority: 0,
        serviceEndpoint: user.defaultMediatorId.isEmpty ? 'didcomm:transport/queue' : user.serviceEndpoint,
        recipientKeys: [createPairwiseDidResponse[1]],
        routingKeys: invitation?.routingKeys == null ? [] : invitation.routingKeys,
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
        invitation: user.defaultMediatorId.isEmpty ? null : invitation,
        verkey: createPairwiseDidResponse[1],
        state: ConnectionStates.INIT.state.toLowerCase(),
        theirLabel: invitation == null ? '' : invitation.label,
        createdAt: new DateTime.now().toString(),
        updatedAt: new DateTime.now().toString(),
        mediatorId: user.defaultMediatorId,
        role: 'invitee',
        autoAcceptConnection: true,
        multiUseInvitation: false,
      );

      return connection;
    } catch (exception) {
      print("Err in acceptInvitation $exception");
      throw exception;
    }
  }
}
