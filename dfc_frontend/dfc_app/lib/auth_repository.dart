import '../models/user_model.dart';
import '../../api_service.dart';

class AuthRepository {
  final ApiService apiService;

  AuthRepository({required this.apiService});

  Future<UserModel> login(String email, String password) async {
    // Simulated V12 network delay & verification
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty.');
    }

    return UserModel(
      id: 'USR-8492',
      email: email,
      displayName: 'Heath Ewart',
      role: 'superuser',
      token: 'jwt_mock_token_123abc',
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<UserModel?> checkSession() async {
    // V12 checks secure storage for a token here. Returns null if invalid.
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }
}
