import '../code_generation/code_generator.dart';
import '../errors/error_reporter.dart';
import '../performance/performance_monitor.dart';

/// Global configuration for the Flutter Dev Toolkit.
///
/// Provides centralized configuration for all toolkit components
/// with sensible defaults and validation.
class ToolkitConfiguration {
  /// Configuration for state management features.
  final StateManagementConfig stateManagement;

  /// Configuration for navigation and routing features.
  final NavigationConfig navigation;

  /// Configuration for testing utilities.
  final TestingConfig testing;

  /// Configuration for performance monitoring.
  final PerformanceConfig performance;

  /// Configuration for code generation.
  final CodeGenerationConfig codeGeneration;

  /// Configuration for development tools.
  final DevelopmentToolsConfig developmentTools;

  /// Configuration for error reporting.
  final ErrorReportingConfig errorReporting;

  /// Whether to enable debug mode features.
  final bool debugMode;

  /// Whether to enable verbose logging.
  final bool verboseLogging;

  /// Creates a new toolkit configuration.
  const ToolkitConfiguration({
    this.stateManagement = const StateManagementConfig(),
    this.navigation = const NavigationConfig(),
    this.testing = const TestingConfig(),
    this.performance = const PerformanceConfig(),
    this.codeGeneration = const CodeGenerationConfig(),
    this.developmentTools = const DevelopmentToolsConfig(),
    this.errorReporting = const ErrorReportingConfig(),
    this.debugMode = false,
    this.verboseLogging = false,
  });

  /// Creates a configuration optimized for development.
  factory ToolkitConfiguration.development() {
    return const ToolkitConfiguration(
      debugMode: true,
      verboseLogging: true,
      stateManagement: StateManagementConfig(
        enableDebugging: true,
        enablePersistence: false,
      ),
      navigation: NavigationConfig(
        enableDeepLinking: true,
        enableDebugLogging: true,
      ),
      performance: PerformanceConfig(
        enableMonitoring: true,
        enableRealTimeWarnings: true,
      ),
      errorReporting: ErrorReportingConfig(
        minimumSeverity: ReportSeverity.debug,
        enableConsoleLogging: true,
      ),
    );
  }

  /// Creates a configuration optimized for production.
  factory ToolkitConfiguration.production() {
    return const ToolkitConfiguration(
      debugMode: false,
      verboseLogging: false,
      stateManagement: StateManagementConfig(
        enableDebugging: false,
        enablePersistence: true,
      ),
      navigation: NavigationConfig(
        enableDeepLinking: true,
        enableDebugLogging: false,
      ),
      performance: PerformanceConfig(
        enableMonitoring: false,
        enableRealTimeWarnings: false,
      ),
      errorReporting: ErrorReportingConfig(
        minimumSeverity: ReportSeverity.warning,
        enableConsoleLogging: false,
      ),
    );
  }

  /// Creates a configuration optimized for testing.
  factory ToolkitConfiguration.testing() {
    return const ToolkitConfiguration(
      debugMode: true,
      verboseLogging: false,
      stateManagement: StateManagementConfig(
        enableDebugging: false,
        enablePersistence: false,
      ),
      navigation: NavigationConfig(
        enableDeepLinking: false,
        enableDebugLogging: false,
      ),
      testing: TestingConfig(
        enableMockGeneration: true,
        enableTestDataFactories: true,
      ),
      performance: PerformanceConfig(
        enableMonitoring: false,
      ),
      errorReporting: ErrorReportingConfig(
        minimumSeverity: ReportSeverity.error,
        enableConsoleLogging: true,
      ),
    );
  }

  /// Validates the configuration and returns any issues found.
  List<ConfigurationIssue> validate() {
    final issues = <ConfigurationIssue>[];

    // Validate state management configuration
    issues.addAll(stateManagement.validate());

    // Validate navigation configuration
    issues.addAll(navigation.validate());

    // Validate testing configuration
    issues.addAll(testing.validate());

    // Validate performance configuration
    issues.addAll(performance.validate());

    // Validate code generation configuration
    issues.addAll(codeGeneration.validate());

    // Validate development tools configuration
    issues.addAll(developmentTools.validate());

    // Validate error reporting configuration
    issues.addAll(errorReporting.validate());

    return issues;
  }

