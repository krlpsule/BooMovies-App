import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../services/internal_api_service.dart';
import '../services/user_manager.dart'; 

class BookListScreen extends StatelessWidget {
  final InternalApiService _apiService = InternalApiService();

  BookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userManager = context.watch<UserManager>();
    final userId = userManager.userId;

    if (userId == null) {
      return const Center(child: Text("Giriş yapmalısınız."));
    }

    return FutureBuilder<List<dynamic>>(
      future: _apiService.getUserLibrary(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Henüz kitap eklemediniz."));
        }

        final books = snapshot.data!;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              title: Text(book['Title'] ?? 'Başlıksız Kitap'),
              subtitle: Text("Puan: ${book['Rating'] ?? '0'}"),
              trailing: const Icon(Icons.info_outline),
              onTap: () {
                // Detay sayfasına geçiş için buraya Navigator eklenebilir
              },
            );
          },
        );
      },
    );
  }
}