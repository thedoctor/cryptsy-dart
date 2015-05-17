// Copyright (c) 2015, Matt Smith. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// A Cryptsy API v2 dart library.
///
/// Dart wrappers for calls to Cryptsy.com

library cryptsy;

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:js';

import 'package:http/http.dart' as http;
import "package:crypto/crypto.dart";

import 'package:cipher/cipher.dart' as cipher;
import 'package:cipher/impl/base.dart';
import 'package:cipher/digests/sha512.dart';
import 'package:cipher/digests/sha512t.dart';
import 'package:cipher/macs/hmac.dart';

part 'src/helpers.dart';

typedef http.Client ClientFactory();

http.Client _baseClient() => new http.Client();

class Cryptsy {
  final String uri;
  final String publicKey;
  final cipher.KeyParameter privateKey;
  final http.Client client;
  Map<String, Function> httpMethods;

  Cryptsy({String publicKey, String privateKey,
      String uri: 'https://api.cryptsy.com/api/v2',
      ClientFactory clientFactory: _baseClient})
      : publicKey = publicKey,
        privateKey = new cipher.KeyParameter(createUint8ListFromHexString(privateKey)),
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
    Uint8List queryBuffer = createUint8ListFromString(queryStringFromBody(body));
//    print(queryStringFromBody(body));
    //var hmac = new HMAC(, UTF8.encode(this.strPrivateKey));
    //hmac.add(queryBuffer);
    //digest = hmac.close();
    //print(CryptoUtils.bytesToHex(digest));
//    String hash(String input, {String name: "SHA-512"}) =>
//      CryptoUtils.bytesToHex(new cipher.Digest(name).process(new Uint8List.fromList(input.codeUnits)));
//    print(hash(queryStringFromBody(body)));

    HMac hmac = new cipher.Mac('SHA-512/HMAC')
      ..init(this.privateKey);
    
    hmac.update(queryBuffer, 0, queryBuffer.lengthInBytes);
    Uint8List sigBuffer = new Uint8List(hmac.macSize);
    hmac.doFinal(sigBuffer, 0);
    print(formatBytesAsHexString(sigBuffer));
    
    hmac.update(queryBuffer, 0, queryBuffer.lengthInBytes);
    hmac.doFinal(sigBuffer, 0);
    print(formatBytesAsHexString(sigBuffer));
    
    hmac.update(queryBuffer, 0, queryBuffer.lengthInBytes);
    hmac.doFinal(sigBuffer, 0);
    print(formatBytesAsHexString(sigBuffer));
    
//    print(formatBytesAsHexString(hmac.process(queryBuffer)));



    
    return formatBytesAsHexString(sigBuffer);
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

    /*
    return httpMethods[httpMethod](requestUrl, headers: headers, body: body)
        .then((http.Response response) => print(response.body))
        .catchError((error) => print(error));
    */
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

void main() {
  initCipher();
  var cc = new Cryptsy(
      publicKey: '85504563e6bcf11291c15993072159721aa326ff',
      privateKey: '93ccf095285043ac0ca02f1ac5fcb54a5b0f33cbfa545750777c176ca23138e4a06c79fe7e6f9a21');
  cc.balances();
}
