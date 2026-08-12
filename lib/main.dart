import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/notes_controller.dart';
import 'screens/notes_screen.dart';

void main() => runApp(const NotesApp());

/// Root of the My Notes application.
class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  static const _themeKey = 'settings.dark_theme';

  final NotesController _notes = NotesController();
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isDark = prefs.getBool(_themeKey) ?? false);
  }

  void _toggleTheme() {
    final next = !_isDark;
    setState(() => _isDark = next);
    SharedPreferences.getInstance().then((prefs) {
      return prefs.setBool(_themeKey, next);
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: NotesScreen(
        controller: _notes,
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
