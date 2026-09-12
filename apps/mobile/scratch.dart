import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final facultyId = 'prof.pn@ves.ac.in';
  try {
    final response = await http.get(Uri.parse('http://localhost:3000/api/sessions/faculty/${Uri.encodeComponent(facultyId)}'));
    print(response.body);
  } catch (e) {
    print(e);
  }
}
