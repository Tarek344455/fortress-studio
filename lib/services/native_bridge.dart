import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('fortress.studio.app/bridge');
  static const String _vaultPath = '/mnt/sdcard/opencode/build-vault';
  static const String _workshopProfile = '$_vaultPath/workshop_profile.json';

  final Map<String, String> _webFiles = {
    '$_vaultPath/state/system_state.json': const JsonEncoder.withIndent('  ').convert({
      'dns': 'ok',
      'port_8888': '200',
      'port_4000': '200',
      'port_4050': '200',
      'routing_mode': 'fast',
      'active_agent': 'nemotron',
      'updated': '2026-11-27T00:00:00Z',
    }),
    '$_vaultPath/state/system_state.json.bak': const JsonEncoder.withIndent('  ').convert({
      'dns': 'ok',
      'port_8888': '401',
      'port_4000': '200',
      'port_4050': '000',
      'routing_mode': 'fast',
      'active_agent': 'nemotron',
      'updated': '2026-11-26T23:00:00Z',
    }),
    '$_vaultPath/workshop_profile.json': const JsonEncoder.withIndent('  ').convert({
      'vault_path': _vaultPath,
      'kashkool_app_path': '/mnt/sdcard/opencode/karkhana/products/kashkool',
      'kashkool_stack': ['flutter', 'supabase', 'kashkool_ai_client'],
      'forbidden': ['gemini', 'firebase'],
      'bridge_channel': 'fortress.studio.app/bridge',
      'termux_package': 'com.termux',
      'termux_run_action': 'com.termux.RUN_COMMAND',
      'routing_modes': ['fast', 'builder', 'deep_reasoning', 'guard'],
      'agents': ['nemotron', 'deepseek', 'qwen', 'claude-cli', 'opencode', 'kashkool-savior', 'Antigravity'],
      'updated': '2026-11-27T00:00:00Z',
    }),
    '$_vaultPath/tools/fortress_guard.py':
        'import json\nprint(json.dumps({"status": "PASS", "vault": "$_vaultPath"}, indent=2))\n',
    '$_vaultPath/tools/trinity.py':
        'print("[trinity] OpenCode (:8888) -> ACTIVE\\n[trinity] Savior (:4000) -> PASS\\n[trinity] Fortress Deck (:4050) -> PASS")\n',
    '$_vaultPath/tools/kashkool_studio.py':
        'import sys\nprint("[kashkool-savior] " + " ".join(sys.argv[1:]))\n',
    '$_vaultPath/playbooks/trinity_playbook.md':
        '# Trinity Fortress Playbook\n\n1. Check storage and Termux\n2. Run fortress-guard\n3. Stage atomic writes with .bak\n',
    '$_vaultPath/scripts/bootstrap_alpine.sh':
        '#!/bin/sh\necho "Alpine proot ready at $_vaultPath"\n',
    '$_vaultPath/studio/out/session_summary.txt':
        'Fortress Studio Session Summary\nActive vault: $_vaultPath\n',
  };

  final Set<String> _webDirs = {
    _vaultPath,
    '$_vaultPath/state',
    '$_vaultPath/playbooks',
    '$_vaultPath/studio',
    '$_vaultPath/studio/out',
    '$_vaultPath/scripts',
    '$_vaultPath/tools',
  };

  bool _webStorageGranted = true;

  Future<Map<String, dynamic>> callMethod(String method, {Map<String, dynamic>? arguments}) async {
    if (kIsWeb) {
      return _handleWebFallback(method, arguments ?? const <String, dynamic>{});
    }
    try {
      final result = await _channel.invokeMethod<dynamic>(method, arguments);
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return <String, dynamic>{'value': result};
    } on MissingPluginException {
      return _handleWebFallback(method, arguments ?? const <String, dynamic>{});
    } on PlatformException catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.message ?? 'Unknown platform error',
        'code': e.code,
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString(),
        'code': 'EXCEPTION',
      };
    }
  }

  Map<String, dynamic> _handleWebFallback(String method, Map<String, dynamic> args) {
    switch (method) {
      case 'checkTermux':
        return <String, dynamic>{
          'installed': true,
          'allowExternalApps': true,
          'package': 'com.termux',
        };
      case 'checkStoragePermission':
        return <String, dynamic>{'success': _webStorageGranted};
      case 'requestStoragePermission':
        _webStorageGranted = true;
        return <String, dynamic>{'success': true};
      case 'getVaultPath':
        return <String, dynamic>{'value': _vaultPath};
      case 'checkFortressGuard':
        return <String, dynamic>{
          'vaultPath': _vaultPath,
          'fortressGuardExists': _webFiles.containsKey('$_vaultPath/tools/fortress_guard.py'),
          'trinityExists': _webFiles.containsKey('$_vaultPath/tools/trinity.py'),
          'stateExists': _webFiles.containsKey('$_vaultPath/state/system_state.json'),
          'guardPath': '$_vaultPath/tools/fortress_guard.py',
          'trinityPath': '$_vaultPath/tools/trinity.py',
          'statePath': '$_vaultPath/state/system_state.json',
        };
      case 'listVault':
        final path = (args['path'] ?? _vaultPath).toString();
        if (!_webDirs.contains(path)) {
          return <String, dynamic>{'exists': false, 'error': 'Path not found: $path'};
        }
        final items = <Map<String, dynamic>>[];
        for (final d in _webDirs) {
          if (d != path && d.startsWith('$path/')) {
            final rest = d.substring(path.length + 1);
            if (!rest.contains('/')) {
              items.add(<String, dynamic>{
                'name': rest,
                'path': d,
                'isDirectory': true,
                'size': 0,
                'lastModified': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        }
        for (final entry in _webFiles.entries) {
          if (entry.key.startsWith('$path/')) {
            final rest = entry.key.substring(path.length + 1);
            if (!rest.contains('/')) {
              items.add(<String, dynamic>{
                'name': rest,
                'path': entry.key,
                'isDirectory': false,
                'size': entry.value.length,
                'lastModified': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        }
        items.sort((a, b) {
          final aDir = a['isDirectory'] == true;
          final bDir = b['isDirectory'] == true;
          if (aDir != bDir) return aDir ? -1 : 1;
          return a['name'].toString().compareTo(b['name'].toString());
        });
        return <String, dynamic>{'exists': true, 'path': path, 'items': items};
      case 'readFile':
        final path = (args['path'] ?? '').toString();
        final content = _webFiles[path];
        if (content == null) {
          return <String, dynamic>{'exists': false, 'error': 'File not found: $path'};
        }
        return <String, dynamic>{
          'exists': true,
          'path': path,
          'content': content,
          'size': content.length,
        };
      case 'writeFile':
        final path = (args['path'] ?? '').toString();
        final content = (args['content'] ?? '').toString();
        _webFiles[path] = content;
        return <String, dynamic>{'success': true, 'path': path, 'size': content.length};
      case 'atomicWrite':
        final path = (args['path'] ?? '').toString();
        final content = (args['content'] ?? '').toString();
        if (_webFiles.containsKey(path)) {
          _webFiles['$path.bak'] = _webFiles[path]!;
        }
        _webFiles[path] = content;
        return <String, dynamic>{
          'success': true,
          'path': path,
          'size': content.length,
          'bak': _webFiles.containsKey('$path.bak'),
        };
      case 'rollbackFile':
        final path = (args['path'] ?? '').toString();
        final bak = _webFiles['$path.bak'];
        if (bak == null) {
          return <String, dynamic>{'success': false, 'path': path, 'error': 'No .bak file found'};
        }
        _webFiles[path] = bak;
        return <String, dynamic>{'success': true, 'path': path, 'message': 'Rolled back from .bak'};
      case 'diffFiles':
        final path1 = (args['path1'] ?? '').toString();
        final path2 = (args['path2'] ?? '').toString();
        final f1 = _webFiles[path1];
        final f2 = _webFiles[path2];
        if (f1 == null) return <String, dynamic>{'success': false, 'error': 'File not found: $path1'};
        if (f2 == null) return <String, dynamic>{'success': false, 'error': 'File not found: $path2'};
        final lines1 = f1.split('\n');
        final lines2 = f2.split('\n');
        final maxLen = lines1.length > lines2.length ? lines1.length : lines2.length;
        final diff = <String>[];
        for (int i = 0; i < maxLen; i++) {
          final l1 = i < lines1.length ? lines1[i] : '';
          final l2 = i < lines2.length ? lines2[i] : '';
          if (l1 != l2) {
            diff.add('Line ${i + 1}:');
            diff.add('  < $l1');
            diff.add('  > $l2');
          }
        }
        return <String, dynamic>{
          'success': true,
          'output': diff.isEmpty ? 'No differences found' : diff.join('\n'),
        };
      case 'runTermuxCommand':
        final command = (args['command'] ?? '').toString();
        final cmdArgs = (args['args'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        if (command == 'which') {
          final target = cmdArgs.isNotEmpty ? cmdArgs.first : '';
          const supported = {
            'trinity',
            'fortress-guard',
            'start-savior',
            'start-deck',
            'opencode',
            'claude-free',
            'agy-cli',
            'kashkool-studio',
          };
          final found = supported.contains(target);
          return <String, dynamic>{
            'success': found,
            'exitCode': found ? 0 : 1,
            'output': found ? '/data/data/com.termux/files/usr/bin/$target' : '',
            'error': found ? '' : 'which: no $target in PATH',
          };
        }
        return <String, dynamic>{
          'success': true,
          'exitCode': 0,
          'output': '[termux] $command ${cmdArgs.join(' ')}',
        };
      case 'runAlpineCommand':
        final command = (args['command'] ?? '').toString();
        final cmdArgs = (args['args'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
        if (command == 'ls') {
          final target = cmdArgs.where((a) => !a.startsWith('-')).isNotEmpty
              ? cmdArgs.where((a) => !a.startsWith('-')).first
              : _vaultPath;
          final listed = _handleWebFallback('listVault', <String, dynamic>{'path': target});
          if (listed['exists'] != true) {
            return <String, dynamic>{'success': false, 'exitCode': 1, 'error': 'ls: $target: No such file or directory'};
          }
          final items = listed['items'] as List<Map<String, dynamic>>;
          return <String, dynamic>{
            'success': true,
            'exitCode': 0,
            'output': items.map((e) => e['name'].toString()).join('\n'),
          };
        }
        if (command == 'cat' && cmdArgs.isNotEmpty) {
          final read = _handleWebFallback('readFile', <String, dynamic>{'path': cmdArgs.first});
          if (read['exists'] != true) {
            return <String, dynamic>{'success': false, 'exitCode': 1, 'error': 'cat: ${cmdArgs.first}: No such file'};
          }
          return <String, dynamic>{'success': true, 'exitCode': 0, 'output': read['content']};
        }
        return <String, dynamic>{
          'success': true,
          'exitCode': 0,
          'output': '[alpine-proot] $command ${cmdArgs.join(' ')}',
        };
      case 'runKashkoolSavior':
        final role = (args['role'] ?? 'Plan').toString();
        final model = (args['model'] ?? 'nemotron').toString();
        final prompt = (args['prompt'] ?? '').toString();
        return <String, dynamic>{
          'success': true,
          'exitCode': 0,
          'output': '[kashkool-savior] role=$role model=$model\nPrompt: $prompt\nStatus: dispatched',
        };
      case 'runFortressGuard':
        return <String, dynamic>{
          'success': true,
          'exitCode': 0,
          'output': const JsonEncoder.withIndent('  ').convert({
            'status': 'PASS',
            'vaultPath': _vaultPath,
            'fortressGuardExists': _webFiles.containsKey('$_vaultPath/tools/fortress_guard.py'),
            'trinityExists': _webFiles.containsKey('$_vaultPath/tools/trinity.py'),
            'stateExists': _webFiles.containsKey('$_vaultPath/state/system_state.json'),
          }),
        };
      case 'readWorkshopProfile':
        final content = _webFiles[_workshopProfile];
        if (content == null) {
          return <String, dynamic>{'exists': false, 'error': 'Workshop profile not found: $_workshopProfile'};
        }
        return <String, dynamic>{
          'exists': true,
          'path': _workshopProfile,
          'content': content,
          'size': content.length,
        };
      case 'runGitHubSync':
        final repo = (args['repo'] ?? '').toString();
        final action = (args['action'] ?? 'status').toString();
        return <String, dynamic>{
          'success': true,
          'exitCode': 0,
          'output': '[github-sync] repo=$repo action=$action\nLocal-only mode: no remote operations performed',
        };
      default:
        return <String, dynamic>{'success': true, 'exitCode': 0, 'output': 'OK'};
    }
  }

  Future<Map<String, dynamic>> checkTermux() async {
    return await callMethod('checkTermux');
  }

  Future<Map<String, dynamic>> checkStoragePermission() async {
    return await callMethod('checkStoragePermission');
  }

  Future<Map<String, dynamic>> requestStoragePermission() async {
    return await callMethod('requestStoragePermission');
  }

  Future<Map<String, dynamic>> getVaultPath() async {
    return await callMethod('getVaultPath');
  }

  Future<Map<String, dynamic>> listDirectory(String path) async {
    return await callMethod('listVault', arguments: <String, dynamic>{'path': path});
  }

  Future<Map<String, dynamic>> readFile(String path) async {
    return await callMethod('readFile', arguments: <String, dynamic>{'path': path});
  }

  Future<Map<String, dynamic>> writeFile(String path, String content) async {
    return await callMethod('writeFile', arguments: <String, dynamic>{'path': path, 'content': content});
  }

  Future<Map<String, dynamic>> atomicWrite(String path, String content) async {
    return await callMethod('atomicWrite', arguments: <String, dynamic>{'path': path, 'content': content});
  }

  Future<Map<String, dynamic>> rollbackFile(String path) async {
    return await callMethod('rollbackFile', arguments: <String, dynamic>{'path': path});
  }

  Future<Map<String, dynamic>> diffFiles(String path1, String path2) async {
    return await callMethod('diffFiles', arguments: <String, dynamic>{'path1': path1, 'path2': path2});
  }

  Future<Map<String, dynamic>> runTermuxCommand(String command, List<String> args, {int timeoutSec = 30}) async {
    return await callMethod('runTermuxCommand', arguments: <String, dynamic>{
      'command': command,
      'args': args,
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> runAlpineCommand(String command, List<String> args, {int timeoutSec = 30}) async {
    return await callMethod('runAlpineCommand', arguments: <String, dynamic>{
      'command': command,
      'args': args,
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> runOpenCode(String command, List<String> args, {int timeoutSec = 60}) async {
    return await callMethod('runOpenCode', arguments: <String, dynamic>{
      'command': command,
      'args': args,
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> runKashkoolSavior(String role, String model, String prompt, {int timeoutSec = 120}) async {
    return await callMethod('runKashkoolSavior', arguments: <String, dynamic>{
      'role': role,
      'model': model,
      'prompt': prompt,
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> runGitHubSync(String repo, String action, {int timeoutSec = 60}) async {
    return await callMethod('runGitHubSync', arguments: <String, dynamic>{
      'repo': repo,
      'action': action,
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> runFortressGuard({int timeoutSec = 60}) async {
    return await callMethod('runFortressGuard', arguments: <String, dynamic>{
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> runTrinity(String command, List<String> args, {int timeoutSec = 60}) async {
    return await callMethod('runTrinity', arguments: <String, dynamic>{
      'command': command,
      'args': args,
      'timeoutSec': timeoutSec,
    });
  }

  Future<Map<String, dynamic>> checkFortressGuard() async {
    return await callMethod('checkFortressGuard');
  }

  Future<Map<String, dynamic>> readWorkshopProfile() async {
    return await callMethod('readWorkshopProfile');
  }
}
