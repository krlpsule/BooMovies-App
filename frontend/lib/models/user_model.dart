import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart'; 

@JsonSerializable()
class User {
  final int? id;
  final String nameSurname;
  final String username;
  final String email;
  final String? password; 


  User({this.id, required this.nameSurname, required this.username, required this.email, this.password});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}