import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddAnimeScreen extends StatefulWidget {
  final Map? animeData;
  const AddAnimeScreen({super.key, this.animeData});

  @override
  State<AddAnimeScreen> createState() => _AddAnimeScreenState();
}

class _AddAnimeScreenState extends State<AddAnimeScreen> {
  final _titleController = TextEditingController();
  final _titleArabicController = TextEditingController();
  final _descController = TextEditingController();
  final _descArabicController = TextEditingController();
  final _coverController = TextEditingController();
  final _bannerController = TextEditingController();
  final _yearController = TextEditingController();
  final _scoreController = TextEditingController();
  final _aniwatchIdController = TextEditingController();

  String _status = 'airing';
  String _type = 'TV';
  List<String> _genres = [];
  final _genreController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool get isEditing => widget.animeData != null;

  final List<String> _statusOptions = ['airing', 'finished', 'upcoming', 'hiatus'];
  final List<String> _typeOptions = ['TV', 'Movie', 'OVA', 'Special', 'ONA'];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final a = widget.animeData!;
      _titleController.text = a['title'] ?? '';
      _titleArabicController.text = a['title_arabic'] ?? '';
      _descController.text = a['description'] ?? '';
      _descArabicController.text = a['description_arabic'] ?? '';
      _coverController.text = a['cover'] ?? '';
      _bannerController.text = a['banner'] ?? '';
      _yearController.text = '${a['year'] ?? ''}';
      _scoreController.text = '${a['score'] ?? ''}';
      _aniwatchIdController.text = a['aniwatch_id'] ?? '';
      _status = a['status'] ?? 'airing';
      _type = a['type'] ?? 'TV';
      _genres = List<String>.from(a['genres'] ?? []);
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty) {
      setState(() => _message = 'Title is required');
      return;
    }
    setState(() { _isLoading = true; _message = ''; });

    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString('server_url') ?? '';
    final adminKey = prefs.getString('admin_key') ?? '';

    try {
      final body = jsonEncode({
        'title': _titleController.text,
        'title_arabic': _titleArabicController.text,
        'description': _descController.text,
        'description_arabic': _descArabicController.text,
        'cover': _coverController.text,
        'banner': _bannerController.text,
        'status': _status,
        'type': _type,
        'genres': _genres,
        'year': int.tryParse(_yearController.text),
        'score': double.tryParse(_scoreController.text),
        'aniwatch_id': _aniwatchIdController.text,
      });

      http.Response response;
      if (isEditing) {
        response = await http.put(
          Uri.parse('$serverUrl/admin/anime/${widget.animeData!['id']}'),
          headers: {'Content-Type': 'application/json', 'x-admin-key': adminKey},
          body: body,
        );
      } else {
        response = await http.post(
          Uri.parse('$serverUrl/admin/anime'),
          headers: {'Content-Type': 'application/json', 'x-admin-key': adminKey},
          body: body,
        );
      }

      if (response.statusCode == 200) {
        setState(() {
          _message = isEditing ? '✅ Anime updated!' : '✅ Anime added!';
          _isLoading = false;
        });
        if (!isEditing) _clearFields();
      } else {
        setState(() { _message = '❌ Failed'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _message = '❌ Connection failed'; _isLoading = false; });
    }
  }

  void _clearFields() {
    _titleController.clear();
    _titleArabicController.clear();
    _descController.clear();
    _descArabicController.clear();
    _coverController.clear();
    _bannerController.clear();
    _yearController.clear();
    _scoreController.clear();
    _aniwatchIdController.clear();
    setState(() { _genres = []; });
  }

  void _addGenre() {
    if (_genreController.text.isNotEmpty) {
      setState(() {
        _genres.add(_genreController.text);
        _genreController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(isEditing ? 'Edit Anime' : 'Add Anime',
          style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Basic Info'),
            _field(_titleController, 'Title (English)', Icons.title),
            SizedBox(height: 10),
            _field(_titleArabicController, 'Title (Arabic)', Icons.title),
            SizedBox(height: 10),
            _field(_coverController, 'Cover Image URL', Icons.image),
            SizedBox(height: 10),
            _field(_bannerController, 'Banner Image URL', Icons.image_outlined),
            SizedBox(height: 20),
            _sectionTitle('Aniwatch'),
            _field(_aniwatchIdController, 'Aniwatch ID (e.g. naruto-60)', Icons.link),
            SizedBox(height: 20),
            _sectionTitle('Details'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _status,
                          isExpanded: true,
                          dropdownColor: Color(0xFF1A1A1A),
                          underline: SizedBox(),
                          style: TextStyle(color: Colors.white),
                          items: _statusOptions.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _type,
                          isExpanded: true,
                          dropdownColor: Color(0xFF1A1A1A),
                          underline: SizedBox(),
                          style: TextStyle(color: Colors.white),
                          items: _typeOptions.map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(_yearController, 'Year', Icons.calendar_today, isNumber: true)),
                SizedBox(width: 10),
                Expanded(child: _field(_scoreController, 'Score', Icons.star, isNumber: true)),
              ],
            ),
            SizedBox(height: 20),
            _sectionTitle('Genres'),
            Row(
              children: [
                Expanded(child: _field(_genreController, 'Add genre...', Icons.tag)),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE53935)),
                  onPressed: _addGenre,
                  child: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _genres.map((g) => Chip(
                label: Text(g, style: TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Color(0xFF2A2A2A),
                deleteIcon: Icon(Icons.close, size: 14, color: Colors.white54),
                onDeleted: () => setState(() => _genres.remove(g)),
              )).toList(),
            ),
            SizedBox(height: 20),
            _sectionTitle('Description'),
            _field(_descController, 'Description (English)', Icons.description, maxLines: 4),
            SizedBox(height: 10),
            _field(_descArabicController, 'Description (Arabic)', Icons.description, maxLines: 4),
            SizedBox(height: 24),
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
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'Update Anime' : 'Add Anime',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(title,
        style: TextStyle(color: Color(0xFFE53935), fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
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