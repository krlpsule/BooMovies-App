import 'package:flutter/material.dart';
import '../services/internal_api_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final InternalApiService _apiService = InternalApiService();
  bool _isLoading = false;

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Burada kendi API'nizdeki add_user yapısını kullanıyoruz
        await _apiService.addUser(
          _nameController.text,
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt başarılı! Giriş yapabilirsiniz.")),
        );
        Navigator.pop(context); // Login ekranına geri dön
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt başarısız: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Ol")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: InputDecoration(labelText: "Ad Soyad")),
              TextFormField(controller: _usernameController, decoration: InputDecoration(labelText: "Kullanıcı Adı")),
              TextFormField(controller: _emailController, decoration: InputDecoration(labelText: "E-posta")),
              TextFormField(controller: _passwordController, decoration: InputDecoration(labelText: "Şifre",), obscureText: true),
              SizedBox(height: 20),
              _isLoading ? CircularProgressIndicator() : ElevatedButton(
                onPressed: _handleSignUp,
                child: Text("Kayıt Ol"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}