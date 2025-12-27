import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'async_stack_trace_enhancer.dart';
import 'enhanced_error_handler.dart';
import 'error_reporter.dart';
import 'platform_issue_detector.dart';
import 'toolkit_error.dart';
import 'widget_debugger.dart';

/// Integrated debugging system that combines all error handling and debugging tools.
class IntegratedDebuggingSystem {
  /// Private constructor for singleton pattern.
  IntegratedDebuggingSystem._({
    ErrorReporter? errorReporter,
  })  : _errorReporter = errorReporter ?? DefaultErrorReporter(),
        _enhancedErrorHandler = const EnhancedErrorHandler(),
        _debugEventController = StreamController<DebugEvent>.broadcast();
  static IntegratedDebuggingSystem? _instance;
  static bool _isInitialized = false;

  final ErrorReporter _errorReporter;
  final EnhancedErrorHandler _enhancedErrorHandler;
  final StreamController<DebugEvent> _debugEventController;

  /// Gets the singleton instance of the debugging system.
  static IntegratedDebuggingSystem get instance {
    _instance ??= IntegratedDebuggingSystem._();
    return _instance!;
  }

  /// Initializes the integrated debugging system.
  static Future<void> initialize({
    ErrorReporter? customErrorReporter,
    bool enableWidgetDebugging = true,
    bool enableAsyncTracing = true,
    bool enablePlatformDetection = true,
  }) async {
    if (_isInitialized) return;

    final system = IntegratedDebuggingSystem._(
      errorReporter: customErrorReporter,
    );
    _instance = system;

    // Configure subsystems
    WidgetDebugger.setEnabled(enableWidgetDebugging);
    AsyncStackTraceEnhancer.setEnabled(enableAsyncTracing);
    PlatformIssueDetector.setEnabled(enablePlatformDetection);

    // Set up error handling
    system._errorReporter.addErrorHandler(system._enhancedErrorHandler);

    // Set up Flutter error handling
    if (kDebugMode) {
      FlutterError.onError = system._handleFlutterError;
      PlatformDispatcher.instance.onError = system._handlePlatformError;
    }

    _isInitialized = true;

    system._reportDebugEvent(
      DebugEvent.systemInitialized(
        'Integrated debugging system initialized successfully',
      ),
    );
  }

  /// Stream of debug events from the system.
  Stream<DebugEvent> get debugEvents => _debugEventController.stream;

  /// Reports an error through the integrated system.
  void reportError(
    Object error, {
    StackTrace? stackTrace,
    ErrorCategory? category,
    Map<String, dynamic>? context,
    String? operationName,
  }) {
    final enhancedStackTrace = stackTrace ?? StackTrace.current;

    // Create enhanced async error if we have operation context
    final enhancedError = operationName != null
        ? AsyncStackTraceEnhancer.enhanceError(
            error,
            enhancedStackTrace,
            operationName: operationName,
            context: context,
          )
        : error;

    // Create toolkit error
    final toolkitError = _createToolkitError(
      enhancedError,
      enhancedStackTrace,
      category,
      context,
    );

    // Detect platform-specific issues
    final platformIssues = PlatformIssueDetector.analyzeError(
      error,
      enhancedStackTrace,
      category: category,
    );

    // Report through error reporter
    _errorReporter.reportError(toolkitError);

    // Report debug event
    _reportDebugEvent(
      DebugEvent.errorReported(
        toolkitError,
        platformIssues: platformIssues,
      ),
    );
  }

  /// Analyzes a widget for debugging information.
  WidgetAnalysisResult analyzeWidget(Widget widget) {
    final inspectionData = WidgetDebugger.inspectWidget(widget);
    final issues = WidgetDebugger.analyzeWidgetTree(widget);
    final performanceIssues = WidgetDebugger.findPerformanceIssues(widget);

    final result = WidgetAnalysisResult(
      inspectionData: inspectionData,
      issues: issues,
      performanceIssues: performanceIssues,
      timestamp: DateTime.now(),
    );

    _reportDebugEvent(DebugEvent.widgetAnalyzed(widget, result));

    return result;
  }

