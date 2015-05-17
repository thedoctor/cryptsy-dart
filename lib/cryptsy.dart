// Copyright (c) 2015, Matt Smith. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// A Cryptsy API v2 dart library.
///
/// Dart wrappers for calls to Cryptsy.com

library cryptsy;

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart' as http;
import "package:crypto/crypto.dart";

part 'src/helpers.dart';

typedef http.Client ClientFactory();
typedef String Sha512Hmac();

http.Client _baseClient() => new http.Client();

class Cryptsy {
  final String uri;
  final String publicKey;
  final String privateKey;
  final http.Client client;
  Function hmac;
  Map<String, Function> httpMethods;

  Cryptsy({String publicKey, String privateKey,
      String uri: 'https://api.cryptsy.com/api/v2',
      Sha512Hmac this.hmac,
      ClientFactory clientFactory: _baseClient})
      : publicKey = publicKey,
        privateKey = privateKey,
        uri = uri,
        client = clientFactory() {

    this.httpMethods = {
      'POST': client.post,
      'PUT': client.put,
      'DELETE': (uri, {headers, body}) => client.delete(
          uri + '?' + queryStringFromBody(body), headers: headers),
      'GET': (uri, {headers, body}) =>
          client.get(uri + '?' + queryStringFromBody(body), headers: headers)
    };
    
  }

  String _signRequest(Map<String, String> body) {
    return hmac(queryStringFromBody(body));
  }

  Future<Map> _request(String method, {Map<String, String> body: null,
      String httpMethod: 'GET', String id: '', String action: ''}) {
    body = body == null ? {} : body;

    // This value is required for each request and must be > all previously
    // used nonces.
    body['nonce'] = '1431210455.571';
        //(new DateTime.now().millisecondsSinceEpoch / 1000.0).toString();

    Map<String, String> headers = {
      'Sign': this._signRequest(body),
      'Key': this.publicKey
    };
    
    print('3ae825cb19e3d79bbadff3b756b7fb78e1dd83448b5ddbdd1c079b7600d2d3201fd0b33b18dd0df623698e64cd9c2c9a78e6cdd9952012d3ebc398941e2743a8' == headers['Sign']);
    String requestUrl = [uri, method, id, action].join('/');

    print("ver('" + body['nonce'] + "', '" + headers['Sign'] + "')");

    return httpMethods[httpMethod](requestUrl, headers: headers, body: body)
        .then((http.Response response) => print(response.body))
        .catchError((error) => print(error));
  }

  Future<Map> markets() {
    return this._request("markets");
  }

  Future<Map> addresses() {
    return this._request("addresses");
  }
  Future<Map> balances() {
    return this._request("balances", body: {'type': 'all'});
  }
}
