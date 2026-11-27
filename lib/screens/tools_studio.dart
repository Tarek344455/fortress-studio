import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/status_badge.dart';
import '../services/native_bridge.dart';

class ToolsStudio extends StatefulWidget {
  final NativeBridge bridge;
  const ToolsStudio({super.key, required this.bridge});

  @override
  State<ToolsStudio> createState() => _ToolsStudioState();
}

class _ToolsStudioState extends State<ToolsStudio> {
  List<Map<String, dynamic>> _tools = [];
  bool _isLoading = false;
  String _selectedTool = '';
  final TextEditingController _argsController = TextEditingController();
  String _commandOutput = '';
  bool _isRunning = false;

  final List<Map<String, String>> _registeredTools = const [
    {'name': 'trinity', 'command': 'trinity', 'description': 'منظم ترينيتي فيرترس'},
    {'name': 'fortress-guard', 'command': 'fortress-guard', 'description': 'حارس التحقق من النظام'},
    {'name': 'start-savior', 'command': 'start-savior', 'description': 'تشغيل سفير على المنفذ 4000'},
    {'name': 'start-deck', 'command': 'start-deck', 'description': 'تشغيل حصن سطح السفينة على المنفذ 4050'},
    {'name': 'opencode', 'command': 'opencode', 'description': 'واجهة أوبن كود'},
    {'name': 'claude-free', 'command': 'claude-free', 'description': 'كلود فري عبر بروكسي سفير'},
    {'name': 'agy-cli', 'command': 'agy-cli', 'description': 'أداة أي جي آي'},
    {'name': 'kashkool-studio', 'command': 'kashkool-studio', 'description': 'استوديو كشكول'},
  ];

  @override
  void initState() {
    super.initState();
    _refreshTools();
  }

  @override
  void dispose() {
    _argsController.dispose();
    super.dispose();
  }

  Future<void> _refreshTools() async {
    setState(() => _isLoading = true);
    try {
      final installed = <String, bool>{};
      for (final tool in _registeredTools) {
        final cmdResult = await widget.bridge.runTermuxCommand('which', <String>[tool['command']!], timeoutSec: 10);
        installed[tool['name']!] = cmdResult['success'] == true;
      }
      if (!mounted) return;
      setState(() {
        _tools = _registeredTools.map((t) {
          final name = t['name']!;
          return {
            'name': name,
            'command': t['command']!,
            'description': t['description']!,
            'isInstalled': installed[name] ?? false,
          };
        }).toList();
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

  Future<void> _runTool(Map<String, dynamic> tool) async {
    setState(() {
      _selectedTool = (tool['name'] ?? '').toString();
      _isRunning = true;
      _commandOutput = '';
    });
    try {
      final rawArgs = _argsController.text.trim();
      final List<String> args = rawArgs.isEmpty ? <String>[] : rawArgs.split(RegExp(r'\s+'));
      final result = await widget.bridge.runTermuxCommand(tool['command'].toString(), args, timeoutSec: 60);
      final success = result['success'] == true;
      final output = success
          ? (result['output'] ?? '').toString()
          : (result['error'] ?? 'خطأ غير معروف').toString();
      if (!mounted) return;
      setState(() {
        _commandOutput = 'رمز الخروج: ${result['exitCode'] ?? -1}\nالمخرج:\n$output';
        _isRunning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commandOutput = 'خطأ في تنفيذ الأمر: $e';
        _isRunning = false;
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
                    data: 'مركز الأدوات واستوديو كشكول',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshTools,
                    child: const BidiText(data: 'تحديث', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppTheme.glassSurface,
                                  border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
                                ),
                                child: const BidiText(
                                  data: 'أدوات النظام المسجّلة',
                                  style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _tools.length,
                                  itemBuilder: (context, index) {
                                    final tool = _tools[index];
                                    final isInstalled = tool['isInstalled'] == true;
                                    final selected = tool['name'] == _selectedTool;
                                    return ListTile(
                                      leading: Icon(
                                        isInstalled ? Icons.check_circle : Icons.error,
                                        color: isInstalled ? AppTheme.accentGreen : AppTheme.accentRed,
                                        size: 20,
                                      ),
                                      title: BidiText(
                                        data: (tool['name'] ?? '').toString(),
                                        style: const TextStyle(fontFamily: 'Arabic', fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: BidiText(
                                        data: (tool['description'] ?? '').toString(),
                                        style: const TextStyle(fontFamily: 'Arabic', fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                      trailing: StatusBadge(status: isInstalled ? 'PASS' : 'FAIL'),
                                      selected: selected,
                                      onTap: () => setState(() => _selectedTool = (tool['name'] ?? '').toString()),
                                      tileColor: selected ? AppTheme.accentCyan.withValues(alpha: 0.1) : null,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.glassBorder),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.glassSurface,
                            border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BidiText(
                                data: _selectedTool.isEmpty ? 'اختر أداة' : _selectedTool,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _argsController,
                                decoration: const InputDecoration(
                                  hintText: 'وسائط الأمر (اختياري)',
                                  hintStyle: TextStyle(color: AppTheme.textMuted),
                                ),
                                style: const TextStyle(fontFamily: 'Mono', color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isRunning || _selectedTool.isEmpty
                                      ? null
                                      : () {
                                          final matches = _tools.where((t) => t['name'] == _selectedTool);
                                          if (matches.isNotEmpty) {
                                            _runTool(matches.first);
                                          }
                                        },
                                  child: BidiText(
                                    data: _isRunning ? 'جارٍ التنفيذ...' : 'تنفيذ الأمر',
                                    style: const TextStyle(fontFamily: 'Arabic'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _commandOutput.isEmpty
                              ? const Center(
                                  child: BidiText(
                                    data: 'لا يوجد مخرجات',
                                    style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Arabic'),
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D1117),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF30363D), width: 1),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: BidiText(
                                        data: _commandOutput,
                                        style: const TextStyle(fontFamily: 'Mono', fontSize: 12, color: Color(0xFFE4E4E7), height: 1.4),
                                        forceLtr: true,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
