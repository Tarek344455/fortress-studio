class CliTool {
  final String name;
  final String command;
  final String description;
  final bool isInstalled;
  final String lastOutput;
  final DateTime? lastRun;
  final bool isRunning;

  CliTool({
    required this.name,
    required this.command,
    required this.description,
    required this.isInstalled,
    this.lastOutput = '',
    this.lastRun,
    this.isRunning = false,
  });

  factory CliTool.fromJson(Map<String, dynamic> json) {
    return CliTool(
      name: json['name'] ?? '',
      command: json['command'] ?? '',
      description: json['description'] ?? '',
      isInstalled: json['is_installed'] ?? false,
      lastOutput: json['last_output'] ?? '',
      lastRun: json['last_run'] != null ? DateTime.tryParse(json['last_run']) : null,
      isRunning: json['is_running'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'command': command,
      'description': description,
      'is_installed': isInstalled,
      'last_output': lastOutput,
      'last_run': lastRun?.toIso8601String(),
      'is_running': isRunning,
    };
  }
}
