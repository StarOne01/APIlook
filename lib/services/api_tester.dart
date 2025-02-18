import 'package:http/http.dart' as http;

Future<void> testConnection() async {
  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/test'));
    print('Response: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
