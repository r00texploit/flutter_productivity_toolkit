import 'dart:async';
import 'toolkit_error.dart';

/// Abstract error reporter for handling and reporting toolkit errors.
///
/// Provides a centralized system for error reporting, logging, and
/// user notification with configurable severity levels and handlers.
abstract class ErrorReporter {
  /// Reports an error to the error handling system.
  ///
  /// The error will be processed according to its category and severity,
  /// and appropriate actions will be taken (logging, user notification, etc.).
  void reportError(ToolkitError error);

  /// Reports a warning message with optional suggestion.
  ///
  /// Warnings are less severe than errors and typically don't interrupt
  /// the user's workflow but should be brought to their attention.
  void reportWarning(String message,
      {String? suggestion, Map<String, dynamic>? context,});

  /// Reports an informational message.
  ///
  /// Info messages provide helpful information to the user but don't
  /// indicate any problems or issues.
  void reportInfo(String message, {Map<String, dynamic>? context});

  /// Stream of all errors reported to this reporter.
  ///
  /// Consumers can listen to this stream to implement custom error
  /// handling or logging behavior.
  Stream<ToolkitError> get errorStream;

  /// Stream of all warnings reported to this reporter.
  Stream<WarningReport> get warningStream;

  /// Stream of all info messages reported to this reporter.
  Stream<InfoReport> get infoStream;

  /// Sets the minimum severity level for reporting.
  ///
  /// Only errors, warnings, and info messages at or above this level
  /// will be processed and reported.
  void setMinimumSeverity(ReportSeverity severity);

  /// Adds a custom error handler.
  ///
  /// Custom handlers can implement specific behavior for different
  /// types of errors or integrate with external logging systems.
  void addErrorHandler(ErrorHandler handler);

  /// Removes a previously added error handler.
  void removeErrorHandler(ErrorHandler handler);

  /// Clears all reported errors and resets the reporter state.
  void clearErrors();

  /// Gets statistics about reported errors.
  ErrorStatistics getStatistics();
}

/// Handler interface for custom error processing.
abstract class ErrorHandler {
  /// Handles a reported error.
  ///
  /// Returns true if the error was handled and should not be processed
  /// by other handlers, false to continue processing.
  Future<bool> handleError(ToolkitError error);

  /// Handles a reported warning.
  ///
  /// Returns true if the warning was handled and should not be processed
  /// by other handlers, false to continue processing.
  Future<bool> handleWarning(WarningReport warning);

  /// Handles a reported info message.
  ///
  /// Returns true if the info was handled and should not be processed
  /// by other handlers, false to continue processing.
  Future<bool> handleInfo(InfoReport info);

  /// The priority of this handler (higher numbers = higher priority).
  int get priority => 0;

  /// Whether this handler can handle the specified error category.
  bool canHandle(ErrorCategory category) => true;
}

/// Severity levels for error reporting.
enum ReportSeverity {
  /// Debug-level information (lowest priority).
  debug,

  /// Informational messages.
  info,

  /// Warning messages.
  warning,

  /// Error messages.
  error,

  /// Critical errors (highest priority).
  critical,
}

/// Report for warning messages.
class WarningReport {

  /// Creates a new warning report.
  const WarningReport({
    required this.message,
    this.suggestion,
    this.context,
    required this.timestamp,
    this.severity = ReportSeverity.warning,
  });
  /// The warning message.
  final String message;

  /// Optional suggestion for addressing the warning.
  final String? suggestion;

  /// Additional context information.
  final Map<String, dynamic>? context;

  /// When the warning was reported.
  final DateTime timestamp;

  /// Severity level of the warning.
  final ReportSeverity severity;

  @override
  String toString() => 'Warning: $message'
      '${suggestion != null ? ' (Suggestion: $suggestion)' : ''}';
}

/// Report for informational messages.
class InfoReport {

  /// Creates a new info report.
  const InfoReport({
    required this.message,
    this.context,
    required this.timestamp,
  });
  /// The informational message.
  final String message;

  /// Additional context information.
  final Map<String, dynamic>? context;

  /// When the info was reported.
  final DateTime timestamp;

  @override
  String toString() => 'Info: $message';
}

/// Statistics about reported errors.
class ErrorStatistics {

  /// Creates new error statistics.
  const ErrorStatistics({
    required this.totalErrors,
    required this.totalWarnings,
    required this.totalInfos,
    required this.errorsByCategory,
    required this.errorsBySeverity,
    this.lastErrorTime,
    this.mostCommonCategory,
  });
  /// Total number of errors reported.
  final int totalErrors;

  /// Total number of warnings reported.
  final int totalWarnings;

  /// Total number of info messages reported.
  final int totalInfos;

  /// Errors grouped by category.
  final Map<ErrorCategory, int> errorsByCategory;

  /// Errors grouped by severity.
  final Map<ReportSeverity, int> errorsBySeverity;

  /// Most recent error timestamp.
  final DateTime? lastErrorTime;

