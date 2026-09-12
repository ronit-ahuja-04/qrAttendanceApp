import 'dart:convert';
void main() {
  String json = '[{"id": "1", "name": "test"}]';
  try {
    final list = List<Map<String, dynamic>>.from(jsonDecode(json));
    print("Success: $list");
  } catch(e) {
    print("Error: $e");
  }
}
