import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const List<String> newsUrls = [
  'https://smail1983.github.io/Nwesmomroco/news.json',
  'https://raw.githubusercontent.com/smail1983/Nwesmomroco/main/news.json',
];

void main() {
  runApp(const NewsMoroccoApp());
}

class NewsMoroccoApp extends StatelessWidget {
  const NewsMoroccoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsMorocco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00875A),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),
      home: const HomePage(),
    );
  }
}

class Article {
  final String title;
  final String description;
  final String url;
  final String source;
  final String category;
  final String image;

  const Article({
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.category,
    required this.image,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      image: (json['image'] ?? '').toString(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;
  String selectedCategory = 'sports';
  String search = '';
  bool loading = true;
  String? error;
  List<Article> articles = [];

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      List<Article>? loaded;

      for (final baseUrl in newsUrls) {
        try {
          final response = await http
              .get(Uri.parse('$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
              .timeout(const Duration(seconds: 12));

          if (response.statusCode != 200) continue;

          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final raw = decoded is List
              ? decoded
              : (decoded is Map<String, dynamic>
                  ? (decoded['articles'] ?? [])
                  : []);

          final list = <Article>[];
          for (final item in raw) {
            if (item is Map) {
              list.add(Article.fromJson(Map<String, dynamic>.from(item)));
            }
          }

          if (list.isNotEmpty) {
            loaded = list;
            break;
          }
        } catch (_) {
          // Try the next news source.
        }
      }

      if (loaded == null) {
        throw Exception('All news sources failed');
      }

      if (!mounted) return;
      setState(() {
        articles = loaded!;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر تحميل الأخبار حالياً. حاول مرة أخرى.';
      });
    }
  }

  List<Article> get filteredArticles {
    final q = search.trim().toLowerCase();
    return articles.where((a) {
      final categoryOk =
          selectedCategory == 'all' || a.category == selectedCategory;
      final searchOk = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q);
      return categoryOk && searchOk;
    }).toList();
  }

  Future<void> openArticle(Article article) async {
    final uri = Uri.tryParse(article.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'NewsMorocco 🇲🇦',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: loading ? null : loadNews,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: IndexedStack(
          index: selectedTab,
          children: [
            _homeTab(),
            _categoryTab('all', 'آخر الأخبار'),
            _categoryTab('business', 'الاقتصاد'),
            _categoryTab('technology', 'التكنولوجيا'),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            setState(() {
              selectedTab = index;
              selectedCategory =
                  ['sports', 'all', 'business', 'technology'][index];
              search = '';
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.sports_soccer_outlined),
              selectedIcon: Icon(Icons.sports_soccer),
              label: 'الرياضة',
            ),
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper),
              label: 'الأخبار',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up),
              label: 'الاقتصاد',
            ),
            NavigationDestination(
              icon: Icon(Icons.memory_outlined),
              selectedIcon: Icon(Icons.memory),
              label: 'التكنولوجيا',
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeTab() {
    return RefreshIndicator(
      onRefresh: loadNews,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _heroCard(),
          const SizedBox(height: 14),
          _searchBox(),
          const SizedBox(height: 14),
          _categoryChips(),
          const SizedBox(height: 8),
          _content(),
        ],
      ),
    );
  }

  Widget _categoryTab(String category, String title) {
    return RefreshIndicator(
      onRefresh: loadNews,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _searchBox(),
          const SizedBox(height: 12),
          _contentFor(category),
        ],
      ),
    );
  }

  Widget _contentFor(String category) {
    final old = selectedCategory;
    selectedCategory = category;
    final widget = _content();
    selectedCategory = old;
    return widget;
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF007A52), Color(0xFF005B3D)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نبض المغرب 🇲🇦', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 6),
          Text(
            'أهم الأخبار الرياضية المغربية أولاً',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'أخبار متجددة من موقع NewsMorocco.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      onChanged: (value) => setState(() => search = value),
      decoration: InputDecoration(
        hintText: 'ابحث في الأخبار...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('all', 'الكل', Icons.apps),
          _chip('sports', 'الرياضة', Icons.sports_soccer),
          _chip('business', 'الاقتصاد', Icons.trending_up),
          _chip('technology', 'التكنولوجيا', Icons.memory),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, IconData icon) {
    const tabForCategory = {
      'sports': 0,
      'all': 1,
      'business': 2,
      'technology': 3,
    };

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        selected: selectedCategory == value,
        onSelected: (_) {
          setState(() {
            selectedCategory = value;
            selectedTab = tabForCategory[value] ?? 0;
            search = '';
          });
        },
        avatar: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _content() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.cloud_off_rounded, size: 52),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loadNews,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }

    final items = filteredArticles;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('لا توجد أخبار حالياً.')),
      );
    }

    return Column(children: items.map(_articleCard).toList());
  }

  Widget _articleCard(Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openArticle(article),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    article.image,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  ),
                )
              else
                _placeholderImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      article.source.isEmpty ? 'NewsMorocco' : article.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.article_outlined, size: 34),
    );
  }
}
