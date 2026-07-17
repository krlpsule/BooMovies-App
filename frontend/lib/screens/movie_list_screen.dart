import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider paketi
import '../services/internal_api_service.dart';
import '../services/user_manager.dart'; // UserManager importu

class MovieListScreen extends StatelessWidget {
  final InternalApiService _apiService = InternalApiService();

  MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
  
    final userManager = context.watch<UserManager>();
    final userId = userManager.userId;

    if (userId == null) {
      return const Center(child: Text("Giriş yapmalısınız."));
    }

    return FutureBuilder<List<dynamic>>(
      future: _apiService.getUserWatchlist(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Henüz film eklemediniz."));
        }

        final movies = snapshot.data!;
        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return ListTile(
              title: Text(movie['Title'] ?? 'Bilinmiyor'),
              subtitle: Text("Puan: ${movie['Rating'] ?? 'Yok'}"),
              trailing: const Icon(Icons.info_outline),
              onTap: () {
                // Detay sayfasına geçiş veya işlem seçenekleri buraya gelecek
              },
            );
          },
        );
      },
    );
  }
}
