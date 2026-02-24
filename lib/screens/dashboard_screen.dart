import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
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
    final adminKey = prefs.getString('admin_key') ?? '';

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/anime?limit=1'),
        headers: {'x-admin-key': adminKey},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalAnime = data['total'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        title: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE53935)),
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
            Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFFE53935)),
            onPressed: logout,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard('Total Anime', '$totalAnime', Icons.movie),
                      SizedBox(width: 12),
                      _statCard('Episodes', '$totalEpisodes', Icons.play_circle),
                    ],
                  ),
                  SizedBox(height: 30),
                  Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _actionButton(
                    icon: Icons.add_circle,
                    title: 'Add New Anime',
                    subtitle: 'Add anime with cover and details',
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddAnimeScreen())),
                  ),
                  SizedBox(height: 12),
                  _actionButton(
                    icon: Icons.list,
                    title: 'Manage Anime',
                    subtitle: 'Edit, delete or add episodes',
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AnimeListScreen())),
                  ),
                  SizedBox(height: 12),
                  _actionButton(
                    icon: Icons.refresh,
                    title: 'Refresh Stats',
                    subtitle: 'Update dashboard statistics',
                    onTap: () {
                      setState(() { isLoading = true; });
                      loadStats();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xFFE53935), size: 28),
            SizedBox(height: 10),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE53935).withOpacity(0.15),
              ),
              child: Icon(icon, color: Color(0xFFE53935)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}