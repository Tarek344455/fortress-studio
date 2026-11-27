import 'package:flutter/material.dart';
import 'services/native_bridge.dart';
import 'screens/command_deck.dart';
import 'screens/vault_explorer.dart';
import 'screens/tools_studio.dart';
import 'screens/settings.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FortressStudioApp());
}

class FortressStudioApp extends StatelessWidget {
  const FortressStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fortress Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final NativeBridge _bridge;

  final List<String> _titles = [
    'قيادة المنظومة',
    'مستكشف vault',
    'الأدوات والاستوديو',
    'الإعدادات',
  ];

  @override
  void initState() {
    super.initState();
    _bridge = NativeBridge();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CommandDeck(bridge: _bridge),
      VaultExplorer(bridge: _bridge),
      ToolsStudio(bridge: _bridge),
      Settings(bridge: _bridge),
    ];

    return Scaffold(
      appBar: AppBar(
        title: BidiTextWidget(
          data: _titles[_selectedIndex],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Arabic'),
        ),
        backgroundColor: AppTheme.obsidian,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentCyan),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'القيادة'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'المستكشف'),
          NavigationDestination(icon: Icon(Icons.build), label: 'الأدوات'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class BidiTextWidget extends StatelessWidget {
  final String data;
  final TextStyle? style;

  const BidiTextWidget({super.key, required this.data, this.style});

  @override
  Widget build(BuildContext context) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(data);
    return Text(
      data,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      style: style,
    );
  }
}
