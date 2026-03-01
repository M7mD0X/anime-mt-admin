import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_anime_screen.dart';
import 'anime_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalAnime = 0;
  int totalEpisodes = 0;
  int airingAnime = 0;
  int finishedAnime = 0;
  List recentAnime = [];
  bool isLoading = true;
  String serverUrl = '';

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    serverUrl = prefs.getString('server_url') ?? '';

    try {
      final response = await http.get(Uri.parse('$serverUrl/anime?limit=100'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List animeList = data['results'];

        int episodes = 0;
        int airing = 0;
        int finished = 0;

        for (var anime in animeList) {
          episodes += (anime['episodes_count'] as num?)?.toInt() ?? 0;
          if (anime['status'] == 'airing') airing++;
          if (anime['status'] == 'finished') finished++;
        }

        setState(() {
          totalAnime = animeList.length;
          totalEpisodes = episodes;
          airingAnime = airing;
          finishedAnime = finished;
          recentAnime = animeList.take(5).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE53935)),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFE53935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.movie, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Text('Anime MT Admin',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white54),
            onPressed: () {
              setState(() { isLoading = true; });
              loadStats();
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white54),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : RefreshIndicator(
              color: Color(0xFFE53935),
              onRefresh: loadStats,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _statCard('Total Anime', '$totalAnime', Icons.movie_outlined, Color(0xFFE53935)),
                        _statCard('Total Episodes', '$totalEpisodes', Icons.play_circle_outline, Colors.blue),
                        _statCard('Airing', '$airingAnime', Icons.fiber_manual_record, Colors.green),
                        _statCard('Finished', '$finishedAnime', Icons.check_circle_outline, Colors.orange),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Quick Actions
                    Text('Quick Actions',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            icon: Icons.add,
                            label: 'Add Anime',
                            color: Color(0xFFE53935),
                            onTap: () async {
                              await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => AddAnimeScreen()));
                              loadStats();
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            icon: Icons.list,
                            label: 'Manage Anime',
                            color: Colors.blue,
                            onTap: () async {
                              await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => AnimeListScreen()));
                              loadStats();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Recent Anime
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Anime',
                          style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AnimeListScreen()));
                            loadStats();
                          },
                          child: Text('See All', style: TextStyle(color: Color(0xFFE53935))),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    recentAnime.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.movie_outlined, color: Colors.white24, size: 50),
                                  SizedBox(height: 10),
                                  Text('No anime yet', style: TextStyle(color: Colors.white38)),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recentAnime.length,
                            itemBuilder: (context, index) {
                              final anime = recentAnime[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: (anime['cover'] ?? '').isNotEmpty
                                          ? Image.network(anime['cover'],
                                              width: 45, height: 60, fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(
                                                width: 45, height: 60, color: Colors.grey[900],
                                                child: Icon(Icons.movie, color: Colors.grey, size: 20)))
                                          : Container(width: 45, height: 60, color: Colors.grey[900],
                                              child: Icon(Icons.movie, color: Colors.grey, size: 20)),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(anime['title'] ?? '',
                                            style: TextStyle(color: Colors.white, fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _badge(anime['status'] ?? '', _statusColor(anime['status'])),
                                              SizedBox(width: 6),
                                              _badge('${anime['episodes_count'] ?? 0} eps', Colors.blue),
                                              if ((anime['aniwatch_id'] ?? '').isNotEmpty) ...[
                                                SizedBox(width: 6),
                                                _badge('AW', Colors.green),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label,
      required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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