/// Base class for all Flutter Dev Toolkit errors.
///
/// Provides structured error information with context and suggestions
/// for resolving issues.
class ToolkitError extends Error {

  /// Creates a new toolkit error.
  ToolkitError({
    required this.category,
    required this.message,
    this.suggestion,
    this.originalStackTrace,
    this.context,
    this.errorCode,
  });
  /// The category of error that occurred.
  final ErrorCategory category;

  /// Human-readable error message.
  final String message;

  /// Specific suggestion for resolving the error.
  final String? suggestion;

  /// Original stack trace if this error wraps another error.
  final StackTrace? originalStackTrace;

  /// Additional context information about the error.
  final Map<String, dynamic>? context;

  /// Error code for programmatic handling.
  final String? errorCode;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ToolkitError: $message');

    if (errorCode != null) {
      buffer.writeln('Error Code: $errorCode');
    }

    if (suggestion != null) {
      buffer.writeln('Suggestion: $suggestion');
    }

    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context: $context');
    }

    return buffer.toString();
  }
}

/// Categories of errors that can occur in the toolkit.
enum ErrorCategory {
  /// Configuration-related errors.
  configuration,

  /// State management errors.
  stateManagement,

  /// Navigation and routing errors.
  navigation,

  /// Testing framework errors.
  testing,

  /// Performance monitoring errors.
  performance,

  /// Code generation errors.
  codeGeneration,

  /// Development tools errors.
  developmentTools,

  /// File system or I/O errors.
  fileSystem,

  /// Network or connectivity errors.
  network,

  /// Validation or data integrity errors.
  validation,

  /// Unknown or unexpected errors.
  unknown,
}

/// Specific error types for state management.
class StateManagementError extends ToolkitError {

  /// Creates a new state management error.
  StateManagementError({
    required super.message,
    this.stateManagerType,
    super.suggestion,
    super.originalStackTrace,
    super.context,
    super.errorCode,
  }) : super(
          category: ErrorCategory.stateManagement,
        );
  /// The state manager that caused the error.
  final String? stateManagerType;
}

/// Specific error types for navigation.
class NavigationError extends ToolkitError {

  /// Creates a new navigation error.
  NavigationError({
    required super.message,
    this.routePath,
    this.operation,
    super.suggestion,
    super.originalStackTrace,
    super.context,
    super.errorCode,
  }) : super(
          category: ErrorCategory.navigation,
        );
  /// The route that caused the error.
  final String? routePath;

  /// The navigation operation that failed.
  final String? operation;
}

/// Specific error types for code generation.
class CodeGenerationError extends ToolkitError {

  /// Creates a new code generation error.
  CodeGenerationError({
    required super.message,
    this.sourceFile,
    this.lineNumber,
    this.annotation,
    super.suggestion,
    super.originalStackTrace,
    super.context,
    super.errorCode,
  }) : super(
          category: ErrorCategory.codeGeneration,
        );
  /// The source file that caused the error.
  final String? sourceFile;

  /// The line number where the error occurred.
  final int? lineNumber;

  /// The annotation that caused the error.
  final String? annotation;
}

/// Specific error types for testing.
class TestingError extends ToolkitError {

  /// Creates a new testing error.
  TestingError({
    required super.message,
    this.testName,
    this.component,
    super.suggestion,
    super.originalStackTrace,
    super.context,
    super.errorCode,
  }) : super(
          category: ErrorCategory.testing,
        );
  /// The test that caused the error.
  final String? testName;

  /// The testing component that failed.
  final String? component;
}

/// Specific error types for performance monitoring.
class PerformanceError extends ToolkitError {

  /// Creates a new performance error.
  PerformanceError({
    required super.message,
    this.component,
    this.metric,
    super.suggestion,
    super.originalStackTrace,
    super.context,
    super.errorCode,
  }) : super(
          category: ErrorCategory.performance,
        );
  /// The performance component that failed.
  final String? component;

  /// The metric that caused the error.
  final String? metric;
}

/// Specific error types for configuration issues.
class ConfigurationError extends ToolkitError {

  /// Creates a new configuration error.
  ConfigurationError({
    required super.message,
    this.configurationKey,
    this.configurationFile,
    super.suggestion,
    super.originalStackTrace,
    super.context,
    super.errorCode,
  }) : super(
          category: ErrorCategory.configuration,
        );
  /// The configuration key that caused the error.
  final String? configurationKey;

  /// The configuration file that has the issue.
  final String? configurationFile;
}
