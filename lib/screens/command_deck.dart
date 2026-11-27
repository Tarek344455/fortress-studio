import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';
import '../services/native_bridge.dart';

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
  String _commandInput = '';
  bool _isRunningCommand = false;

  String _selectedRole = 'Plan';
  String _selectedModel = 'nemotron';
  String _saviorPrompt = '';
  bool _isRunningSavior = false;
  String _saviorOutput = '';

  bool _isRunningGuard = false;
  String _guardOutput = '';

  final List<String> _roles = ['Plan', 'Builder', 'Reviewer', 'Guard'];
  final List<String> _models = ['nemotron', 'deepseek', 'qwen', 'claude-cli'];

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

  Future<void> _runCommand() async {
    if (_commandInput.trim().isEmpty) return;
    setState(() {
      _isRunningCommand = true;
      _terminalOutput += '\n>>> $_commandInput\n';
    });
    try {
      final parts = _commandInput.trim().split(' ');
      final cmd = parts.first;
      final args = parts.skip(1).toList();
      final result = await widget.bridge.runAlpineCommand(cmd, args, timeoutSec: 30);
      final success = result['success'] == true;
      final output = success ? result['output'] ?? '' : result['error'] ?? 'Unknown error';
      setState(() {
        _terminalOutput += output + '\n';
        _isRunningCommand = false;
        _commandInput = '';
      });
    } catch (e) {
      setState(() {
        _terminalOutput += 'خطأ: $e\n';
        _isRunningCommand = false;
      });
    }
  }

  Future<void> _runSavior() async {
    if (_saviorPrompt.trim().isEmpty) return;
    setState(() {
      _isRunningSavior = true;
      _saviorOutput = '';
    });
    try {
      final result = await widget.bridge.runKashkoolSavior(
        _selectedRole,
        _selectedModel,
        _saviorPrompt,
        timeoutSec: 120,
      );
      final success = result['success'] == true;
      final output = success ? result['output'] ?? '' : result['error'] ?? 'Unknown error';
      setState(() {
        _saviorOutput = output;
        _isRunningSavior = false;
      });
    } catch (e) {
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
      final output = success ? result['output'] ?? '' : result['error'] ?? 'Unknown error';
      setState(() {
        _guardOutput = output;
        _isRunningGuard = false;
      });
    } catch (e) {
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
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
              ),
              child: Row(
                children: [
                  const BidiText(
                    data: 'FORTRESS STUDIO',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentCyan, fontFamily: 'Arabic'),
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
                    GlassCardWidget(
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
                              Expanded(child: _infoItem('Termux مثبت', _termuxInfo['installed'] ?? false)),
                              Expanded(child: _infoItem('السماح بالتطبيقات الخارجية', _termuxInfo['allowExternalApps'] ?? false)),
                              Expanded(child: _infoItem('أذونات التخزين', _storageInfo['success'] == true)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_vaultPathInfo.isNotEmpty)
                            CodeBlock(
                              code: 'مسار Vault: ${_vaultPathInfo['value'] ?? _vaultPathInfo.toString()}\nالحارس: ${_guardInfo['fortressGuardExists'] ?? false ? 'موجود' : 'غير موجود'}\nترينيتي: ${_guardInfo['trinityExists'] ?? false ? 'موجود' : 'غير موجود'}\nالحالة: ${_guardInfo['stateExists'] ?? false ? 'موجود' : 'غير موجود'}',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCardWidget(
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
                                  decoration: InputDecoration(
                                    labelText: 'الدور',
                                    labelStyle: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                                  ),
                                  items: _roles.map((r) => DropdownMenuItem(
                                    value: r,
                                    child: BidiText(data: r, style: const TextStyle(fontFamily: 'Arabic')),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedRole = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedModel,
                                  decoration: InputDecoration(
                                    labelText: 'الموديل',
                                    labelStyle: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textSecondary),
                                  ),
                                  items: _models.map((m) => DropdownMenuItem(
                                    value: m,
                                    child: BidiText(data: m, style: const TextStyle(fontFamily: 'Mono')),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedModel = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'أدخل نص المهمة أو النَصّ المطلوب معالجته',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                            ),
                            style: const TextStyle(fontFamily: 'Arabic', color: AppTheme.textPrimary),
                            maxLines: 3,
                            onChanged: (v) => _saviorPrompt = v,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isRunningSavior || _saviorPrompt.trim().isEmpty ? null : _runSavior,
                              child: BidiText(
                                data: _isRunningSavior ? 'جارٍ المعالجة...' : 'تشغيل savior',
                                style: const TextStyle(fontFamily: 'Arabic', fontSize: 12),
                              ),
                            ),
                          ),
                          if (_saviorOutput.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: CodeBlock(
                                code: _saviorOutput,
                                onCopy: () {},
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCardWidget(
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
                                  decoration: InputDecoration(
                                    hintText: 'أدخل أمر Alpine (مثل: ls -la /mnt/sdcard/opencode/build-vault)',
                                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                                  ),
                                  style: const TextStyle(fontFamily: 'Mono', color: AppTheme.textPrimary),
                                  onChanged: (v) => _commandInput = v,
                                  onSubmitted: (_) => _runCommand(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isRunningCommand || _commandInput.trim().isEmpty ? null : _runCommand,
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
                    GlassCardWidget(
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
                              child: CodeBlock(
                                code: _guardOutput,
                                onCopy: () {},
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

  Widget _infoItem(String label, bool value) {
    final isOk = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BidiText(data: label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'Arabic')),
        const SizedBox(height: 4),
        BidiText(data: value ? 'نعم' : 'لا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOk ? AppTheme.accentGreen : AppTheme.accentRed, fontFamily: 'Mono'), forceLtr: true),
      ],
    );
  }
}

class GlassCardWidget extends StatelessWidget {
  final Widget child;
  const GlassCardWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
