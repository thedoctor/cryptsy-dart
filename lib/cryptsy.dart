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
  final cipher.Digest Sha512 = new SHA512Digest();

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

  Future<Map> _request(String action,
      {Map<String, String> body: null, String method: 'GET'}) {
    Map<String, String> headers = {'Key': this.publicKey};
    if (body == null) {
      body = {};
    }
    body['nonce'] = new DateTime.now().millisecondsSinceEpoch.toString();

    String query = '';
    body.forEach((key, value) {
      if (query != '') query += '&';
      query += '$key=$value';
    });
    Uint8List queryBuffer = new Uint8List.fromList(UTF8.encode(query));
    HMac hmac = new HMac(Sha512, Sha512.digestSize);
    hmac.init(new cipher.KeyParameter(this.privateKey));
    hmac.update(queryBuffer, 0, queryBuffer.lengthInBytes);
    Uint8List digest = new Uint8List(hmac.macSize);
    hmac.doFinal(digest, 0);

    headers['Sign'] = CryptoUtils.bytesToHex(digest.toList());
    print(headers);
    return httpMethods[method](uri, headers: headers, body: body)
        .then((String response) => JSON.decode(response))
        .catchError((error) => print(error));
  }

  Future<Map> markets() {
    return this._request("markets");
  }
}

void main() {
  var cc =
      new Cryptsy(publicKey: '298477553435e4c12b7', privateKey: 'dartthing');
  print(cc.markets());
}
