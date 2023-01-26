/*
  Copyright AyanWorks Technology Solutions Pvt. Ltd. All Rights Reserved.
  SPDX-License-Identifier: Apache-2.0
*/
import 'dart:convert';

import 'package:http/http.dart' as http;

Future<dynamic> postData(String url, String apiBody) async {
  try {
    var response = await http.post(
      url,
      body: apiBody,
      headers: {
        "Accept": 'application/json',
        'Content-Type': 'application/json',
      },
    );
    Map<String, dynamic> responseJson = jsonDecode(response.body);
    return responseJson;
  } catch (exception) {
    throw exception;
  }
}

Future<String> getStringData(String url) async {
  try {
    var response = await http.get(
      url,
      headers: {
        "Accept": 'application/json',
        'Content-Type': 'application/json',
      },
    );

    String data = response.body;
    return data;
  } catch (exception) {

    throw exception;
  }
}


Future<dynamic> getData(String url) async {
  try {
    var response = await http.get(
      url,
      headers: {
        "Accept": 'application/json',
        'Content-Type': 'application/json',
      },
    );

    String z = response.body.split('=')[1];
    var x = base64.normalize(z);
    List<int> c = base64.decode(x);
    var v = utf8.decode(c);
    return v;

    //Map<String, dynamic> responseJson = jsonDecode(a);     // that is how it was
    //return responseJson;
  } catch (exception) {
    throw exception;
  }
}

Future<dynamic> outboundAgentMessagePost(
  String url,
  Object apiBody,
) async {
  try {

    // print('AGENT POST MESSAGE DETAILS');
    // print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
    // print('URL => $url');
    // print('BODY => $apiBody');
    // print('vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');


    final response = await http.post(
      url,
      body: apiBody,
      headers: {
        "Accept": 'application/json',
        'Content-Type': 'application/ssi-agent-wire',
      },
    );


    //print('RESPONSE status code => ${response.statusCode}');
    //print('RESPONSE BODY bytes => ${response.bodyBytes}');
    //print('RESPONSE BODY string => ${response.body}');

    return response;
  } catch (exception) {
    throw exception;
  }
}
