import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // BEYAZ EKRAN
      appBar: AppBar(
        title: Text("BooMovies Ana Sayfa"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Yazıları görünür kılmak için
        elevation: 0, // AppBar gölgesini kaldırır
      ),
      body: Center(
        child: Text(
          "Hoş geldin! Burası şimdilik boş.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}