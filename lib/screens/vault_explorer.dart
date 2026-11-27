import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';
import '../services/native_bridge.dart';

class VaultExplorer extends StatefulWidget {
  final NativeBridge bridge;
  const VaultExplorer({super.key, required this.bridge});

  @override
  State<VaultExplorer> createState() => _VaultExplorerState();
}

class _VaultExplorerState extends State<VaultExplorer> {
  String _currentPath = '/mnt/sdcard/opencode/build-vault';
  List<Map<String, dynamic>> _items = [];
  String _selectedFile = '';
  String _fileContent = '';
  String _bakContent = '';
  String _diffOutput = '';
  bool _isLoading = false;
  bool _showDiff = false;
  bool _editing = false;
  final TextEditingController _editorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _currentPath = path;
      _isLoading = true;
      _selectedFile = '';
      _fileContent = '';
      _bakContent = '';
      _diffOutput = '';
      _showDiff = false;
      _editing = false;
      _editorController.clear();
    });
    try {
      final result = await widget.bridge.listDirectory(path);
      if (!mounted) return;
      if (result['exists'] == true) {
        final rawItems = result['items'];
        final parsed = rawItems is List
            ? rawItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        setState(() => _items = parsed);
      } else {
        setState(() => _items = []);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _readFile(String path) async {
    setState(() {
      _selectedFile = path;
      _isLoading = true;
      _fileContent = '';
      _bakContent = '';
      _diffOutput = '';
      _showDiff = false;
      _editing = false;
      _editorController.clear();
    });
    try {
      final result = await widget.bridge.readFile(path);
      if (!mounted) return;
      if (result['exists'] == true) {
        final content = (result['content'] ?? '').toString();
        setState(() {
          _fileContent = content;
          _editorController.text = content;
        });
        final bakResult = await widget.bridge.readFile('$path.bak');
        if (mounted && bakResult['exists'] == true) {
          setState(() => _bakContent = (bakResult['content'] ?? '').toString());
        }
      } else {
        setState(() {
          _fileContent = 'خطأ: ${result['error'] ?? 'ملف غير موجود'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fileContent = 'خطأ في قراءة الملف: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _computeDiff() async {
    if (_selectedFile.isEmpty) return;
    setState(() {
      _isLoading = true;
      _showDiff = true;
      _diffOutput = '';
    });
    try {
      final result = await widget.bridge.diffFiles(_selectedFile, '$_selectedFile.bak');
      if (!mounted) return;
      setState(() {
        _diffOutput = (result['output'] ?? result['error'] ?? 'لا يوجد فرق').toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _diffOutput = 'خطأ في حساب الفرق: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _atomicWrite() async {
    if (_selectedFile.isEmpty) return;
    final nextContent = _editorController.text;
    setState(() {
      _isLoading = true;
      _editing = false;
    });
    try {
      final result = await widget.bridge.atomicWrite(_selectedFile, nextContent);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() => _fileContent = nextContent);
        final bakResult = await widget.bridge.readFile('$_selectedFile.bak');
        if (mounted && bakResult['exists'] == true) {
          setState(() => _bakContent = (bakResult['content'] ?? '').toString());
        }
      } else {
        setState(() {
          _fileContent = 'خطأ في الحفظ: ${result['error'] ?? 'غير معروف'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fileContent = 'خطأ في الحفظ: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rollbackFile() async {
    if (_selectedFile.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await widget.bridge.rollbackFile(_selectedFile);
      if (!mounted) return;
      if (result['success'] == true) {
        final readResult = await widget.bridge.readFile(_selectedFile);
        if (mounted && readResult['exists'] == true) {
          final content = (readResult['content'] ?? '').toString();
          setState(() {
            _fileContent = content;
            _editorController.text = content;
            _showDiff = false;
          });
        }
      } else {
        setState(() {
          _fileContent = 'خطأ في التراجع: ${result['error'] ?? 'غير معروف'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fileContent = 'خطأ في التراجع: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final isDir = item['isDirectory'] == true;
    final name = (item['name'] ?? '').toString();
    final path = (item['path'] ?? '').toString();
    return ListTile(
      leading: Icon(isDir ? Icons.folder : Icons.description, color: AppTheme.accentCyan, size: 20),
      title: BidiText(
        data: name,
        style: const TextStyle(fontFamily: 'Arabic', fontSize: 14),
        forceLtr: !isDir,
      ),
      trailing: isDir ? const Icon(Icons.chevron_right, color: AppTheme.textMuted) : null,
      onTap: () {
        if (isDir) {
          _loadDirectory(path);
        } else {
          _readFile(path);
        }
      },
    );
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
                  Expanded(child: CodeBlock(code: _currentPath)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
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
                            data: 'ملفات المجلد',
                            style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        Expanded(
                          child: _isLoading && _items.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) => _buildItem(_items[index]),
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
                          child: Row(
                            children: [
                              Expanded(child: CodeBlock(code: _selectedFile)),
                              if (_selectedFile.isNotEmpty) ...[
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: () => _readFile(_selectedFile),
                                ),
                                if (_bakContent.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.compare_arrows, size: 20),
                                    onPressed: _computeDiff,
                                  ),
                                if (_bakContent.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.undo, size: 20),
                                    onPressed: _rollbackFile,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        if (_showDiff && _diffOutput.isNotEmpty)
                          Expanded(
                            child: SingleChildScrollView(
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
                                    data: _diffOutput,
                                    style: const TextStyle(fontFamily: 'Mono', fontSize: 11, color: Color(0xFFE4E4E7), height: 1.4),
                                    forceLtr: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!_showDiff || _diffOutput.isEmpty)
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_editing)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const BidiText(
                                                data: 'التعديل الذري (سيتم إنشاء .bak تلقائيًا)',
                                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'Arabic'),
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                maxLines: 12,
                                                style: const TextStyle(fontFamily: 'Mono', fontSize: 11, color: Color(0xFFE4E4E7)),
                                                controller: _editorController,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: const Color(0xFF0D1117),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: const BorderSide(color: AppTheme.glassBorder),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: _isLoading ? null : _atomicWrite,
                                                      child: const BidiText(data: 'حفظ ذري مع .bak', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  OutlinedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _editorController.text = _fileContent;
                                                        _editing = false;
                                                      });
                                                    },
                                                    child: const BidiText(data: 'إلغاء', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        if (!_editing)
                                          CodeBlock(code: _fileContent),
                                        if (!_editing && _selectedFile.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: _isLoading ? null : () => setState(() => _editing = true),
                                                    child: const BidiText(data: 'تعديل ذري', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                                  ),
                                                ),
                                                if (_bakContent.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: _rollbackFile,
                                                      child: const BidiText(data: 'تراجع سريع من .bak', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                                    ),
                                                  ),
                                                ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