  /// Creates a copy of this configuration with the specified changes.
  ToolkitConfiguration copyWith({
    StateManagementConfig? stateManagement,
    NavigationConfig? navigation,
    TestingConfig? testing,
    PerformanceConfig? performance,
    CodeGenerationConfig? codeGeneration,
    DevelopmentToolsConfig? developmentTools,
    ErrorReportingConfig? errorReporting,
    bool? debugMode,
    bool? verboseLogging,
  }) {
    return ToolkitConfiguration(
      stateManagement: stateManagement ?? this.stateManagement,
      navigation: navigation ?? this.navigation,
      testing: testing ?? this.testing,
      performance: performance ?? this.performance,
      codeGeneration: codeGeneration ?? this.codeGeneration,
      developmentTools: developmentTools ?? this.developmentTools,
      errorReporting: errorReporting ?? this.errorReporting,
      debugMode: debugMode ?? this.debugMode,
      verboseLogging: verboseLogging ?? this.verboseLogging,
    );
  }
}

/// Configuration for state management features.
class StateManagementConfig {
  /// Whether to enable debugging features.
  final bool enableDebugging;

  /// Whether to enable automatic persistence.
  final bool enablePersistence;

  /// Default storage backend for persistence.
  final String storageBackend;

  /// Whether to enable automatic disposal.
  final bool autoDispose;

  /// Maximum number of state transitions to keep in history.
  final int maxHistorySize;

  /// Creates a new state management configuration.
  const StateManagementConfig({
    this.enableDebugging = false,
    this.enablePersistence = false,
    this.storageBackend = 'shared_preferences',
    this.autoDispose = true,
    this.maxHistorySize = 100,
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    final issues = <ConfigurationIssue>[];

    if (maxHistorySize < 0) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'maxHistorySize must be non-negative',
        field: 'stateManagement.maxHistorySize',
      ));
    }

    if (enablePersistence && storageBackend.isEmpty) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'storageBackend must be specified when persistence is enabled',
        field: 'stateManagement.storageBackend',
      ));
    }

    return issues;
  }
}

/// Configuration for navigation and routing features.
class NavigationConfig {
  /// Whether to enable deep linking support.
  final bool enableDeepLinking;

  /// Whether to enable debug logging for navigation.
  final bool enableDebugLogging;

  /// Default transition animation duration.
  final Duration defaultTransitionDuration;

  /// Whether to enable route guards.
  final bool enableRouteGuards;

  /// Maximum navigation stack size.
  final int maxStackSize;

  /// Creates a new navigation configuration.
  const NavigationConfig({
    this.enableDeepLinking = true,
    this.enableDebugLogging = false,
    this.defaultTransitionDuration = const Duration(milliseconds: 300),
    this.enableRouteGuards = true,
    this.maxStackSize = 50,
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    final issues = <ConfigurationIssue>[];

    if (defaultTransitionDuration.isNegative) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'defaultTransitionDuration must be non-negative',
        field: 'navigation.defaultTransitionDuration',
      ));
    }

    if (maxStackSize <= 0) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'maxStackSize must be positive',
        field: 'navigation.maxStackSize',
      ));
    }

    return issues;
  }
}

/// Configuration for testing utilities.
class TestingConfig {
  /// Whether to enable automatic mock generation.
  final bool enableMockGeneration;

  /// Whether to enable test data factories.
  final bool enableTestDataFactories;

  /// Default timeout for async test operations.
  final Duration defaultTimeout;

  /// Whether to enable test environment isolation.
  final bool enableIsolation;

  /// Creates a new testing configuration.
  const TestingConfig({
    this.enableMockGeneration = true,
    this.enableTestDataFactories = true,
    this.defaultTimeout = const Duration(seconds: 30),
    this.enableIsolation = true,
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    final issues = <ConfigurationIssue>[];

    if (defaultTimeout.isNegative) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'defaultTimeout must be non-negative',
        field: 'testing.defaultTimeout',
      ));
    }

    return issues;
  }
}

