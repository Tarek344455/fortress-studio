import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/system_state.dart';

class SystemService {
  static const String vaultPath = '/mnt/sdcard/opencode/build-vault';
  static const String stateFile = '$vaultPath/state/system_state.json';
  static const Duration timeout = Duration(seconds: 5);

  Future<SystemState> fetchState() async {
    try {
      final uri = Uri.parse('http://127.0.0.1:4000/health');
      final response = await http.get(uri).timeout(timeout);
      if (response.statusCode == 200) {
        return SystemState(
          dns: 'ok',
          port8888: '200',
          port4000: response.statusCode.toString(),
          updated: DateTime.now().toIso8601String(),
        );
      }
      return SystemState(
        dns: 'ok',
        port8888: response.statusCode.toString(),
        port4000: response.statusCode.toString(),
        updated: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return SystemState(
        dns: 'fail',
        port8888: '000',
        port4000: '000',
        updated: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<List<ComponentStatus>> checkComponents() async {
    final components = <ComponentStatus>[];
    final checks = [
      {'name': 'OpenCode', 'port': '8888', 'url': 'http://127.0.0.1:8888/global/health'},
      {'name': 'Savior', 'port': '4000', 'url': 'http://127.0.0.1:4000/health'},
      {'name': 'Fortress Deck', 'port': '4050', 'url': 'http://127.0.0.1:4050/health'},
    ];
    for (final check in checks) {
      try {
        final uri = Uri.parse(check['url'] as String);
        final response = await http.get(uri).timeout(timeout);
        components.add(ComponentStatus(
          name: check['name'] as String,
          port: check['port'] as String,
          httpCode: response.statusCode.toString(),
          isOnline: response.statusCode >= 200 && response.statusCode < 500,
        ));
      } catch (e) {
        components.add(ComponentStatus(
          name: check['name'] as String,
          port: check['port'] as String,
          httpCode: '000',
          isOnline: false,
        ));
      }
    }
    return components;
  }

  Future<String> readFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }
}
