import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Enhances async stack traces with context preservation and better debugging information.
class AsyncStackTraceEnhancer {
  static bool _isEnabled = kDebugMode;
  static final Map<String, AsyncContext> _contextMap = {};
  static final List<AsyncOperation> _operationHistory = [];
  static const int _maxHistorySize = 100;

  /// Enables or disables async stack trace enhancement.
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Checks if async stack trace enhancement is enabled.
  static bool get isEnabled => _isEnabled;

  /// Wraps a Future with enhanced error tracking and context preservation.
  static Future<T> wrapFuture<T>(
    Future<T> future, {
    required String operationName,
    Map<String, dynamic>? context,
    String? category,
  }) {
    if (!_isEnabled) return future;

    final operationId = _generateOperationId();
    final asyncContext = AsyncContext(
      operationId: operationId,
      operationName: operationName,
      context: context ?? {},
      category: category ?? 'unknown',
      startTime: DateTime.now(),
      stackTrace: StackTrace.current,
    );

    _contextMap[operationId] = asyncContext;
    _addToHistory(AsyncOperation.started(asyncContext));

    return future.then<T>((result) {
      _addToHistory(AsyncOperation.completed(asyncContext, result));
      _contextMap.remove(operationId);
      return result;
    }).catchError((Object error, StackTrace stackTrace) {
      final enhancedError = _enhanceAsyncError(error, stackTrace, asyncContext);
      _addToHistory(AsyncOperation.failed(asyncContext, enhancedError));
      _contextMap.remove(operationId);
      throw enhancedError;
    });
  }

  /// Wraps a Stream with enhanced error tracking and context preservation.
  static Stream<T> wrapStream<T>(
    Stream<T> stream, {
    required String operationName,
    Map<String, dynamic>? context,
    String? category,
  }) {
    if (!_isEnabled) return stream;

    final operationId = _generateOperationId();
    final asyncContext = AsyncContext(
      operationId: operationId,
      operationName: operationName,
      context: context ?? {},
      category: category ?? 'stream',
      startTime: DateTime.now(),
      stackTrace: StackTrace.current,
    );

    _contextMap[operationId] = asyncContext;
    _addToHistory(AsyncOperation.started(asyncContext));

    return stream.handleError((Object error, StackTrace stackTrace) {
      final enhancedError = _enhanceAsyncError(error, stackTrace, asyncContext);
      _addToHistory(AsyncOperation.failed(asyncContext, enhancedError));
      throw enhancedError;
    }).doOnDone(() {
      _addToHistory(AsyncOperation.completed(asyncContext, null));
      _contextMap.remove(operationId);
    });
  }

  /// Creates an enhanced error with async context and improved stack trace.
  static EnhancedAsyncError enhanceError(
    error,
    StackTrace stackTrace, {
    String? operationName,
    Map<String, dynamic>? context,
  }) {
    if (!_isEnabled) {
      return EnhancedAsyncError(
        originalError: error,
        originalStackTrace: stackTrace,
        operationName: operationName ?? 'unknown',
        context: context ?? {},
        enhancedStackTrace: stackTrace.toString(),
        asyncChain: [],
      );
    }

    final asyncChain = _buildAsyncChain();
    final enhancedStackTrace = _enhanceStackTrace(stackTrace, asyncChain);

    return EnhancedAsyncError(
      originalError: error,
      originalStackTrace: stackTrace,
      operationName: operationName ?? 'unknown',
      context: context ?? {},
      enhancedStackTrace: enhancedStackTrace,
      asyncChain: asyncChain,
    );
  }

  /// Gets the current async operation history.
  static List<AsyncOperation> getOperationHistory() => List.unmodifiable(_operationHistory);

  /// Gets currently active async operations.
  static List<AsyncContext> getActiveOperations() => List.unmodifiable(_contextMap.values);

  /// Clears the operation history and active operations.
  static void clearHistory() {
    _operationHistory.clear();
    _contextMap.clear();
  }

  /// Logs the current async operation state for debugging.
  static void logAsyncState() {
    if (!_isEnabled) return;

    developer.log('=== Async Operations State ===');
    developer.log('Active operations: ${_contextMap.length}');
    for (final context in _contextMap.values) {
      developer.log('  ${context.operationName} (${context.operationId})');
    }
    developer.log('Recent history: ${_operationHistory.length}');
    for (final operation in _operationHistory.take(10)) {
      developer.log('  ${operation.type}: ${operation.context.operationName}');
    }
    developer.log('=============================');
  }

  static String _generateOperationId() => '${DateTime.now().millisecondsSinceEpoch}_${_contextMap.length}';

  static void _addToHistory(AsyncOperation operation) {
    _operationHistory.insert(0, operation);
    if (_operationHistory.length > _maxHistorySize) {
      _operationHistory.removeLast();
    }
  }

  static EnhancedAsyncError _enhanceAsyncError(
    error,
    StackTrace stackTrace,
    AsyncContext context,
  ) {
    final asyncChain = _buildAsyncChain();
    final enhancedStackTrace = _enhanceStackTrace(stackTrace, asyncChain);

    return EnhancedAsyncError(
      originalError: error,
      originalStackTrace: stackTrace,
      operationName: context.operationName,
      context: context.context,
      enhancedStackTrace: enhancedStackTrace,
      asyncChain: asyncChain,
      asyncContext: context,
    );
  }