/// Configuration for performance monitoring.
class PerformanceConfig {
  /// Whether to enable performance monitoring.
  final bool enableMonitoring;

  /// Whether to enable real-time performance warnings.
  final bool enableRealTimeWarnings;

  /// Interval for collecting performance metrics.
  final Duration metricsInterval;

  /// Performance thresholds for warnings.
  final PerformanceThresholds thresholds;

  /// Creates a new performance configuration.
  const PerformanceConfig({
    this.enableMonitoring = false,
    this.enableRealTimeWarnings = false,
    this.metricsInterval = const Duration(seconds: 1),
    this.thresholds = const PerformanceThresholds(),
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    final issues = <ConfigurationIssue>[];

    if (metricsInterval.isNegative || metricsInterval == Duration.zero) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'metricsInterval must be positive',
        field: 'performance.metricsInterval',
      ));
    }

    return issues;
  }
}

/// Configuration for code generation.
class CodeGenerationConfig {
  /// Whether to enable code generation.
  final bool enabled;

  /// Configuration for generation behavior.
  final GenerationConfiguration generationConfig;

  /// Whether to watch for file changes and regenerate automatically.
  final bool watchMode;

  /// Creates a new code generation configuration.
  const CodeGenerationConfig({
    this.enabled = true,
    this.generationConfig = const GenerationConfiguration(),
    this.watchMode = false,
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    // Code generation config is always valid for now
    return [];
  }
}

/// Configuration for development tools.
class DevelopmentToolsConfig {
  /// Whether to enable pub.dev optimization tools.
  final bool enablePubOptimization;

  /// Whether to enable real-time linting.
  final bool enableRealTimeLinting;

  /// Whether to enable asset reference generation.
  final bool enableAssetGeneration;

  /// Creates a new development tools configuration.
  const DevelopmentToolsConfig({
    this.enablePubOptimization = true,
    this.enableRealTimeLinting = true,
    this.enableAssetGeneration = true,
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    // Development tools config is always valid for now
    return [];
  }
}

/// Configuration for error reporting.
class ErrorReportingConfig {
  /// Minimum severity level for reporting.
  final ReportSeverity minimumSeverity;

  /// Whether to enable console logging.
  final bool enableConsoleLogging;

  /// Whether to enable file logging.
  final bool enableFileLogging;

  /// Log file path (if file logging is enabled).
  final String? logFilePath;

  /// Creates a new error reporting configuration.
  const ErrorReportingConfig({
    this.minimumSeverity = ReportSeverity.warning,
    this.enableConsoleLogging = true,
    this.enableFileLogging = false,
    this.logFilePath,
  });

  /// Validates this configuration.
  List<ConfigurationIssue> validate() {
    final issues = <ConfigurationIssue>[];

    if (enableFileLogging && (logFilePath == null || logFilePath!.isEmpty)) {
      issues.add(ConfigurationIssue(
        severity: ConfigurationSeverity.error,
        message: 'logFilePath must be specified when file logging is enabled',
        field: 'errorReporting.logFilePath',
      ));
    }

    return issues;
  }
}

/// Issue found during configuration validation.
class ConfigurationIssue {
  /// Severity of the issue.
  final ConfigurationSeverity severity;

  /// Description of the issue.
  final String message;

  /// Configuration field that has the issue.
  final String field;

  /// Suggested fix for the issue.
  final String? suggestion;

  /// Creates a new configuration issue.
  const ConfigurationIssue({
    required this.severity,
    required this.message,
    required this.field,
    this.suggestion,
  });

  @override
  String toString() =>
      '${severity.name.toUpperCase()}: $message (field: $field)'
      '${suggestion != null ? ' - Suggestion: $suggestion' : ''}';
}

/// Severity levels for configuration issues.
enum ConfigurationSeverity {
  /// Warning - configuration will work but may not be optimal.
  warning,

  /// Error - configuration is invalid and must be fixed.
  error,
}
