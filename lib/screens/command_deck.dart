import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';
import '../services/native_bridge.dart';
import '../services/system_service.dart';

class CommandDeck extends StatefulWidget {
  final NativeBridge bridge;
  const CommandDeck({super.key, required this.bridge});

  @override
  State<CommandDeck> createState() => _CommandDeckState();
}

class _CommandDeckState extends State<CommandDeck> {
  bool _isLoading = false;
  Map<String, dynamic> _termuxInfo = {};
  Map<String, dynamic> _storageInfo = {};
  Map<String, dynamic> _vaultPathInfo = {};
  Map<String, dynamic> _guardInfo = {};
  String _terminalOutput = '';
  bool _isRunningCommand = false;
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _saviorController = TextEditingController();

  String _selectedRole = 'Plan';
  String _selectedModel = 'nemotron';
  bool _isRunningSavior = false;
  String _saviorOutput = '';

  bool _isRunningGuard = false;
  String _guardOutput = '';

  final List<String> _roles = const ['Plan', 'Builder', 'Reviewer', 'Guard'];
  final List<String> _models = const ['nemotron', 'deepseek', 'qwen', 'claude-cli', 'opencode', 'kashkool-savior', 'Antigravity'];
  final List<String> _agents = const ['opencode', 'claude-cli', 'kashkool-savior', 'Antigravity', 'fortress-guard', 'trinity'];

