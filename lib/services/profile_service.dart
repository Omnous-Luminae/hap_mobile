import '../models/user.dart';
import 'auth_service.dart';

class ProfileService {
  static Future<User?> updateProfile(Map<String, dynamic> fields) {
    return AuthService.updateProfile(fields);
  }
}
