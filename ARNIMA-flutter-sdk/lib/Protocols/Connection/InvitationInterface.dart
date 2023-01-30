/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
class InvitationDetails {
  String id;
  String type;
  String label;
  List<String> recipientKeys;
  String serviceEndpoint;
  List<String> routingKeys;

  InvitationDetails({
    this.id,
    this.type,
    this.label,
    this.recipientKeys,
    this.serviceEndpoint,
    this.routingKeys,
  });

  InvitationDetails.fromJson(Map<String, dynamic> json){
    this.id = json['@id'];
    this.type = json['@type'];
    this.label = json['label'];
    this.recipientKeys = [];
    if (json['recipientKeys'] != null)
      json['recipientKeys'].forEach((key) => this.recipientKeys.add(key));
    this.serviceEndpoint = json['serviceEndpoint'];
    this.routingKeys = [];
    if (json['routingKeys'] != null)
      json['routingKeys'].forEach((key) => this.routingKeys.add(key));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['@id'] = this.id;
    data['@type'] = this.type;
    data['label'] = this.label;
    data['recipientKeys'] = this.recipientKeys;
    data['serviceEndpoint'] = this.serviceEndpoint;
    data['routingKeys'] = this.routingKeys;
    return data;
  }
}
