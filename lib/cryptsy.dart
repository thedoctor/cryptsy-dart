// Copyright (c) 2015, Matt Smith. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// A Cryptsy API v2 dart library.
///
/// Dart wrappers for calls to Cryptsy.com

library cryptsy;

import 'dart:async';

import 'package:http/http.dart' as http;

part 'src/helpers.dart';

typedef http.Client ClientFactory();
typedef String Sha512Hmac(String message, String secret);

http.Client _baseClient() => new http.Client();

class Cryptsy {
  final String uri;
  final String publicKey;
  final String privateKey;
  final http.Client client;
  var hmac;
  Map<String, Function> httpMethods;

  Cryptsy({String publicKey, String privateKey,
      String uri: 'http://127.0.0.1:8081/cryptsy/api/v2',
      this.hmac,
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
    return hmac.apply([queryStringFromBody(body), this.privateKey]).toString();
  }

  Future<Map> _request(String method, {Map<String, String> body: null,
      String httpMethod: 'GET', String id: '', String action: ''}) {
    body = body == null ? {} : body;

    // This value is required for each request and "must" be > all previously
    // used nonces. (quotes because this hasn't been anecdotally true in cursory tests)
    body['nonce'] = (new DateTime.now().millisecondsSinceEpoch / 1000.0).toString();

    Map<String, String> headers = {
      'Sign': this._signRequest(body),
      'Key': this.publicKey
    };
    
    String requestUrl = [uri, method].join('/');
    if (id != '') {
      requestUrl = [requestUrl, id].join('/');
    }
    if (action != '') {
      requestUrl = [requestUrl, action].join('/');
    }
    print(requestUrl);
    print(headers);
    print(body);
    return httpMethods[httpMethod](requestUrl, headers: headers, body: body);
  }

  // Market calls
  Future<Map> markets() {
    return this._request("markets");
  }

  Future<Map> market(id) {
    return this._request("markets", id:id);
  }

  Future<Map> marketOrderbook(id, {int limit: 100, String otype: 'both', bool mine: false}) {
    return this._request("markets", id:id, 
        action: 'orderbook', 
        body:{'limit': limit.toString(), 'type': otype, 'mine': mine.toString()});
  }

  Future<Map> marketTradehistory(id, {int limit: 100, bool mine: false}) {
    return this._request("markets", id:id, 
        action: 'tradehistory', 
        body:{'limit': limit.toString(), 'mine': mine.toString()});
  }

  Future<Map> marketTriggers(id, {int limit: 100}) {
    return this._request("markets", id:id, 
        action: 'triggers', 
        body:{'limit': limit.toString()});
  }

  Future<Map> marketOhlc(id, {num start: 0, num stop: 0, String interval: "minute", int limit: 100}) {
    if (stop <= 0) {
      stop = new DateTime.now().millisecondsSinceEpoch / 1000.0;
    }
    return this._request("markets", id:id, 
        action: 'triggers', 
        body:{'start': start.toString(),
          'stop': stop.toString(),
          'interval': interval.toString(),
          'limit': limit.toString()});
  }
  
  // Currency stuff
  Future<Map> currencies() {
    return this._request("currencies");
  }

  Future<Map> currency(id) {
    return this._request("currencies", id:id);
  }

  Future<Map> currencyMarkets(id) {
    return this._request("currencies", id:id, action: 'markets');
  }

  // User shiz
  Future<Map> balances({String type: 'all'}) {
    return this._request("balances", body: {'type': type});
  }
  
  Future<Map> balance(id, {String type: 'all'}) {
    return this._request("balances", id: id, body: {'type': type});
  }
  
  Future<Map> deposits({id: 0, limit: 100}) {
    var body = {'limit': limit.toString()}; 
    if (id != 0) {
      return this._request("deposits", id: id, body: body);
    }
    return this._request("deposits", body: body);
  }
  
  Future<Map> withdrawals({id: 0, limit: 100}) {
    var body = {'limit': limit.toString()}; 
    if (id != 0) {
      return this._request("withdrawals", id: id, body: body);
    }
    return this._request("withdrawals", body: body);
  }
  
  Future<Map> addresses() {
    return this._request("addresses");
  }
  
  Future<Map> address(id) {
    return this._request("addresses", id: id);
  }

  Future<Map> transfers({int limit: 100}) {
    return this._request("transfers",
        body:{'limit': limit.toString()});
  }

  // Orders
  Future<Map> order(id) {
    return this._request("order", id:id);
  }

  Future<Map> createOrder(var marketId, int quantity, String orderType, num price) {
    return this._request("order", 
        body: {'marketid': marketId.toString(),
               'quantity': quantity.toString(),
               'ordertype': orderType.toString(),
               'price': price.toString()}, 
        httpMethod: 'POST');
  }
  
  Future<Map> removeOrder(id) {
    return this._request("order", id: id, httpMethod: 'DELETE');
  }
  
  // Triggers
  Future<Map> trigger(id) {
    return this._request("trigger", id:id);
  }

  Future<Map> createTrigger(var marketId, String orderType, num quantity, String comparison, num price, num orderPrice, {String expires: ''}) {
    return this._request("order", 
        body: {'marketid': marketId.toString(),
               'quantity': quantity.toString(),
               'comparison': comparison.toString(),
               'type': orderType.toString(),
               'price': price.toString(),
               'orderprice': orderPrice.toString(),
               'expires': expires}, 
        httpMethod: 'POST');
  }
  
  Future<Map> removeTrigger(id) {
    return this._request("trigger", id: id, httpMethod: 'DELETE');
  }
  
  // Converter
  Future<Map> conversion(id) {
    return this._request("converter", id:id);
  }

  Future<Map> convertCurrency(String fromCurrency, String toCurrency, {num sendingAmount: 0.0, num receivingAmount: 0.0, String tradeKey: '', num feePercent: 0.0}) {
    return this._request("converter", 
        body: {'fromcurrency': fromCurrency,
               'tocurrency': toCurrency,
               'sendingamount': sendingAmount.toString(),
               'receivingamount': receivingAmount.toString(),
               'tradekey': tradeKey,
               'feepercent': feePercent.toString()}, 
        httpMethod: 'POST');
  }
  
  
}
