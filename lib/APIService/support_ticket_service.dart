import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:dude/APIService/Remote/network/BaseApiService.dart';
import 'package:dude/DudeScreens/AuthService.dart';

class SupportTicketService {
  static final String baseUrl = "https://api.dudee.online/api/v1/";

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken() ?? '';
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${baseUrl}auth/user/support-ticket/dashboard'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? {};
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  Future<List<dynamic>> getTickets({String status = 'active'}) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${baseUrl}auth/user/support-ticket/list?status=$status'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("data $data");
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load tickets');
    }
  }

  Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${baseUrl}auth/user/support-ticket/$ticketId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load ticket');
    }
  }

  Future<Map<String, dynamic>> createTicket({
    required String description,
    List<File>? images,
  }) async {
    final token = await AuthService.getToken() ?? '';
    var uri = Uri.parse('${baseUrl}auth/user/support-ticket/create');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] =
        'Bearer $token'; // Only set Authorization for multipart
    request.fields['description'] = description;
    if (images != null) {
      for (var img in images.take(3)) {
        final ext = img.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (ext == 'png')
          mimeType = 'image/png';
        else if (ext == 'gif')
          mimeType = 'image/gif';
        else if (ext == 'webp')
          mimeType = 'image/webp';
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            img.path,
            contentType: MediaType('image', mimeType.split('/').last),
          ),
        );
      }
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      print('Failed to create ticket: ${response.statusCode} ${response.body}');
      throw Exception(
        'Failed to create ticket: ${response.statusCode} ${response.body}',
      );
    }
  }
}
