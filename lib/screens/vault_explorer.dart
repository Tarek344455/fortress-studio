import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bidi_text.dart';
import '../widgets/code_block.dart';

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
  String _editedContent = '';

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
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
      _editedContent = '';
    });
    try {
      final result = await widget.bridge.listDirectory(path);
      if (result['exists'] == true) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(result['items'] ?? []);
        });
      } else {
        setState(() {
          _items = [];
        });
      }
    } catch (e) {
      setState(() {});
    } finally {
      setState(() => _isLoading = false);
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
      _editedContent = '';
    });
    try {
      final result = await widget.bridge.readFile(path);
      if (result['exists'] == true) {
        setState(() {
          _fileContent = result['content'] ?? '';
          _editedContent = _fileContent;
        });
        final bakResult = await widget.bridge.readFile('$path.bak');
        if (bakResult['exists'] == true) {
          setState(() {
            _bakContent = bakResult['content'] ?? '';
          });
        }
      } else {
        setState(() {
          _fileContent = 'خطأ: ${result['error'] ?? 'ملف غير موجود'}';
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = 'خطأ في قراءة الملف: $e';
      });
    } finally {
      setState(() => _isLoading = false);
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
      setState(() {
        _diffOutput = result['output'] ?? result['error'] ?? 'لا يوجد فرق';
      });
    } catch (e) {
      setState(() {
        _diffOutput = 'خطأ في حساب الفرق: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _atomicWrite() async {
    if (_selectedFile.isEmpty) return;
    setState(() {
      _isLoading = true;
      _editing = false;
    });
    try {
      final result = await widget.bridge.atomicWrite(_selectedFile, _editedContent);
      if (result['success'] == true) {
        setState(() {
          _fileContent = _editedContent;
        });
      } else {
        setState(() {
          _fileContent = 'خطأ في الحفظ: ${result['error'] ?? 'غير معروف'}';
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = 'خطأ في الحفظ: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rollbackFile() async {
    if (_selectedFile.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await widget.bridge.rollbackFile(_selectedFile);
      if (result['success'] == true) {
        final readResult = await widget.bridge.readFile(_selectedFile);
        if (readResult['exists'] == true) {
          setState(() {
            _fileContent = readResult['content'] ?? '';
            _editedContent = _fileContent;
          });
        }
      } else {
        setState(() {
          _fileContent = 'خطأ في التراجع: ${result['error'] ?? 'غير معروف'}';
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = 'خطأ في التراجع: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final isDir = item['isDirectory'] ?? false;
    final name = item['name'] ?? '';
    final path = item['path'] ?? '';
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
              decoration: BoxDecoration(
                color: AppTheme.glassSurface,
                border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CodeBlock(
                      code: _currentPath,
                      onCopy: () {},
                    ),
                  ),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.glassSurface,
                            border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
                          ),
                          child: const BidiText(
                            data: 'ملفات المجلد',
                            style: TextStyle(fontFamily: 'Arabic', fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        Expanded(
                          child: _isLoading
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
                          decoration: BoxDecoration(
                            color: AppTheme.glassSurface,
                            border: Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: CodeBlock(
                                  code: _selectedFile,
                                  onCopy: () {},
                                ),
                              ),
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
                            child: Container(
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
                        if (!_showDiff || _diffOutput.isEmpty)
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_editing || _editedContent.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const BidiText(
                                            data: 'التعديل الذري (سيتم إنشاء .bak تلقائيًا)',
                                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'Arabic'),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            maxLines: 10,
                                            style: const TextStyle(fontFamily: 'Mono', fontSize: 11, color: Color(0xFFE4E4E7)),
                                            controller: TextEditingController(text: _editedContent),
                                            onChanged: (v) => _editedContent = v,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(0xFF0D1117),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: AppTheme.glassBorder),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: _isLoading ? null : _atomicWrite,
                                                  child: const BidiText(data: 'حفظ ذري مع .bak', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _editedContent = _fileContent;
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
                                      CodeBlock(
                                        code: _fileContent,
                                        onCopy: () {},
                                      ),
                                    if (!_editing && _selectedFile.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: _isLoading ? null : () => setState(() => _editing = true),
                                                child: const BidiText(data: 'تعديل ذري', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (_bakContent.isNotEmpty)
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed: _rollbackFile,
                                                  child: const BidiText(data: 'تراجع سريع من .bak', style: TextStyle(fontFamily: 'Arabic', fontSize: 12)),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
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
