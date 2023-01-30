/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'package:AriesFlutterMobileAgent/Protocols/Connection/InvitationInterface.dart';
import 'package:AriesFlutterMobileAgent/Utils/DidDoc.dart';

class Connection {
  String did;
  DidDoc didDoc;
  String verkey;
  String state;
  String theirLabel;
  String theirDid;
  DidDoc theirDidDoc;
  String createdAt;
  String updatedAt;
  InvitationDetails invitation;
  String mediatorId;
  String role;
  bool multiUseInvitation;
  bool autoAcceptConnection;


  // ignore: non_constant_identifier_names
  String get connection_state => state;

  // ignore: non_constant_identifier_names
  set connection_state(String states) {
    this.state = states;
  }

  Connection({
    this.did,
    this.didDoc,
    this.verkey,
    this.state,
    this.theirDid,
    this.theirDidDoc,
    this.theirLabel,
    this.createdAt,
    this.updatedAt,
    this.invitation,
    this.role,
    this.mediatorId,
    this.autoAcceptConnection,
    this.multiUseInvitation
  });

  Connection.fromJson(Map<String, dynamic> json) {
    did = json['did'];

    theirDid = json['theirDid'];

    if (json['theirDidDoc'] != null) {
      var theirDidDocObj = new DidDoc.fromJson(json['theirDidDoc']);
      theirDidDoc = theirDidDocObj;
    } else {
      theirDidDoc = json['theirDidDoc'];
    }
    verkey = json['verkey'];
    state = json['state'];
    theirLabel = json['theirLabel'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    var didDocObj = new DidDoc.fromJson(json['didDoc']);
    if (json['didDoc'] != null) {
      didDoc = didDocObj;
    } else {
      didDoc = null;
    }
    if (json['invitation'] != null)
      invitation = new InvitationDetails.fromJson(json['invitation']);
    mediatorId = json['mediatorId'];
    role = json['role'];
    autoAcceptConnection = json['autoAcceptConnection'];
    multiUseInvitation = json['multiUseInvitation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['did'] = this.did;
    if (this.didDoc != null) {
      data['didDoc'] = this.didDoc.toJson();
    }
    data['theirDid'] = this.theirDid;
    data['theirDidDoc'] = this.theirDidDoc;
    data['verkey'] = this.verkey;
    data['state'] = this.state;
    data['theirLabel'] = this.theirLabel;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.invitation != null)
      data['invitation'] = this.invitation.toJson();
    data['mediatorId'] = this.mediatorId;
    data['role'] = this.role;
    data['autoAcceptConnection'] = this.autoAcceptConnection;
    data['multiUseInvitation'] = this.multiUseInvitation;
    return data;
  }
}
