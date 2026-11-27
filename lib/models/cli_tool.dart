class CliTool {
  final String name;
  final String command;
  final String description;
  final bool isInstalled;
  final String lastOutput;
  final DateTime? lastRun;
  final bool isRunning;
  final String agentType;
  final String routingMode;
  final int priority;

  CliTool({
    required this.name,
    required this.command,
    required this.description,
    required this.isInstalled,
    this.lastOutput = '',
    this.lastRun,
    this.isRunning = false,
    this.agentType = 'system',
    this.routingMode = 'fast',
    this.priority = 0,
  });

  factory CliTool.fromJson(Map<String, dynamic> json) {
    return CliTool(
      name: (json['name'] ?? '').toString(),
      command: (json['command'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isInstalled: json['is_installed'] == true,
      lastOutput: (json['last_output'] ?? '').toString(),
      lastRun: json['last_run'] is String ? DateTime.tryParse(json['last_run'] as String) : null,
      isRunning: json['is_running'] == true,
      agentType: (json['agent_type'] ?? 'system').toString(),
      routingMode: (json['routing_mode'] ?? 'fast').toString(),
      priority: json['priority'] is int ? json['priority'] as int : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
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
      'agent_type': agentType,
      'routing_mode': routingMode,
      'priority': priority,
    };
  }
}

class RoutingProfile {
  final String mode;
  final List<String> models;
  final List<String> agents;
  final Duration timeout;
  final int maxRetries;
  final bool allowFallback;
  final bool requiresGuardPass;

  RoutingProfile({
    required this.mode,
    required this.models,
    required this.agents,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 1,
    this.allowFallback = true,
    this.requiresGuardPass = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'models': models,
      'agents': agents,
      'timeout': timeout.inSeconds,
      'max_retries': maxRetries,
      'allow_fallback': allowFallback,
      'requires_guard_pass': requiresGuardPass,
    };
  }
}
