import 'dart:html' as html;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<void> downloadWithAjax(String url, String token, String filename) async {
  final response = await http.get(
    Uri.parse(url),
    headers: { 'Authorization': 'Bearer $token' }
  );
  if (response.statusCode == 200) {
    final blob = html.Blob([response.bodyBytes]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: blobUrl)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(blobUrl);
  } else {
    throw Exception('Failed to download');
  }
}