  final SystemService _systemService = SystemService();

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _saviorController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    try {
      final t = await widget.bridge.checkTermux();
      final s = await widget.bridge.checkStoragePermission();
      final v = await widget.bridge.getVaultPath();
      final g = await widget.bridge.checkFortressGuard();
      final k = await _systemService.checkKashkoolWorkspace();
      if (!mounted) return;
      setState(() {
        _termuxInfo = t;
        _storageInfo = s;
        _vaultPathInfo = v;
        _guardInfo = g;
        _kashkoolWorkspace = k;
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

  Map<String, dynamic> _kashkoolWorkspace = {};

  Future<void> _runCommand() async {
    final raw = _commandController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _isRunningCommand = true;
      _terminalOutput += '\n>>> $raw\n';
    });
    try {
      final parts = raw.split(RegExp(r'\s+'));
      final cmd = parts.first;
      final args = parts.skip(1).toList();
      final result = await widget.bridge.runAlpineCommand(cmd, args, timeoutSec: 30);
      final success = result['success'] == true;
      final output = success
          ? (result['output'] ?? '').toString()
          : (result['error'] ?? 'Unknown error').toString();
      if (!mounted) return;
      setState(() {
        _terminalOutput += '$output\n';
        _isRunningCommand = false;
        _commandController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _terminalOutput += 'خطأ: $e\n';
        _isRunningCommand = false;
      });
    }
  }

  Future<void> _runSavior() async {
    final prompt = _saviorController.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _isRunningSavior = true;
      _saviorOutput = '';
    });
    try {
      final result = await widget.bridge.runKashkoolSavior(
        _selectedRole,
        _selectedModel,
        prompt,
        timeoutSec: 120,
      );
      final success = result['success'] == true;
      final output = success
          ? (result['output'] ?? '').toString()
          : (result['error'] ?? 'Unknown error').toString();
      if (!mounted) return;
      setState(() {
        _saviorOutput = output;
        _isRunningSavior = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saviorOutput = 'خطأ: $e';
        _isRunningSavior = false;
      });
    }
  }

  Future<void> _runFortressGuard() async {
    setState(() {
      _isRunningGuard = true;
      _guardOutput = '';
    });
    try {
      final result = await widget.bridge.runFortressGuard(timeoutSec: 60);
      final success = result['success'] == true;
      final output = success
          ? (result['output'] ?? '').toString()
          : (result['error'] ?? 'Unknown error').toString();
      if (!mounted) return;
      setState(() {
        _guardOutput = output;
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
                    data: 'FORTRESS STUDIO',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentCyan, fontFamily: 'Arabic'),
                    forceLtr: true,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshAll,
                    child: const BidiText(data: 'تحديث الحالة', style: TextStyle(fontSize: 12)),
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
                            data: 'حالة النظام والجسر الأصلي',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _infoItem('Termux مثبت', _termuxInfo['installed'] == true)),
                              Expanded(child: _infoItem('السماح بالتطبيقات الخارجية', _termuxInfo['allowExternalApps'] == true)),
                              Expanded(child: _infoItem('أذونات التخزين', _storageInfo['success'] == true || _storageInfo['value'] == true)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_vaultPathInfo.isNotEmpty)
                            CodeBlock(
                              code: 'مسار Vault: ${_vaultPathInfo['value'] ?? _vaultPathInfo.toString()}\nالحارس: ${_guardInfo['fortressGuardExists'] == true ? 'موجود' : 'غير موجود'}\nترينيتي: ${_guardInfo['trinityExists'] == true ? 'موجود' : 'غير موجود'}\nالحالة: ${_guardInfo['stateExists'] == true ? 'موجود' : 'غير موجود'}',
                            ),
                          const SizedBox(height: 12),
                          if (_kashkoolWorkspace.isNotEmpty)
                            CodeBlock(
                              code: 'كشكول workspace: ${_kashkoolWorkspace['path']}\nموجود: ${_kashkoolWorkspace['exists'] == true ? 'نعم' : 'لا'}\nالمكدس جاهز: ${_kashkoolWorkspace['stack_ready'] == true ? 'نعم' : 'لا'}\nخالي من Gemini/Firebase: ${_kashkoolWorkspace['forbidden_free'] == true ? 'نعم' : 'لا'}',
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
                            data: 'kashkool-savior - الموجّه الموحّد',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: 'الدور',
                                    labelStyle: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                                  ),
                                  items: _roles.map((r) => DropdownMenuItem(
                                    value: r,
                                    child: BidiText(data: r, style: const TextStyle(fontFamily: 'Arabic')),
                                  )).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedRole = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedModel,
                                  decoration: const InputDecoration(
                                    labelText: 'الموديل',
                                    labelStyle: TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                                  ),
                                  items: _models.map((m) => DropdownMenuItem(
                                    value: m,
                                    child: BidiText(data: m, style: const TextStyle(fontFamily: 'Mono')),
                                  )).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedModel = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _saviorController,
                            decoration: const InputDecoration(
                              hintText: 'أدخل نص المهمة أو النَصّ المطلوب معالجته',
                              hintStyle: TextStyle(color: AppTheme.textMuted),
                            ),
                            style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textPrimary),
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRunningSavior || _saviorController.text.trim().isEmpty ? null : _runSavior,
                              child: BidiText(
                                data: _isRunningSavior ? 'جارٍ المعالجة...' : 'تشغيل savior',
                                style: const TextStyle(fontFamily: 'Arabic', fontSize: 12),
                              ),
                            ),
                          ),
                          if (_saviorOutput.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: CodeBlock(code: _saviorOutput),
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
                            data: 'المحطة الطرفية (Alpine proot)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF30363D), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: BidiText(
                                data: _terminalOutput.isEmpty ? 'لا يوجد مخرجات بعد' : _terminalOutput,
                                style: const TextStyle(fontFamily: 'Mono', fontSize: 12, color: Color(0xFFE4E4E7), height: 1.4),
                                forceLtr: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commandController,
                                  decoration: const InputDecoration(
                                    hintText: 'أدخل أمر Alpine (مثل: ls -la /mnt/sdcard/opencode/build-vault)',
                                    hintStyle: TextStyle(color: AppTheme.textMuted),
                                  ),
                                  style: const TextStyle(fontFamily: 'Mono', color: AppTheme.textPrimary),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _runCommand(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isRunningCommand || _commandController.text.trim().isEmpty ? null : _runCommand,
                                child: BidiText(
                                  data: _isRunningCommand ? 'جارٍ التشغيل...' : 'تنفيذ',
                                  style: const TextStyle(fontFamily: 'Arabic', fontSize: 12),
                                ),
                              ),
                            ],
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
                            data: 'الحارس الحتمي (Fortress Guard)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRunningGuard ? null : _runFortressGuard,
                              child: BidiText(
                                data: _isRunningGuard ? 'جارٍ الفحص...' : 'تشغيل fortress-guard',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, bool value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BidiText(data: label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'Arabic')),
        const SizedBox(height: 4),
        BidiText(
          data: value ? 'نعم' : 'لا',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: value ? AppTheme.accentGreen : AppTheme.accentRed,
            fontFamily: 'Mono',
          ),
          forceLtr: true,
        ),
      ],
    );
  }
}
