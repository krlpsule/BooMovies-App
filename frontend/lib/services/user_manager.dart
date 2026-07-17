
class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  int? _userId;

  int? get userId => _userId;

  void setUserId(int id) {
    _userId = id;
  }

  void logout() {
    _userId = null;
  }
}