// Copyright (c) 2015, Matt Smith. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// A Cryptsy API v2 dart library.
///
/// Dart wrappers for calls to Cryptsy.com

library cryptsy;

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cipher/cipher.dart' as cipher;
import 'package:cipher/impl/server.dart';
import 'package:cipher/digests/sha512.dart';
import 'package:cipher/macs/hmac.dart';
import 'package:http/http.dart' as http;
//import 'package:http/browser_client.dart';

//part 'src/client.dart';

typedef http.Client ClientFactory();

http.Client _baseClient() => new http.Client();

class Cryptsy {
  String uri;
  Uint8List privateKey;
  String publicKey;
  http.Client client;
  Map<String, Function> httpMethods;

  Cryptsy({String this.publicKey, String privateKey,
      this.uri: 'https://api.cryptsy.com/api/v2/',
      clientFactory: _baseClient}) {

    this.client = clientFactory();
    this.privateKey = new Uint8List.fromList(UTF8.encode(privateKey));

    this.httpMethods = {
      'POST': client.post,
      'PUT': client.put,
      'DELETE': (uri, {headers, body}) => client.delete(uri, headers:headers),
      'GET': (uri, {headers, body}) => client.get(uri, headers:headers)
    };
  }

  Future<Map> _request(String method,
      {Map<String, String> body: null, String httpMethod: 'GET', String id: '', String action: ''}) {
    Map<String, String> headers = {'Key': this.publicKey};
    if (body == null) {
      body = {};
    }
    body['nonce'] = (new DateTime.now().millisecondsSinceEpoch * 9.09).toString();

    String query = '';
    body.forEach((key, value) {
      if (query != '') query += '&';
      query += '$key=$value';
    });
    print(query);
    Uint8List queryBuffer = new Uint8List.fromList(UTF8.encode(query));
    HMac hmac = new cipher.Mac('SHA-512/HMAC')
         ..init(new cipher.KeyParameter(this.privateKey));

    hmac.update(queryBuffer, 0, queryBuffer.lengthInBytes);
    Uint8List digest = new Uint8List(hmac.macSize);
    hmac.doFinal(digest, 0);

    headers['Sign'] = CryptoUtils.bytesToHex(digest.toList());
    if (id != '') {
      id = '/' + id;
    }
    if (action != '') {
      action = '/'+action;
    }
    query = '?'+query;
    print(uri+method+id+action+query);
    print(headers);
    return httpMethods[httpMethod](uri+method+id+action+query, headers: headers, body: body)
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
    return this._request("balances", body: {'type':'all'});
  }
}

void main() {
  initCipher();
  var cc =
      new Cryptsy(publicKey: '85504563e6bcf11291c15993072159721aa326ff', privateKey: '93ccf095285043ac0ca02f1ac5fcb54a5b0f33cbfa545750777c176ca23138e4a06c79fe7e6f9a21');
  //cc.addresses();
  cc.balances();
}
