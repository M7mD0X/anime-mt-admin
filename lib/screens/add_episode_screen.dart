import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEpisodeScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  const AddEpisodeScreen({super.key, required this.animeId, required this.animeTitle});

  @override
  State<AddEpisodeScreen> createState() => _AddEpisodeScreenState();
}

class _AddEpisodeScreenState extends State<AddEpisodeScreen> {
  final _numberController = TextEditingController();
  final _titleController = TextEditingController();
  final _titleArabicController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _videoUrlArabicController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  List episodes = [];

  @override
  void initState() {
    super.initState();
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? '';
    try {
      final response = await http.get(Uri.parse('$serverUrl/episodes/${widget.animeId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() { episodes = data['results']; });
      }
    } catch (e) {}
  }

  Future<void> addEpisode() async {
    if (_numberController.text.isEmpty || _videoUrlController.text.isEmpty) {
      setState(() => _message = 'Episode number and video URL are required');
      return;
    }
    setState(() { _isLoading = true; _message = ''; });

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? '';
    final adminKey = prefs.getString('admin_key') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/admin/episode'),
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': adminKey,
        },
        body: jsonEncode({
          'anime_id': widget.animeId,
          'number': int.parse(_numberController.text),
          'title': _titleController.text,
          'title_arabic': _titleArabicController.text,
          'thumbnail': _thumbnailController.text,
          'video_url': _videoUrlController.text,
          'video_url_arabic': _videoUrlArabicController.text,
          'duration': int.tryParse(_durationController.text) ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        setState(() { _message = '✅ Episode added!'; _isLoading = false; });
        _clearFields();
        loadEpisodes();
      } else {
        setState(() { _message = '❌ Failed to add episode'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _message = '❌ Connection failed'; _isLoading = false; });
    }
  }

  Future<void> deleteEpisode(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? '';
    final adminKey = prefs.getString('admin_key') ?? '';
    await http.delete(
      Uri.parse('$serverUrl/admin/episode/$id'),
      headers: {'x-admin-key': adminKey},
    );
    loadEpisodes();
  }

  void _clearFields() {
    _numberController.clear();
    _titleController.clear();
    _titleArabicController.clear();
    _thumbnailController.clear();
    _videoUrlController.clear();
    _videoUrlArabicController.clear();
    _durationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Episode', style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(widget.animeTitle, style: TextStyle(color: Color(0xFFE53935), fontSize: 12)),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (episodes.isNotEmpty) ...[
              Text('Episodes (${episodes.length})',
                style: TextStyle(color: Color(0xFFE53935), fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final ep = episodes[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE53935).withOpacity(0.15),
                          ),
                          child: Center(
                            child: Text('${ep['number']}',
                              style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(ep['title'] ?? 'Episode ${ep['number']}',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => deleteEpisode(ep['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
            Text('Add New Episode',
              style: TextStyle(color: Color(0xFFE53935), fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _field(_numberController, 'Episode Number *', Icons.numbers, isNumber: true),
            SizedBox(height: 10),
            _field(_titleController, 'Episode Title', Icons.title),
            SizedBox(height: 10),
            _field(_titleArabicController, 'Episode Title (Arabic)', Icons.title),
            SizedBox(height: 10),
            _field(_thumbnailController, 'Thumbnail URL', Icons.image),
            SizedBox(height: 10),
            _field(_videoUrlController, 'Video URL *', Icons.play_circle),
            SizedBox(height: 10),
            _field(_videoUrlArabicController, 'Video URL (Arabic Sub)', Icons.play_circle_outline),
            SizedBox(height: 10),
            _field(_durationController, 'Duration (minutes)', Icons.timer, isNumber: true),
            SizedBox(height: 20),
            if (_message.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('✅') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_message,
                  style: TextStyle(color: _message.contains('✅') ? Colors.green : Colors.red)),
              ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE53935),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : addEpisode,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Episode', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Color(0xFFE53935)),
        filled: true,
        fillColor: Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}