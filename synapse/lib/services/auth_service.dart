// Simple authentication service (in-memory for demo)
// In a real app, this would connect to a backend/API
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String? _userEmail;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;

  // Simple in-memory user storage (for demo purposes)
  final Map<String, String> _users = {
    'demo@synapse.com': 'demo123',
    'test@synapse.com': 'test123',
  };

  Future<bool> login(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_users.containsKey(email) && _users[email] == password) {
      _isLoggedIn = true;
      _userEmail = email;
      return true;
    }
    return false;
  }

  Future<bool> signUp(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_users.containsKey(email)) {
      // User already exists
      return false;
    }
    
    _users[email] = password;
    _isLoggedIn = true;
    _userEmail = email;
    return true;
  }

  void logout() {
    _isLoggedIn = false;
    _userEmail = null;
  }
}