  /// Wraps a Future with enhanced debugging capabilities.
  Future<T> wrapFuture<T>(
    Future<T> future, {
    required String operationName,
    Map<String, dynamic>? context,
    String? category,
  }) =>
      AsyncStackTraceEnhancer.wrapFuture(
        future,
        operationName: operationName,
        context: context,
        category: category,
      ).catchError((Object error, StackTrace stackTrace) {
        reportError(
          error,
          stackTrace: stackTrace,
          context: context,
          operationName: operationName,
        );
        Error.throwWithStackTrace(error, stackTrace);
      });

  /// Wraps a Stream with enhanced debugging capabilities.
  Stream<T> wrapStream<T>(
    Stream<T> stream, {
    required String operationName,
    Map<String, dynamic>? context,
    String? category,
  }) =>
      AsyncStackTraceEnhancer.wrapStream(
        stream,
        operationName: operationName,
        context: context,
        category: category,
      ).handleError((Object error, StackTrace stackTrace) {
        reportError(
          error,
          stackTrace: stackTrace,
          context: context,
          operationName: operationName,
        );
      });

  /// Creates a debug overlay widget for visual debugging.
  Widget createDebugOverlay(Widget child) =>
      WidgetDebugger.createDebugOverlay(child);

  /// Gets comprehensive system diagnostics.
  SystemDiagnostics getSystemDiagnostics() => SystemDiagnostics(
        platformInfo: PlatformIssueDetector.getCurrentPlatformInfo(),
        platformRecommendations:
            PlatformIssueDetector.getPlatformRecommendations(),
        configurationIssues: PlatformIssueDetector.checkPlatformConfiguration(),
        activeAsyncOperations: AsyncStackTraceEnhancer.getActiveOperations(),
        asyncOperationHistory: AsyncStackTraceEnhancer.getOperationHistory(),
        errorStatistics: _errorReporter.getStatistics(),
        timestamp: DateTime.now(),
      );

  /// Captures a comprehensive debugging snapshot.
  DebuggingSnapshot captureSnapshot(BuildContext? context) => DebuggingSnapshot(
        timestamp: DateTime.now(),
        systemDiagnostics: getSystemDiagnostics(),
        widgetSnapshot:
            context != null ? WidgetDebugger.captureSnapshot(context) : null,
        asyncState: AsyncStackTraceEnhancer.getActiveOperations(),
      );

  /// Clears all debugging history and caches.
  void clearDebuggingData() {
    AsyncStackTraceEnhancer.clearHistory();
    _errorReporter.clearErrors();

    _reportDebugEvent(
      DebugEvent.dataCleared(
        'All debugging data has been cleared',
      ),
    );
  }

  /// Disposes of the debugging system.
  void dispose() {
    _debugEventController.close();
    if (_errorReporter is DefaultErrorReporter) {
      (_errorReporter as DefaultErrorReporter).dispose();
    }
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    reportError(
      details.exception,
      stackTrace: details.stack,
      category: ErrorCategory.unknown,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    // Call the default error handler as well
    FlutterError.presentError(details);
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    reportError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.unknown,
    );
    return true; // Indicates the error was handled
  }

  ToolkitError _createToolkitError(
    Object error,
    StackTrace stackTrace,
    ErrorCategory? category,
    Map<String, dynamic>? context,
  ) {
    if (error is ToolkitError) {
      return error;
    }

    return ToolkitError(
      category: category ?? ErrorCategory.unknown,
      message: error.toString(),
      originalStackTrace: stackTrace,
      context: context,
    );
  }

  void _reportDebugEvent(DebugEvent event) {
    if (!_debugEventController.isClosed) {
      _debugEventController.add(event);
    }
  }
}

/// Result of widget analysis.
class WidgetAnalysisResult {
  /// Creates a widget analysis result.
  const WidgetAnalysisResult({
    required this.inspectionData,
    required this.issues,
    required this.performanceIssues,
    required this.timestamp,
  });

  /// Widget inspection data.
  final WidgetInspectionData inspectionData;

  /// Issues found in the widget tree.
  final List<WidgetIssue> issues;

