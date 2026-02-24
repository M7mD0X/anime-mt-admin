import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_episode_screen.dart';

class AnimeListScreen extends StatefulWidget {
  const AnimeListScreen({super.key});

  @override
  State<AnimeListScreen> createState() => _AnimeListScreenState();
}

class _AnimeListScreenState extends State<AnimeListScreen> {
  List animeList = [];
  bool isLoading = true;
  String serverUrl = '';
  String adminKey = '';

  @override
  void initState() {
    super.initState();
    loadAnime();
  }

  Future<void> loadAnime() async {
    final prefs = await SharedPreferences.getInstance();
    serverUrl = prefs.getString('server_url') ?? '';
    adminKey = prefs.getString('admin_key') ?? '';

    try {
      final response = await http.get(Uri.parse('$serverUrl/anime?limit=100'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          animeList = data['results'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  Future<void> deleteAnime(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Delete Anime', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await http.delete(
        Uri.parse('$serverUrl/admin/anime/$id'),
        headers: {'x-admin-key': adminKey},
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
        title: Text('Manage Anime', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFE53935)),
            onPressed: () {
              setState(() { isLoading = true; });
              loadAnime();
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : animeList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined, color: Colors.white24, size: 80),
                      SizedBox(height: 16),
                      Text('No anime yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: animeList.length,
                  itemBuilder: (context, index) {
                    final anime = animeList[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: anime['cover'] != null && anime['cover'].isNotEmpty
                                ? Image.network(anime['cover'],
                                    width: 70, height: 95, fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 70, height: 95, color: Colors.grey[900],
                                      child: Icon(Icons.broken_image, color: Colors.grey)))
                                : Container(width: 70, height: 95, color: Colors.grey[900],
                                    child: Icon(Icons.movie, color: Colors.grey)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(anime['title'] ?? '',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 4),
                                  Text(
                                    anime['title_arabic'] ?? '',
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFE53935).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(anime['status'] ?? '',
                                          style: TextStyle(color: Color(0xFFE53935), fontSize: 10)),
                                      ),
                                      SizedBox(width: 6),
                                      Text('${anime['episodes_count'] ?? 0} eps',
                                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.add_circle, color: Colors.green, size: 22),
                                onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => AddEpisodeScreen(
                                    animeId: anime['id'],
                                    animeTitle: anime['title'],
                                  ))),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red, size: 22),
                                onPressed: () => deleteAnime(anime['id']),
                              ),
                            ],
                          ),
                          SizedBox(width: 4),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}