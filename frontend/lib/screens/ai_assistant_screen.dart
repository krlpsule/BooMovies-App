import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/internal_api_service.dart';
import '../services/user_manager.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final InternalApiService _apiService = InternalApiService();
  final TextEditingController _promptController = TextEditingController();

  bool _isLoading = false;
  String? _activeType; 
  List<dynamic> _recommendations = [];
  String? _errorText;

  Future<void> _fetchRecommendations(String type, {String prompt = ""}) async {
    final userId = context.read<UserManager>().userId;
    if (userId == null) {
      setState(() => _errorText = "Öneri alabilmek için giriş yapmalısınız.");
      return;
    }

    setState(() {
      _isLoading = true;
      _activeType = type;
      _errorText = null;
      _recommendations = [];
    });

    final results = await _apiService.getAiRecommendations(
      userId,
      type,
      prompt: prompt,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _recommendations = results;
      if (results.isEmpty) {
        _errorText =
            "Şu anda öneri üretilemedi. Lütfen daha sonra tekrar deneyin.";
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yapay Zeka Asistanı")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ne önereyim?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Hazır komut butonları
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickPromptChip(
                  icon: Icons.menu_book,
                  label: "Kitap Öner",
                  isLoading: _isLoading && _activeType == 'book',
                  onTap: () => _fetchRecommendations('book'),
                ),
                _QuickPromptChip(
                  icon: Icons.movie,
                  label: "Film Öner",
                  isLoading: _isLoading && _activeType == 'movie',
                  onTap: () => _fetchRecommendations('movie'),
                ),
              ],
            ),

            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Text(
          _errorText!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const Center(
        child: Text(
          "Yukarıdaki butonlardan birine dokunarak\nsana özel öneriler alabilirsin.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        final bool isBook = _activeType == 'book';
        final String subtitleLabel = isBook
            ? (rec['author'] ?? 'Bilinmeyen Yazar')
            : (rec['director'] ?? 'Bilinmeyen Yönetmen');

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(
              isBook ? Icons.menu_book : Icons.movie,
              color: Colors.deepPurple,
            ),
            title: Text(
              rec['title'] ?? 'Başlıksız',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(subtitleLabel),
                const SizedBox(height: 6),
                Text(
                  rec['reason'] ?? '',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _QuickPromptChip({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18, color: Colors.deepPurple),
      label: Text(label),
      onPressed: isLoading ? null : onTap,
      backgroundColor: Colors.deepPurple.withOpacity(0.08),
    );
  }
}
