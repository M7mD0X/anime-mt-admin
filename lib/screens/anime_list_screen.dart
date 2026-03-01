import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_anime_screen.dart';
import 'add_episode_screen.dart';

class AnimeListScreen extends StatefulWidget {
  const AnimeListScreen({super.key});

  @override
  State<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends State<AnimeListScreen> {
  List animeList = [];
  List filteredList = [];
  bool isLoading = true;
  String serverUrl = '';
  String adminKey = '';
  final _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    loadAnime();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredList = animeList.where((anime) {
        final title = (anime['title'] ?? '').toLowerCase();
        final titleAr = (anime['title_arabic'] ?? '').toLowerCase();
        return title.contains(query) || titleAr.contains(query);
      }).toList();
    });
  }

  Future<void> loadAnime() async {
    final prefs = await SharedPreferences.getInstance();
    serverUrl = prefs.getString('server_url') ?? '';
    adminKey = prefs.getString('admin_key') ?? '';

    try {
      final response = await http.get(Uri.parse('$serverUrl/anime?limit=100'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          animeList = data['results'];
          filteredList = animeList;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  Future<void> deleteAnime(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red, size: 22),
            ),
            SizedBox(width: 12),
            Text('Delete Anime', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete:',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(title,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 8),
            Text('This will also delete all episodes!',
              style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(Icons.delete, size: 16),
            label: Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await http.delete(
        Uri.parse('$serverUrl/admin/anime/$id'),
        headers: {'x-admin-key': adminKey},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Deleted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      loadAnime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search anime...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              )
            : Text('Manage Anime', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  filteredList = animeList;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFE53935)),
            onPressed: () {
              setState(() { isLoading = true; });
              loadAnime();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFE53935),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddAnimeScreen()));
          loadAnime();
        },
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined, color: Colors.white24, size: 80),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty ? 'No anime yet' : 'No results found',
                        style: TextStyle(color: Colors.white38, fontSize: 16)),
                      if (_searchController.text.isEmpty) ...[
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE53935)),
                          icon: Icon(Icons.add),
                          label: Text('Add Anime'),
                          onPressed: () async {
                            await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AddAnimeScreen()));
                            loadAnime();
                          },
                        ),
                      ],
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Color(0xFF1A1A1A),
                      child: Row(
                        children: [
                          Icon(Icons.movie, color: Color(0xFFE53935), size: 16),
                          SizedBox(width: 6),
                          Text('${filteredList.length} anime',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final anime = filteredList[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    bottomLeft: Radius.circular(14),
                                  ),
                                  child: (anime['cover'] ?? '').isNotEmpty
                                      ? Image.network(anime['cover'],
                                          width: 70, height: 100, fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            width: 70, height: 100, color: Colors.grey[900],
                                            child: Icon(Icons.broken_image, color: Colors.grey)))
                                      : Container(width: 70, height: 100, color: Colors.grey[900],
                                          child: Icon(Icons.movie, color: Colors.grey)),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(anime['title'] ?? '',
                                          style: TextStyle(color: Colors.white, fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                        SizedBox(height: 4),
                                        if ((anime['title_arabic'] ?? '').isNotEmpty)
                                          Text(anime['title_arabic'],
                                            style: TextStyle(color: Colors.white38, fontSize: 11),
                                            textDirection: TextDirection.rtl,
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            _badge(anime['status'] ?? '', _statusColor(anime['status'])),
                                            _badge('${anime['episodes_count'] ?? 0} eps', Colors.blue),
                                            _badge(anime['type'] ?? 'TV', Colors.purple),
                                            if ((anime['aniwatch_id'] ?? '').isNotEmpty)
                                              _badge('AW ✓', Colors.green),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () async {
                                        await Navigator.push(context,
                                          MaterialPageRoute(builder: (_) =>
                                            AddAnimeScreen(animeData: anime)));
                                        loadAnime();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.video_library, color: Colors.green, size: 20),
                                      onPressed: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => AddEpisodeScreen(
                                          animeId: anime['id'],
                                          animeTitle: anime['title'],
                                        ))),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => deleteAnime(anime['id'], anime['title'] ?? ''),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 4),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'airing': return Colors.green;
      case 'finished': return Colors.orange;
      case 'upcoming': return Colors.amber;
      default: return Colors.grey;
    }
  }
}