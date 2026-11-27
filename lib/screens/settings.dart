import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';
import '../widgets/status_badge.dart';
import '../services/native_bridge.dart';

class Settings extends StatefulWidget {
  final NativeBridge bridge;
  const Settings({super.key, required this.bridge});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final List<Map<String, String>> _paths = [
    {'key': 'مسار Vault', 'value': '/mnt/sdcard/opencode/build-vault'},
    {'key': 'مجلد الحالة', 'value': '/mnt/sdcard/opencode/build-vault/state'},
    {'key': 'مجلد الملصقات', 'value': '/mnt/sdcard/opencode/build-vault/playbooks'},
    {'key': 'مخرجات الاستوديو', 'value': '/mnt/sdcard/opencode/build-vault/studio/out'},
    {'key': 'مجلد السكريبتات', 'value': '/mnt/sdcard/opencode/build-vault/scripts'},
    {'key': 'مجلد الأدوات', 'value': '/mnt/sdcard/opencode/build-vault/tools'},
  ];

  Map<String, dynamic> _termuxInfo = {};
  Map<String, dynamic> _storageInfo = {};
  Map<String, dynamic> _guardInfo = {};

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    try {
      final t = await widget.bridge.checkTermux();
      final s = await widget.bridge.checkStoragePermission();
      final v = await widget.bridge.getVaultPath();
      final g = await widget.bridge.checkFortressGuard();
      setState(() {
        _termuxInfo = t;
        _storageInfo = s;
        _vaultPathInfo = v;
        _guardInfo = g;
      });
    } catch (e) {
      setState(() {});
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
              ),
              child: const BidiText(
                data: 'الإعدادات والبيئة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _paths.length + 4,
                itemBuilder: (context, index) {
                  if (index < _paths.length) {
                    final item = _paths[index];
                    return ListTile(
                      title: BidiText(data: item['key']!, style: const TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: CodeBlock(code: item['value']!, onCopy: () {}),
                    );
                  }
                  if (index == _paths.length) {
                    return ListTile(
                      title: const BidiText(data: 'الحارس والتحقق', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(data: 'التحقق من fortress-guard وسلامة الملفات', style: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary)),
                      trailing: StatusBadge(status: _guardInfo['fortressGuardExists'] == true ? 'PASS' : 'FAIL'),
                      onTap: _refreshAll,
                    );
                  }
                  if (index == _paths.length + 1) {
                    return ListTile(
                      title: const BidiText(data: 'توفر ترمكس', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(data: 'مثبت: ${_termuxInfo['installed'] == true ? "نعم" : "لا"}', style: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary)),
                      trailing: StatusBadge(status: _termuxInfo['installed'] == true ? 'PASS' : 'FAIL'),
                      onTap: _refreshAll,
                    );
                  }
                  if (index == _paths.length + 2) {
                    return ListTile(
                      title: const BidiText(data: 'أذونات التخزين', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(data: 'ممنوح: ${_storageInfo['success'] == true ? "نعم" : "لا"}', style: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary)),
                      trailing: StatusBadge(status: _storageInfo['success'] == true ? 'PASS' : 'FAIL'),
                      onTap: () async {
                        await widget.bridge.requestStoragePermission();
                        _refreshAll();
                      },
                    );
                  }
                  return ListTile(
                    title: const BidiText(data: 'حول التطبيق', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                    subtitle: const BidiText(data: 'Fortress Studio - مركز قيادة احترافي', style: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary)),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
