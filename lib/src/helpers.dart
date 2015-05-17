part of cryptsy;

// Lifted from the cipher package's test suite.

Uint8List createUint8ListFromString( String s ) {
  var ret = new Uint8List(s.length);
  for( var i=0 ; i<s.length ; i++ ) {
    ret[i] = s.codeUnitAt(i);
  }
  return ret;
}

Uint8List createUint8ListFromHexString(String hex) {
  var result = new Uint8List(hex.length~/2);
  for( var i=0 ; i<hex.length ; i+=2 ) {
    var num = hex.substring(i, i+2);
    var byte = int.parse( num, radix: 16 );
    result[i~/2] = byte;
  }
  return result;
}

String formatBytesAsHexString(Uint8List bytes) {
  var result = new StringBuffer();
  for( var i=0 ; i<bytes.lengthInBytes ; i++ ) {
    var part = bytes[i];
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}


String queryStringFromBody(Map<String, String> body) {
  String query = '';
  return body.keys.map((k) {
    return "${Uri.encodeComponent(k)}=${Uri.encodeComponent(body[k])}";
  }).join("&");
}