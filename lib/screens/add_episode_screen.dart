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
  String? _editingEpisodeId;

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

  void _fillEditFields(Map ep) {
    setState(() { _editingEpisodeId = ep['id']; });
    _numberController.text = '${ep['number']}';
    _titleController.text = ep['title'] ?? '';
    _titleArabicController.text = ep['title_arabic'] ?? '';
    _thumbnailController.text = ep['thumbnail'] ?? '';
    _videoUrlController.text = ep['video_url'] ?? '';
    _videoUrlArabicController.text = ep['video_url_arabic'] ?? '';
    _durationController.text = '${ep['duration'] ?? ''}';
  }

  void _cancelEdit() {
    setState(() { _editingEpisodeId = null; });
    _clearFields();
  }

  Future<void> saveEpisode() async {
    if (_numberController.text.isEmpty || _videoUrlController.text.isEmpty) {
      setState(() => _message = 'Episode number and video URL are required');
      return;
    }
    setState(() { _isLoading = true; _message = ''; });

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? '';
    final adminKey = prefs.getString('admin_key') ?? '';

    final body = jsonEncode({
      'anime_id': widget.animeId,
      'number': int.parse(_numberController.text),
      'title': _titleController.text,
      'title_arabic': _titleArabicController.text,
      'thumbnail': _thumbnailController.text,
      'video_url': _videoUrlController.text,
      'video_url_arabic': _videoUrlArabicController.text,
      'duration': int.tryParse(_durationController.text) ?? 0,
    });

    try {
      http.Response response;
      if (_editingEpisodeId != null) {
        response = await http.put(
          Uri.parse('$serverUrl/admin/episode/$_editingEpisodeId'),
          headers: {'Content-Type': 'application/json', 'x-admin-key': adminKey},
          body: body,
        );
      } else {
        response = await http.post(
          Uri.parse('$serverUrl/admin/episode'),
          headers: {'Content-Type': 'application/json', 'x-admin-key': adminKey},
          body: body,
        );
      }

      if (response.statusCode == 200) {
        setState(() {
          _message = _editingEpisodeId != null ? '✅ Episode updated!' : '✅ Episode added!';
          _isLoading = false;
          _editingEpisodeId = null;
        });
        _clearFields();
        loadEpisodes();
      } else {
        setState(() { _message = '❌ Failed'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _message = '❌ Connection failed'; _isLoading = false; });
    }
  }

  Future<void> deleteEpisode(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Delete Episode', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? '';
      final adminKey = prefs.getString('admin_key') ?? '';
      await http.delete(
        Uri.parse('$serverUrl/admin/episode/$id'),
        headers: {'x-admin-key': adminKey},
      );
      loadEpisodes();
    }
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
            Text(_editingEpisodeId != null ? 'Edit Episode' : 'Add Episode',
              style: TextStyle(color: Colors.white, fontSize: 16)),
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
                  final isEditing = _editingEpisodeId == ep['id'];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isEditing ? Color(0xFFE53935).withOpacity(0.1) : Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: isEditing ? Border.all(color: Color(0xFFE53935)) : null,
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
                          icon: Icon(Icons.edit, color: Colors.blue, size: 18),
                          onPressed: () => _fillEditFields(ep),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () => deleteEpisode(ep['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_editingEpisodeId != null ? 'Edit Episode' : 'Add New Episode',
                  style: TextStyle(color: Color(0xFFE53935), fontSize: 14, fontWeight: FontWeight.bold)),
                if (_editingEpisodeId != null)
                  TextButton(
                    onPressed: _cancelEdit,
                    child: Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
              ],
            ),
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
                  color: _message.contains('✅')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_message,
                  style: TextStyle(
                    color: _message.contains('✅') ? Colors.green : Colors.red)),
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
                onPressed: _isLoading ? null : saveEpisode,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _editingEpisodeId != null ? 'Update Episode' : 'Add Episode',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
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