  /// Most common error category.
  final ErrorCategory? mostCommonCategory;

  /// Total number of all reports (errors + warnings + infos).
  int get totalReports => totalErrors + totalWarnings + totalInfos;

  @override
  String toString() => 'ErrorStatistics('
      'errors: $totalErrors, '
      'warnings: $totalWarnings, '
      'infos: $totalInfos, '
      'mostCommon: $mostCommonCategory'
      ')';
}

/// Default implementation of ErrorReporter.
class DefaultErrorReporter implements ErrorReporter {
  final List<ErrorHandler> _handlers = [];
  final StreamController<ToolkitError> _errorController =
      StreamController<ToolkitError>.broadcast();
  final StreamController<WarningReport> _warningController =
      StreamController<WarningReport>.broadcast();
  final StreamController<InfoReport> _infoController =
      StreamController<InfoReport>.broadcast();

  ReportSeverity _minimumSeverity = ReportSeverity.info;
  final List<ToolkitError> _errors = [];
  final List<WarningReport> _warnings = [];
  final List<InfoReport> _infos = [];

  @override
  Stream<ToolkitError> get errorStream => _errorController.stream;

  @override
  Stream<WarningReport> get warningStream => _warningController.stream;

  @override
  Stream<InfoReport> get infoStream => _infoController.stream;

  @override
  void reportError(ToolkitError error) {
    if (_shouldReport(ReportSeverity.error)) {
      _errors.add(error);
      _errorController.add(error);
      _processWithHandlers(error);
    }
  }

  @override
  void reportWarning(String message,
      {String? suggestion, Map<String, dynamic>? context,}) {
    if (_shouldReport(ReportSeverity.warning)) {
      final warning = WarningReport(
        message: message,
        suggestion: suggestion,
        context: context,
        timestamp: DateTime.now(),
      );
      _warnings.add(warning);
      _warningController.add(warning);
      _processWarningWithHandlers(warning);
    }
  }

  @override
  void reportInfo(String message, {Map<String, dynamic>? context}) {
    if (_shouldReport(ReportSeverity.info)) {
      final info = InfoReport(
        message: message,
        context: context,
        timestamp: DateTime.now(),
      );
      _infos.add(info);
      _infoController.add(info);
      _processInfoWithHandlers(info);
    }
  }

  @override
  void setMinimumSeverity(ReportSeverity severity) {
    _minimumSeverity = severity;
  }

  @override
  void addErrorHandler(ErrorHandler handler) {
    _handlers.add(handler);
    _handlers.sort((a, b) => b.priority.compareTo(a.priority));
  }

  @override
  void removeErrorHandler(ErrorHandler handler) {
    _handlers.remove(handler);
  }

  @override
  void clearErrors() {
    _errors.clear();
    _warnings.clear();
    _infos.clear();
  }

  @override
  ErrorStatistics getStatistics() {
    final errorsByCategory = <ErrorCategory, int>{};
    final errorsBySeverity = <ReportSeverity, int>{};

    for (final error in _errors) {
      errorsByCategory[error.category] =
          (errorsByCategory[error.category] ?? 0) + 1;
      errorsBySeverity[ReportSeverity.error] =
          (errorsBySeverity[ReportSeverity.error] ?? 0) + 1;
    }

    for (final warning in _warnings) {
      errorsBySeverity[warning.severity] =
          (errorsBySeverity[warning.severity] ?? 0) + 1;
    }

    errorsBySeverity[ReportSeverity.info] = _infos.length;

    final mostCommonCategory = errorsByCategory.entries
        .fold<MapEntry<ErrorCategory, int>?>(
          null,
          (prev, entry) =>
              prev == null || entry.value > prev.value ? entry : prev,
        )
        ?.key;

    return ErrorStatistics(
      totalErrors: _errors.length,
      totalWarnings: _warnings.length,
      totalInfos: _infos.length,
      errorsByCategory: errorsByCategory,
      errorsBySeverity: errorsBySeverity,
      lastErrorTime: _errors.isNotEmpty ? DateTime.now() : null,
      mostCommonCategory: mostCommonCategory,
    );
  }

  bool _shouldReport(ReportSeverity severity) => severity.index >= _minimumSeverity.index;

  Future<void> _processWithHandlers(ToolkitError error) async {
    for (final handler in _handlers) {
      if (handler.canHandle(error.category)) {
        final handled = await handler.handleError(error);
        if (handled) break;
      }
    }
  }

  Future<void> _processWarningWithHandlers(WarningReport warning) async {
    for (final handler in _handlers) {
      final handled = await handler.handleWarning(warning);
      if (handled) break;
    }
  }

  Future<void> _processInfoWithHandlers(InfoReport info) async {
    for (final handler in _handlers) {
      final handled = await handler.handleInfo(info);
      if (handled) break;
    }
  }

  /// Disposes of the error reporter and closes all streams.
  void dispose() {
    _errorController.close();
    _warningController.close();
    _infoController.close();
  }
}
