import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/api/auth';
  // http://10.0.2.2:8080

  static Future<String> userSignUp(
      String username,
      String firstName,
      String lastName,
      String phoneNumber,
      String email,
      String password,
      String role,
      List<String> userInterestedStates,
      String interestedCourse
      ) async {
    final String endpoint = '$_baseUrl/${role}Signup';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userName': username,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
        'role': role,
        'userInterestedStateOfCounsellors': userInterestedStates,
        'interestedCourse': interestedCourse,
      }),
    );

    final data = jsonDecode(response.body);
    return data['message'];
  }

  static Future<String> counsellorSignUp(
      String username,
      String firstName,
      String lastName,
      String phoneNumber,
      String email,
      String password,
      String role,
      double? ratePerYear,
      List<String> expertise,
      String stateOfCounsellor
      ) async {
    final String endpoint = '$_baseUrl/${role}Signup';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userName': username,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
        'role': role,
        'ratePerYear': ratePerYear,
        'expertise': expertise,
        'stateOfCounsellor': stateOfCounsellor,
      }),
    );

    final data = jsonDecode(response.body);
    return data['message'];
  }

static Future<String> signIn(String identifier, String password) async {
    try {
      for (String role in ['user', 'counsellor', 'admin']) {
        final String endpoint = '$_baseUrl/${role}Signin';

        final uri = Uri.parse(endpoint).replace(queryParameters: {
          'identifier': identifier,
          'password': password,
        });

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return role; // Return the role if sign-in is successful
        }
      }
      return "Invalid credentials or user not found.";
    } catch (e) {
      return "An error occurred: $e";
    }
  }
}
