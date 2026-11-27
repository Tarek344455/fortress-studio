import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/status_badge.dart';
import '../widgets/code_block.dart';
import '../services/native_bridge.dart';
import '../models/cli_tool.dart';

class ToolsStudio extends StatefulWidget {
  final NativeBridge bridge;
  const ToolsStudio({super.key, required this.bridge});

  @override
  State<ToolsStudio> createState() => _ToolsStudioState();
}

class _ToolsStudioState extends State<ToolsStudio> {
  List<CliTool> _tools = [];
  bool _isLoading = false;
  CliTool? _selectedTool;
  final TextEditingController _argsController = TextEditingController();
  String _commandOutput = '';
  bool _isRunning = false;

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
      final installed = <CliTool>[];
      for (final tool in widget.bridge.routingEngine.profiles.expand((p) => p.agents).toSet().isNotEmpty ? <CliTool>[] : <CliTool>[]) {}
      for (final tool in widget.bridge.routingEngine.profiles.expand((p) => p.agents).toList()) {}
      final cliService = CliService(bridge: widget.bridge);
      final refreshed = await cliService.refreshTools();
      if (!mounted) return;
      setState(() {
        _tools = refreshed;
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

  Future<void> _runTool(CliTool tool) async {
    setState(() {
      _selectedTool = tool;
      _isRunning = true;
      _commandOutput = '';
    });
    try {
      final rawArgs = _argsController.text.trim();
      final List<String> args = rawArgs.isEmpty ? <String>[] : rawArgs.split(RegExp(r'\s+'));
      final result = await widget.bridge.runTermuxCommand(tool.command, args, timeoutSec: 60);
      final success = result['success'] == true;
      final output = success
          ? (result['output'] ?? '').toString()
          : (result['error'] ?? 'خطأ غير معروف').toString();
      if (!mounted) return;
      setState(() {
        _commandOutput = 'رمز الخروج: ${result['exitCode'] ?? -1}\nالأمر: ${result['command'] ?? tool.command}\nالمخرج:\n$output';
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
                                child: _tools.isEmpty
                                    ? const Center(
                                        child: BidiText(
                                          data: 'لا توجد أدوات',
                                          style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Arabic'),
                                        ),
                                      )
                                    : GridView.builder(
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 3.2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                        itemCount: _tools.length,
                                        itemBuilder: (context, index) {
                                          final tool = _tools[index];
                                          final isInstalled = tool.isInstalled;
                                          final selected = tool == _selectedTool;
                                          return InkWell(
                                            onTap: () => setState(() => _selectedTool = tool),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.glassSurface,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: selected ? AppTheme.accentCyan : AppTheme.glassBorder,
                                                  width: selected ? 2 : 1,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    isInstalled ? Icons.check_circle : Icons.error,
                                                    color: isInstalled ? AppTheme.accentGreen : AppTheme.accentRed,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  BidiText(
                                                    data: tool.name,
                                                    style: const TextStyle(fontFamily: 'Mono', fontSize: 11, fontWeight: FontWeight.w500),
                                                    forceLtr: true,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  BidiText(
                                                    data: tool.agentType,
                                                    style: TextStyle(fontFamily: 'Mono', fontSize: 9, color: AppTheme.textMuted),
                                                    forceLtr: true,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  StatusBadge(status: isInstalled ? 'PASS' : 'FAIL'),
                                                ],
                                              ),
                                            ),
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
                                data: _selectedTool == null ? 'اختر أداة' : _selectedTool!.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Arabic'),
                              ),
                              const SizedBox(height: 8),
                              if (_selectedTool != null) ...[
                                BidiText(
                                  data: 'النوع: ${_selectedTool!.agentType}  |  التوجيه: ${_selectedTool!.routingMode}  |  الأولوية: ${_selectedTool!.priority}',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'Mono', fontStyle: FontStyle.italic),
                                  forceLtr: true,
                                ),
                                const SizedBox(height: 12),
                              ],
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
                                  onPressed: _isRunning || _selectedTool == null
                                      ? null
                                      : () => _runTool(_selectedTool!),
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
