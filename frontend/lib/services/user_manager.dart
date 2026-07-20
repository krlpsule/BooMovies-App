import 'package:flutter/material.dart';

class UserManager extends ChangeNotifier {
  int? _userId;
  String? _userName;

  int? get userId => _userId;

  void setUserId(int id) {
    _userId = id;
    notifyListeners(); 
  }

  String? getUserNameAsString() {
    return _userName?.toString();
  }

  void logout() {
    _userId = null;
    notifyListeners();
  }
}