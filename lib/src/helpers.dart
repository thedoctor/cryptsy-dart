part of cryptsy;

String queryStringFromBody(Map<String, String> body) {
  String query = '';
  return body.keys.map((k) {
    return "${Uri.encodeComponent(k)}=${Uri.encodeComponent(body[k])}";
  }).join("&");
}