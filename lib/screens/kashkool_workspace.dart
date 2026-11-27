import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';
import '../services/native_bridge.dart';
import '../services/system_service.dart';

class KashkoolWorkspace extends StatefulWidget {
  final NativeBridge bridge;
  const KashkoolWorkspace({super.key, required this.bridge});

  @override
  State<KashkoolWorkspace> createState() => _KashkoolWorkspaceState();
}

class _KashkoolWorkspaceState extends State<KashkoolWorkspace> {
  Map<String, dynamic> _kashkoolInfo = {};
  Map<String, dynamic> _profileInfo = {};
  bool _isLoading = false;
  final TextEditingController _promptController = TextEditingController();
  String _guardOutput = '';
  bool _isRunningGuard = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    try {
      final p = await widget.bridge.readWorkshopProfile();
      final systemService = SystemService();
      final k = await systemService.checkKashkoolWorkspace();
      if (!mounted) return;
      setState(() {
        _profileInfo = p;
        _kashkoolInfo = k;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runGuardPass() async {
    setState(() {
      _isRunningGuard = true;
      _guardOutput = '';
    });
    try {
      final result = await widget.bridge.runFortressGuard(timeoutSec: 60);
      if (!mounted) return;
      setState(() {
        _guardOutput = result['output'] ?? '';
        _isRunningGuard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardOutput = 'خطأ: $e';
        _isRunningGuard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kashkoolReady = _kashkoolInfo['stack_ready'] == true;
    final forbiddenFree = _kashkoolInfo['forbidden_free'] == true;
    final pubspecExists = _kashkoolInfo['pubspec_exists'] == true;
    final hasFlutter = _kashkoolInfo['has_flutter'] == true;
    final hasSupabase = _kashkoolInfo['has_supabase'] == true;
    final hasKashkoolClient = _kashkoolInfo['has_kashkool_ai_client'] == true;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.glassSurface,
                border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
              ),
              child: Row(
                children: [
                  const BidiText(
                    data: 'مساحة عمل كشكول',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshAll,
                    child: const BidiText(data: 'تحديث', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BidiText(
                            data: 'ملف التعريف المركزي (workshop_profile.json)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          if (_profileInfo.isNotEmpty && _profileInfo['exists'] == true)
                            CodeBlock(code: _profileInfo['content'] ?? '')
                          else
                            const BidiText(
                              data: 'ملف التعريف غير متوفر',
                              style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Arabic'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BidiText(
                            data: 'مدقق كشكول (fortress-guard)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRunningGuard ? null : _runGuardPass,
                              child: BidiText(
                                data: _isRunningGuard ? 'جارٍ الفحص...' : 'تشغيل المدقق',
                                style: const TextStyle(fontFamily: 'Arabic', fontSize: 12),
                              ),
                            ),
                          ),
                          if (_guardOutput.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: CodeBlock(code: _guardOutput),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BidiText(
                            data: 'جاهزية كشكول workspace',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          _statusItem('مسار كشكول', _kashkoolInfo['path'] ?? 'غير محدد'),
                          _statusItemBool('ملف pubspec موجود', pubspecExists),
                          _statusItemBool('Flutter SDK', hasFlutter),
                          _statusItemBool('Supabase', hasSupabase),
                          _statusItemBool('kashkool_ai_client', hasKashkoolClient),
                          _statusItemBool('خالي من Firebase و Gemini', forbiddenFree),
                          if (!kashkoolReady) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentAmber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.5), width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BidiText(
                                    data: 'كشكول workspace غير مهيأ محلياً',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentAmber, fontFamily: 'Arabic'),
                                  ),
                                  const SizedBox(height: 4),
                                  BidiText(
                                    data: 'المسار: ${_kashkoolInfo['path'] ?? 'غير محدد'}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'Mono', fontStyle: FontStyle.italic),
                                    forceLtr: true,
                                  ),
                                  const SizedBox(height: 4),
                                  BidiText(
                                    data: 'أنشئ pubspec.yaml مع flutter و supabase و kashkool_ai_client فقط (بدون Gemini أو Firebase)',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'Arabic'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kashkoolReady ? AppTheme.accentGreen : AppTheme.accentAmber,
                                foregroundColor: AppTheme.obsidian,
                              ),
                              onPressed: _refreshAll,
                              child: BidiText(
                                data: kashkoolReady ? 'الكشكول جاهز للنشر' : 'الكشكول غير مكتمل',
                                style: const TextStyle(fontFamily: 'Arabic', fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BidiText(
                            data: 'إرسال مهمة كشكول',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _promptController,
                            decoration: const InputDecoration(
                              hintText: 'أدخل مهمة كشكول للمعالجة',
                              hintStyle: TextStyle(color: AppTheme.textMuted),
                            ),
                            style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textPrimary),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _promptController.text.trim().isEmpty ? null : () {},
                              child: const BidiText(data: 'إرسال إلى kashkool-savior', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: BidiText(
              data: label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontFamily: 'Arabic'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CodeBlock(code: value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItemBool(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: BidiText(
              data: label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontFamily: 'Arabic'),
            ),
          ),
          BidiText(
            data: value ? 'نعم' : 'لا',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: value ? AppTheme.accentGreen : AppTheme.accentRed,
              fontFamily: 'Mono',
            ),
            forceLtr: true,
          ),
        ],
      ),
    );
  }
}
