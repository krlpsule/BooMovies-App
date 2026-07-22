import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/search_result_screen.dart';
import '../services/user_manager.dart';
import '../services/google_books_service.dart';
import '../services/tmdb_service.dart';
import '../models/book_model.dart';
import '../models/movie_model.dart';
import '../screens/movie_list_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../utils/content_actions.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

  final OpenLibraryService _bookService = OpenLibraryService();
  final TmdbService _movieService = TmdbService();

  Timer? _debounce;
  List<dynamic> _suggestions = []; // Book veya Movie nesneleri
  bool _isLoadingSuggestions = false;

  // Aramaya başlamak için gereken minimum karakter sayısı
  static const int _minCharsForSuggestions = 3;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, String searchType) {
    _debounce?.cancel();

    final query = value.trim();
    if (query.length < _minCharsForSuggestions) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    // Kullanıcı yazmayı bırakınca 400ms sonra ara (her tuş vuruşunda değil)
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = searchType == 'book'
            ? await _bookService.searchBooks(query)
            : await _movieService.searchMovies(query);

        if (!mounted) return;
        setState(() {
          _suggestions = results.take(6).toList();
          _isLoadingSuggestions = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _goToSearchResults(String query, String searchType) {
    if (query.trim().isEmpty) return;
    _debounce?.cancel();
    setState(() => _suggestions = []);
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchResultsScreen(query: query.trim(), searchType: searchType),
      ),
    );
  }

  Widget _buildSearchBar() {
    final String currentSearchType = _currentIndex == 0 ? 'book' : 'movie';
    final String hintText = _currentIndex == 0
        ? "Kitap ismi ara..."
        : "Film ismi ara...";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) => _onSearchChanged(value, currentSearchType),
            onSubmitted: (value) => _goToSearchResults(value, currentSearchType),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _suggestions = []);
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_isLoadingSuggestions || _suggestions.isNotEmpty)
            _buildSuggestionsList(currentSearchType),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(String searchType) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _isLoadingSuggestions
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final bool isBook = searchType == 'book';
                final String title = item.title ?? '';
                final String subtitle =
                    isBook ? (item as Book).author : (item as Movie).director;
                final String? imageUrl =
                    isBook ? (item as Book).coverUrl : (item as Movie).posterUrl;

                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            width: 36,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              isBook ? Icons.menu_book : Icons.movie,
                              color: Colors.deepPurple,
                              size: 28,
                            ),
                          )
                        : SizedBox(
                            width: 36,
                            height: 52,
                            child: Icon(
                              isBook ? Icons.menu_book : Icons.movie,
                              color: Colors.deepPurple,
                              size: 28,
                            ),
                          ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: (subtitle.isNotEmpty)
                      ? Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  trailing: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.deepPurple,
                  ),
                  onTap: () {
                    addItemToUserList(
                      context: context,
                      item: item,
                      searchType: searchType,
                    );
                  },
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _suggestions = [];
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