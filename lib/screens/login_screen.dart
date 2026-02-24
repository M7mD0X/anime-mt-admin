import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _keyController = TextEditingController();
  final _serverController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('admin_key');
    final server = prefs.getString('server_url');
    if (key != null && server != null) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => DashboardScreen()));
    }
  }

  Future<void> _login() async {
    if (_keyController.text.isEmpty || _serverController.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_key', _keyController.text);
      await prefs.setString('server_url', _serverController.text);
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => DashboardScreen()));
    } catch (e) {
      setState(() { _error = 'Login failed'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE53935),
                ),
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 45),
              ),
              SizedBox(height: 20),
              Text('Anime MT Admin',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Login to manage your app',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
              SizedBox(height: 40),
              TextField(
                controller: _serverController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Server URL (e.g. https://anime-mt-server...)',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                  prefixIcon: Icon(Icons.link, color: Color(0xFFE53935)),
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _keyController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Admin Key',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.key, color: Color(0xFFE53935)),
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(_error, style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}