  /// Performance issues found.
  final List<PerformanceIssue> performanceIssues;

  /// When the analysis was performed.
  final DateTime timestamp;

  /// Gets the total number of issues found.
  int get totalIssues => issues.length + performanceIssues.length;

  /// Gets issues by severity.
  Map<IssueSeverity, int> get issuesBySeverity {
    final map = <IssueSeverity, int>{};
    for (final issue in issues) {
      map[issue.severity] = (map[issue.severity] ?? 0) + 1;
    }
    return map;
  }
}

/// Comprehensive system diagnostics.
class SystemDiagnostics {
  /// Creates system diagnostics.
  const SystemDiagnostics({
    required this.platformInfo,
    required this.platformRecommendations,
    required this.configurationIssues,
    required this.activeAsyncOperations,
    required this.asyncOperationHistory,
    required this.errorStatistics,
    required this.timestamp,
  });

  /// Platform information.
  final PlatformInfo platformInfo;

  /// Platform-specific recommendations.
  final List<PlatformRecommendation> platformRecommendations;

  /// Configuration issues found.
  final List<ConfigurationIssue> configurationIssues;

  /// Currently active async operations.
  final List<AsyncContext> activeAsyncOperations;

  /// History of async operations.
  final List<AsyncOperation> asyncOperationHistory;

  /// Error reporting statistics.
  final ErrorStatistics errorStatistics;

  /// When the diagnostics were captured.
  final DateTime timestamp;
}

/// Comprehensive debugging snapshot.
class DebuggingSnapshot {
  /// Creates a debugging snapshot.
  const DebuggingSnapshot({
    required this.timestamp,
    required this.systemDiagnostics,
    this.widgetSnapshot,
    required this.asyncState,
  });

  /// When the snapshot was taken.
  final DateTime timestamp;

  /// System diagnostics at snapshot time.
  final SystemDiagnostics systemDiagnostics;

  /// Widget snapshot, if available.
  final WidgetSnapshot? widgetSnapshot;

  /// Async operation state at snapshot time.
  final List<AsyncContext> asyncState;
}

/// Debug events emitted by the system.
class DebugEvent {
  /// Creates a debug event.
  const DebugEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.data = const {},
  });

  /// Creates a system initialized event.
  factory DebugEvent.systemInitialized(String message) => DebugEvent(
        type: DebugEventType.systemInitialized,
        message: message,
        timestamp: DateTime.now(),
      );

  /// Creates an error reported event.
  factory DebugEvent.errorReported(
    ToolkitError error, {
    List<PlatformIssue>? platformIssues,
  }) =>
      DebugEvent(
        type: DebugEventType.errorReported,
        message: 'Error reported: ${error.message}',
        timestamp: DateTime.now(),
        data: {
          'error': error,
          'platformIssues': platformIssues ?? [],
        },
      );

  /// Creates a widget analyzed event.
  factory DebugEvent.widgetAnalyzed(
    Widget widget,
    WidgetAnalysisResult result,
  ) =>
      DebugEvent(
        type: DebugEventType.widgetAnalyzed,
        message: 'Widget analyzed: ${widget.runtimeType}',
        timestamp: DateTime.now(),
        data: {
          'widget': widget.runtimeType.toString(),
          'result': result,
        },
      );

  /// Creates a data cleared event.
  factory DebugEvent.dataCleared(String message) => DebugEvent(
        type: DebugEventType.dataCleared,
        message: message,
        timestamp: DateTime.now(),
      );

  /// Type of the debug event.
  final DebugEventType type;

  /// Event message.
  final String message;

  /// When the event occurred.
  final DateTime timestamp;

  /// Additional event data.
  final Map<String, dynamic> data;
}

/// Types of debug events.
enum DebugEventType {
  /// System was initialized.
  systemInitialized,

  /// An error was reported.
  errorReported,

  /// A widget was analyzed.
  widgetAnalyzed,

  /// Debugging data was cleared.
  dataCleared,

  /// An async operation started.
  asyncOperationStarted,

  /// An async operation completed.
  asyncOperationCompleted,

  /// An async operation failed.
  asyncOperationFailed,
}