  static List<AsyncContext> _buildAsyncChain() {
    // Build a chain of related async operations
    final chain = <AsyncContext>[];
    final recentOperations = _operationHistory.take(10);

    for (final operation in recentOperations) {
      if (operation.type == AsyncOperationType.started ||
          operation.type == AsyncOperationType.failed) {
        chain.add(operation.context);
      }
    }

    return chain;
  }

  static String _enhanceStackTrace(
    StackTrace stackTrace,
    List<AsyncContext> asyncChain,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Enhanced Async Stack Trace:');
    buffer.writeln('Original Stack Trace:');
    buffer.writeln(stackTrace.toString());

    if (asyncChain.isNotEmpty) {
      buffer.writeln('\nAsync Operation Chain:');
      for (var i = 0; i < asyncChain.length; i++) {
        final context = asyncChain[i];
        buffer.writeln('  $i. ${context.operationName} (${context.category})');
        buffer.writeln('     Started: ${context.startTime}');
        if (context.context.isNotEmpty) {
          buffer.writeln('     Context: ${context.context}');
        }
      }
    }

    return buffer.toString();
  }
}

/// Context information for async operations.
class AsyncContext {

  /// Creates async context.
  const AsyncContext({
    required this.operationId,
    required this.operationName,
    required this.context,
    required this.category,
    required this.startTime,
    required this.stackTrace,
  });
  /// Unique identifier for the operation.
  final String operationId;

  /// Human-readable name of the operation.
  final String operationName;

  /// Additional context data.
  final Map<String, dynamic> context;

  /// Category of the operation.
  final String category;

  /// When the operation started.
  final DateTime startTime;

  /// Stack trace when the operation was created.
  final StackTrace stackTrace;

  /// Duration since the operation started.
  Duration get duration => DateTime.now().difference(startTime);
}

/// Enhanced async error with context and improved stack trace.
class EnhancedAsyncError extends Error {

  /// Creates an enhanced async error.
  EnhancedAsyncError({
    required this.originalError,
    required this.originalStackTrace,
    required this.operationName,
    required this.context,
    required this.enhancedStackTrace,
    required this.asyncChain,
    this.asyncContext,
  });
  /// The original error that occurred.
  final dynamic originalError;

  /// The original stack trace.
  final StackTrace originalStackTrace;

  /// Name of the operation where the error occurred.
  final String operationName;

  /// Context data when the error occurred.
  final Map<String, dynamic> context;

  /// Enhanced stack trace with async context.
  final String enhancedStackTrace;

  /// Chain of async operations leading to this error.
  final List<AsyncContext> asyncChain;

  /// The async context where the error occurred.
  final AsyncContext? asyncContext;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('EnhancedAsyncError in operation: $operationName');
    buffer.writeln('Original error: $originalError');

    if (context.isNotEmpty) {
      buffer.writeln('Context: $context');
    }

    if (asyncContext != null) {
      buffer.writeln('Operation duration: ${asyncContext!.duration}');
    }

    buffer.writeln('\n$enhancedStackTrace');

    return buffer.toString();
  }

  @override
  StackTrace? get stackTrace => originalStackTrace;
}

/// Represents an async operation in the history.
class AsyncOperation {

  /// Creates an async operation record.
  const AsyncOperation({
    required this.type,
    required this.context,
    required this.timestamp,
    this.result,
    this.error,
  });

  /// Creates a started operation record.
  factory AsyncOperation.started(AsyncContext context) => AsyncOperation(
      type: AsyncOperationType.started,
      context: context,
      timestamp: DateTime.now(),
    );

  /// Creates a completed operation record.
  factory AsyncOperation.completed(AsyncContext context, result) => AsyncOperation(
      type: AsyncOperationType.completed,
      context: context,
      timestamp: DateTime.now(),
      result: result,
    );

  /// Creates a failed operation record.
  factory AsyncOperation.failed(AsyncContext context, error) => AsyncOperation(
      type: AsyncOperationType.failed,
      context: context,
      timestamp: DateTime.now(),
      error: error,
    );
  /// Type of the operation.
  final AsyncOperationType type;

  /// Context of the operation.
  final AsyncContext context;

  /// When the operation event occurred.
  final DateTime timestamp;

  /// Result of the operation (for completed operations).
  final dynamic result;

  /// Error that occurred (for failed operations).
  final dynamic error;
}

/// Types of async operation events.
enum AsyncOperationType {
  /// Operation was started.
  started,

  /// Operation completed successfully.
  completed,

  /// Operation failed with an error.
  failed,
}

/// Extension to add doOnDone functionality to streams.
extension StreamExtensions<T> on Stream<T> {
  /// Executes a callback when the stream is done.
  Stream<T> doOnDone(void Function() onDone) {
    late StreamController<T> controller;
    late StreamSubscription<T> subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            onDone();
            controller.close();
          },
        );
      },
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }
}
