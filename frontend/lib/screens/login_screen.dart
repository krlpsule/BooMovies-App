import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider paketini import ettik
import '../services/internal_api_service.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import '../services/user_manager.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final InternalApiService _apiService = InternalApiService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final result = await _apiService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (result != null && result['UserID'] != null) {
          final userManager = Provider.of<UserManager>(context, listen: false);
          userManager.setUserId(result['UserID']);
          if (result['Username'] != null) {
            userManager.setUserName(result['Username']);
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hatalı kullanıcı adı veya şifre!")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Bağlantı hatası: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("BooMovies Giriş")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Gerekli" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (val) => val!.isEmpty ? "Gerekli" : null,
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      child: Text("Giriş Yap"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Text("Hesabın yok mu? Kayıt Ol"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}