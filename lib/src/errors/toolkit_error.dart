/// Base class for all Flutter Dev Toolkit errors.
///
/// Provides structured error information with context and suggestions
/// for resolving issues.
class ToolkitError extends Error {
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

  /// Creates a new toolkit error.
  ToolkitError({
    required this.category,
    required this.message,
    this.suggestion,
    this.originalStackTrace,
    this.context,
    this.errorCode,
  });

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
  /// The state manager that caused the error.
  final String? stateManagerType;

  /// Creates a new state management error.
  StateManagementError({
    required String message,
    this.stateManagerType,
    String? suggestion,
    StackTrace? originalStackTrace,
    Map<String, dynamic>? context,
    String? errorCode,
  }) : super(
          category: ErrorCategory.stateManagement,
          message: message,
          suggestion: suggestion,
          originalStackTrace: originalStackTrace,
          context: context,
          errorCode: errorCode,
        );
}

/// Specific error types for navigation.
class NavigationError extends ToolkitError {
  /// The route that caused the error.
  final String? routePath;

  /// The navigation operation that failed.
  final String? operation;

  /// Creates a new navigation error.
  NavigationError({
    required String message,
    this.routePath,
    this.operation,
    String? suggestion,
    StackTrace? originalStackTrace,
    Map<String, dynamic>? context,
    String? errorCode,
  }) : super(
          category: ErrorCategory.navigation,
          message: message,
          suggestion: suggestion,
          originalStackTrace: originalStackTrace,
          context: context,
          errorCode: errorCode,
        );
}

/// Specific error types for code generation.
class CodeGenerationError extends ToolkitError {
  /// The source file that caused the error.
  final String? sourceFile;

  /// The line number where the error occurred.
  final int? lineNumber;

  /// The annotation that caused the error.
  final String? annotation;

  /// Creates a new code generation error.
  CodeGenerationError({
    required String message,
    this.sourceFile,
    this.lineNumber,
    this.annotation,
    String? suggestion,
    StackTrace? originalStackTrace,
    Map<String, dynamic>? context,
    String? errorCode,
  }) : super(
          category: ErrorCategory.codeGeneration,
          message: message,
          suggestion: suggestion,
          originalStackTrace: originalStackTrace,
          context: context,
          errorCode: errorCode,
        );
}

/// Specific error types for testing.
class TestingError extends ToolkitError {
  /// The test that caused the error.
  final String? testName;

  /// The testing component that failed.
  final String? component;

  /// Creates a new testing error.
  TestingError({
    required String message,
    this.testName,
    this.component,
    String? suggestion,
    StackTrace? originalStackTrace,
    Map<String, dynamic>? context,
    String? errorCode,
  }) : super(
          category: ErrorCategory.testing,
          message: message,
          suggestion: suggestion,
          originalStackTrace: originalStackTrace,
          context: context,
          errorCode: errorCode,
        );
}

/// Specific error types for performance monitoring.
class PerformanceError extends ToolkitError {
  /// The performance component that failed.
  final String? component;

  /// The metric that caused the error.
  final String? metric;

  /// Creates a new performance error.
  PerformanceError({
    required String message,
    this.component,
    this.metric,
    String? suggestion,
    StackTrace? originalStackTrace,
    Map<String, dynamic>? context,
    String? errorCode,
  }) : super(
          category: ErrorCategory.performance,
          message: message,
          suggestion: suggestion,
          originalStackTrace: originalStackTrace,
          context: context,
          errorCode: errorCode,
        );
}

/// Specific error types for configuration issues.
class ConfigurationError extends ToolkitError {
  /// The configuration key that caused the error.
  final String? configurationKey;

  /// The configuration file that has the issue.
  final String? configurationFile;

  /// Creates a new configuration error.
  ConfigurationError({
    required String message,
    this.configurationKey,
    this.configurationFile,
    String? suggestion,
    StackTrace? originalStackTrace,
    Map<String, dynamic>? context,
    String? errorCode,
  }) : super(
          category: ErrorCategory.configuration,
          message: message,
          suggestion: suggestion,
          originalStackTrace: originalStackTrace,
          context: context,
          errorCode: errorCode,
        );
}
