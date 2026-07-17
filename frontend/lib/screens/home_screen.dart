import 'package:flutter/material.dart';
import '../screens/search_result_screen.dart';
import '../services/user_manager.dart';
import '../screens/movie_list_screen.dart';
import '../screens/book_list_screen.dart';

final int? currentUserId = UserManager().userId;

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  String _searchType = 'book';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // --- Arama Filtreleri ---
  Widget _buildSearchFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Kitap Ara"),
            selected: _searchType == 'book',
            onSelected: (bool selected) => setState(() => _searchType = 'book'),
          ),
          const SizedBox(width: 10),
          ChoiceChip(
            label: const Text("Film Ara"),
            selected: _searchType == 'movie',
            onSelected: (bool selected) =>
                setState(() => _searchType = 'movie'),
          ),
        ],
      ),
    );
  }

  // --- Modern Arama Çubuğu ---
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SearchResultsScreen(query: value, searchType: _searchType),
              ),
            );
          }
        },
        decoration: InputDecoration(
          hintText: _searchType == 'book'
              ? "Kitap ismi ara..."
              : "Film ismi ara...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BookListScreen(),
      MovieListScreen(),
      const Center(child: Text("Profil Ayarları")),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("BooMovies & Books"), centerTitle: true),
      body: Column(
        children: [
          _buildSearchFilters(),
          _buildSearchBar(),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            label: 'Kitaplarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            label: 'Filmlerim',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
