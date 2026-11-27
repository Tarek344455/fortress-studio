import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';
import '../widgets/status_badge.dart';
import '../services/native_bridge.dart';
import '../services/system_service.dart';

class Settings extends StatefulWidget {
  final NativeBridge bridge;
  const Settings({super.key, required this.bridge});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final List<Map<String, String>> _paths = const [
    {'key': 'مسار Vault', 'value': '/mnt/sdcard/opencode/build-vault'},
    {'key': 'مجلد الحالة', 'value': '/mnt/sdcard/opencode/build-vault/state'},
    {'key': 'ملف الملف الشخصي', 'value': '/mnt/sdcard/opencode/build-vault/workshop_profile.json'},
    {'key': 'مجلد الملصقات', 'value': '/mnt/sdcard/opencode/build-vault/playbooks'},
    {'key': 'مخرجات الاستوديو', 'value': '/mnt/sdcard/opencode/build-vault/studio/out'},
    {'key': 'مجلد السكريبتات', 'value': '/mnt/sdcard/opencode/build-vault/scripts'},
    {'key': 'مجلد الأدوات', 'value': '/mnt/sdcard/opencode/build-vault/tools'},
    {'key': 'مسار APK محلي', 'value': '/mnt/sdcard/Download/fortress-studio.apk'},
  ];

  Map<String, dynamic> _termuxInfo = {};
  Map<String, dynamic> _storageInfo = {};
  Map<String, dynamic> _guardInfo = {};
  Map<String, dynamic> _kashkoolInfo = {};
  Map<String, dynamic> _profileInfo = {};

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    try {
      final t = await widget.bridge.checkTermux();
      final s = await widget.bridge.checkStoragePermission();
      await widget.bridge.getVaultPath();
      final g = await widget.bridge.checkFortressGuard();
      final p = await widget.bridge.readWorkshopProfile();
      final systemService = SystemService();
      final k = await systemService.checkKashkoolWorkspace();
      if (!mounted) return;
      setState(() {
        _termuxInfo = t;
        _storageInfo = s;
        _guardInfo = g;
        _profileInfo = p;
        _kashkoolInfo = k;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageOk = _storageInfo['success'] == true || _storageInfo['value'] == true;
    final termuxOk = _termuxInfo['installed'] == true && _termuxInfo['allowExternalApps'] == true;
    final guardOk = _guardInfo['fortressGuardExists'] == true;
    final kashkoolReady = _kashkoolInfo['stack_ready'] == true;
    final apkExists = _profileInfo.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
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
                itemCount: _paths.length + 6,
                itemBuilder: (context, index) {
                  if (index < _paths.length) {
                    final item = _paths[index];
                    return ListTile(
                      title: BidiText(data: item['key']!, style: const TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: CodeBlock(code: item['value']!),
                    );
                  }
                  if (index == _paths.length) {
                    return ListTile(
                      title: const BidiText(data: 'الحارس والتحقق', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: const BidiText(
                        data: 'التحقق من fortress-guard وسلامة الملفات',
                        style: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                      ),
                      trailing: StatusBadge(status: guardOk ? 'PASS' : 'FAIL'),
                      onTap: _refreshAll,
                    );
                  }
                  if (index == _paths.length + 1) {
                    return ListTile(
                      title: const BidiText(data: 'توفر ترمكس', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(
                        data: 'مثبت: ${_termuxInfo['installed'] == true ? "نعم" : "لا"} | التطبيقات الخارجية: ${_termuxInfo['allowExternalApps'] == true ? "نعم" : "لا"}',
                        style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                      ),
                      trailing: StatusBadge(status: termuxOk ? 'PASS' : 'FAIL'),
                      onTap: _refreshAll,
                    );
                  }
                  if (index == _paths.length + 2) {
                    return ListTile(
                      title: const BidiText(data: 'أذونات التخزين', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(
                        data: 'ممنوح: ${storageOk ? "نعم" : "لا"}',
                        style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                      ),
                      trailing: StatusBadge(status: storageOk ? 'PASS' : 'FAIL'),
                      onTap: () async {
                        await widget.bridge.requestStoragePermission();
                        await _refreshAll();
                      },
                    );
                  }
                  if (index == _paths.length + 3) {
                    return ListTile(
                      title: const BidiText(data: 'كشكول workspace', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(
                        data: kashkoolReady ? 'جاهز (Flutter + Supabase + kashkool_ai_client)' : 'غير مكتمل',
                        style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                      ),
                      trailing: StatusBadge(status: kashkoolReady ? 'PASS' : 'FAIL'),
                      onTap: _refreshAll,
                    );
                  }
                  if (index == _paths.length + 4) {
                    return ListTile(
                      title: const BidiText(data: 'ملف APK', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                      subtitle: BidiText(
                        data: apkExists ? 'موجود (23 ميجابايت)' : 'غير موجود',
                        style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                      ),
                      trailing: StatusBadge(status: apkExists ? 'PASS' : 'FAIL'),
                      onTap: _refreshAll,
                    );
                  }
                  return const ListTile(
                    title: BidiText(data: 'حول التطبيق', style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.w500)),
                    subtitle: BidiText(
                      data: 'Fortress Studio - مركز قيادة احترافي',
                      style: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                    ),
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
