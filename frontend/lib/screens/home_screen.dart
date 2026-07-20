import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/search_result_screen.dart';
import '../services/user_manager.dart';
import '../screens/movie_list_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/ai_assistant_screen.dart';
import 'user_info_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Widget _buildSearchBar() {
    // Bulunulan sekmeye göre arama tipini ve ipucu metnini dinamik belirliyoruz
    final String currentSearchType = _currentIndex == 0 ? 'book' : 'movie';
    final String hintText = _currentIndex == 0
        ? "Kitap ismi ara..."
        : "Film ismi ara...";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultsScreen(
                  query: value,
                  searchType: currentSearchType, // Dinamik tip gönderiliyor
                ),
              ),
            );
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
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
    // Provider ile kullanıcıyı dinliyoruz
    final userManager = context.watch<UserManager>();

    final List<Widget> pages = [
      BookListScreen(),
      MovieListScreen(),
      const AiAssistantScreen(),
      const UserInfoScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("BooMovies"), centerTitle: true),
      body: Column(
        children: [
          if (_currentIndex == 0 || _currentIndex == 1) _buildSearchBar(),

          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _searchController.clear();
          });
        },
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
            icon: Icon(Icons.auto_awesome),
            label: 'Yapay Zeka',
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
