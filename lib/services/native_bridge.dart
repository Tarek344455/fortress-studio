import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('fortress.studio.app/bridge');

  Future<Map<String, dynamic>> callMethod(String method, {Map<String, dynamic>? arguments}) async {
    try {
      final result = await _channel.invokeMethod(method, arguments);
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return <String, dynamic>{'value': result};
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
}
