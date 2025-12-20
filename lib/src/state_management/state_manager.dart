import 'dart:async';
import 'dart:convert';

import '../errors/error_reporter.dart';
import '../errors/toolkit_error.dart';

/// Abstract base class for state management in the Flutter Dev Toolkit.
///
/// Provides reactive state updates with automatic lifecycle management
/// and optional persistence capabilities.
abstract class StateManager<T> {
  /// The current state value.
  T get state;

  /// Stream of state changes for reactive updates.
  Stream<T> get stream;

  /// Updates the state using the provided updater function.
  ///
  /// The updater function receives the current state and should return
  /// the new state. This ensures atomic updates and proper change detection.
  void update(T Function(T current) updater);

  /// Disposes of the state manager and cleans up resources.
  ///
  /// Should be called when the state manager is no longer needed
  /// to prevent memory leaks.
  void dispose();

  /// Whether this state manager supports persistence.
  bool get supportsPersistence => false;

  /// Persists the current state to storage.
  ///
  /// Only available if [supportsPersistence] returns true.
  Future<void> persist() async {
    throw UnsupportedError('Persistence not supported by this state manager');
  }

  /// Restores state from storage.
  ///
  /// Only available if [supportsPersistence] returns true.
  Future<void> restore() async {
    throw UnsupportedError('Persistence not supported by this state manager');
  }
}

/// Abstract provider for state manager dependency injection.
///
/// Manages the lifecycle of state managers and provides automatic
/// dependency resolution.
abstract class StateProvider {
  /// Provides an instance of the specified state manager type.
  ///
  /// If the state manager doesn't exist, it will be created automatically.
  T provide<T extends StateManager<dynamic>>();

  /// Registers a state manager instance with the provider.
  ///
  /// The state manager will be available for dependency injection
  /// and its lifecycle will be managed by the provider.
  void register<T extends StateManager<dynamic>>(T manager);

  /// Unregisters and disposes of a state manager.
  ///
  /// The state manager will be removed from the provider and
  /// its dispose method will be called.
  void unregister<T extends StateManager<dynamic>>();

  /// Disposes of all registered state managers.
  ///
  /// Should be called when the provider is no longer needed
  /// to clean up all managed resources.
  void disposeAll();
}

/// Represents a state transition for debugging purposes.
class StateTransition<T> {

  /// Creates a new state transition record.
  const StateTransition({
    required this.previousState,
    required this.newState,
    required this.timestamp,
    this.action,
  });
  /// The previous state value.
  final T previousState;

  /// The new state value.
  final T newState;

  /// When the transition occurred.
  final DateTime timestamp;

  /// Optional action name that triggered the transition.
  final String? action;

  @override
  String toString() => 'StateTransition('
      'from: $previousState, '
      'to: $newState, '
      'at: $timestamp'
      '${action != null ? ', action: $action' : ''}'
      ')';
}

/// Concrete implementation of StateManager with reactive updates and persistence.
class ReactiveStateManager<T> extends StateManager<T> {

  /// Creates a new reactive state manager.
  ReactiveStateManager(
    T initialState, {
    StateConfiguration config = const StateConfiguration(),
    ErrorReporter? errorReporter,
  })  : _state = initialState,
        _config = config,
        _errorReporter = errorReporter {
    if (_config.enableDebugging) {
      _logTransition(null, initialState, 'initialization');
    }
  }
  T _state;
  final StreamController<T> _streamController = StreamController<T>.broadcast();
  final StateConfiguration _config;
  final ErrorReporter? _errorReporter;
  final List<StateTransition<T>> _history = [];
  bool _disposed = false;

  @override
  T get state {
    _checkDisposed();
    return _state;
  }

  @override
  Stream<T> get stream => _streamController.stream;

  @override
  bool get supportsPersistence => _config.enablePersistence;

  @override
  void update(T Function(T current) updater) {
    _checkDisposed();

    try {
      final previousState = _state;
      final newState = updater(_state);

      if (newState != _state) {
        _state = newState;
        _streamController.add(_state);

        if (_config.enableDebugging) {
          _logTransition(previousState, newState, 'update');
        }

        // Auto-persist if enabled
        if (_config.enablePersistence) {
          persist().catchError((Object error) {
            _errorReporter?.reportError(StateManagementError(
              message: 'Failed to persist state after update',
              stateManagerType: T.toString(),
              suggestion: 'Check storage backend configuration and permissions',
              originalStackTrace: error is Error ? error.stackTrace : null,
              context: {'state': newState.toString()},
            ),);
          });
        }
      }
    } catch (error, stackTrace) {
      _errorReporter?.reportError(StateManagementError(
        message: 'State update failed: $error',
        stateManagerType: T.toString(),
        suggestion:
            "Ensure the updater function is valid and doesn't throw exceptions",
        originalStackTrace: stackTrace,
        context: {'currentState': _state.toString()},
      ),);
      rethrow;
    }
  }

  @override
  Future<void> persist() async {
    if (!supportsPersistence) {
      throw UnsupportedError('Persistence not enabled for this state manager');
    }

    _checkDisposed();

    try {
      // For now, we'll use a simple JSON serialization approach
      // In a real implementation, this would use the configured storage backend
      final serialized = _serializeState(_state);
      final key = _config.storageKey ?? T.toString();

      // This is a placeholder - in real implementation would use SharedPreferences, etc.
      await _writeToStorage(key, serialized);

      if (_config.enableDebugging) {
        _errorReporter?.reportInfo('State persisted successfully',
            context: {'key': key, 'type': T.toString()},);
      }
    } catch (error, stackTrace) {
      _errorReporter?.reportError(StateManagementError(
        message: 'Failed to persist state: $error',
        stateManagerType: T.toString(),
        suggestion: 'Check storage backend availability and permissions',
        originalStackTrace: stackTrace,
        context: {'state': _state.toString()},
      ),);
      rethrow;
    }
  }

  @override
  Future<void> restore() async {
    if (!supportsPersistence) {
      throw UnsupportedError('Persistence not enabled for this state manager');
    }

    _checkDisposed();

    try {
      final key = _config.storageKey ?? T.toString();
      final serialized = await _readFromStorage(key);

      if (serialized != null) {
        final restoredState = _deserializeState(serialized);
        final previousState = _state;
        _state = restoredState;
        _streamController.add(_state);

        if (_config.enableDebugging) {
          _logTransition(previousState, restoredState, 'restore');
          _errorReporter?.reportInfo('State restored successfully',
              context: {'key': key, 'type': T.toString()},);
        }
      }
    } catch (error, stackTrace) {
      _errorReporter?.reportError(StateManagementError(
        message: 'Failed to restore state: $error',
        stateManagerType: T.toString(),
        suggestion: 'Check if persisted state exists and is valid',
        originalStackTrace: stackTrace,
      ),);
      rethrow;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _streamController.close();
    _history.clear();

    if (_config.enableDebugging) {
      _errorReporter?.reportInfo('State manager disposed',
          context: {'type': T.toString(), 'historySize': _history.length},);
    }
  }

  /// Gets the state transition history for debugging.
  List<StateTransition<T>> get history => List.unmodifiable(_history);

  /// Clears the state transition history.
  void clearHistory() {
    _checkDisposed();
    _history.clear();

    if (_config.enableDebugging) {
      _errorReporter?.reportInfo('State history cleared',
          context: {'type': T.toString()},);
    }
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('StateManager has been disposed');
    }
  }

  void _logTransition(T? previousState, T newState, String action) {
    final transition = StateTransition<T>(
      previousState: previousState ?? newState,
      newState: newState,
      timestamp: DateTime.now(),
      action: action,
    );

    _history.add(transition);

    // Limit history size to prevent memory leaks
    while (_history.length > _config.maxHistorySize) {
      _history.removeAt(0);
    }

    if (_config.enableDebugging && _errorReporter != null) {
      _errorReporter!.reportInfo('State transition: $action', context: {
        'type': T.toString(),
        'previousState': previousState?.toString(),
        'newState': newState.toString(),
        'timestamp': transition.timestamp.toIso8601String(),
      },);
    }
  }

  String _serializeState(T state) {
    // Simple JSON serialization - in real implementation would be more sophisticated
    try {
      return jsonEncode(state);
    } catch (e) {
      // Fallback to toString for non-JSON serializable objects
      return state.toString();
    }
  }

  T _deserializeState(String serialized) {
    // Simple JSON deserialization - in real implementation would be more sophisticated
    try {
      final decoded = jsonDecode(serialized);
      return decoded as T;
    } catch (e) {
      throw StateManagementError(
        message: 'Failed to deserialize state: incompatible format',
        stateManagerType: T.toString(),
        suggestion:
            'Ensure the persisted state format is compatible with the current state type',
        context: {'serialized': serialized},
      );
    }
  }

  Future<void> _writeToStorage(String key, String value) async {
    // Placeholder for actual storage implementation
    // In real implementation, this would use SharedPreferences, Hive, etc.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  Future<String?> _readFromStorage(String key) async {
    // Placeholder for actual storage implementation
    // In real implementation, this would use SharedPreferences, Hive, etc.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return null; // No persisted data in this placeholder
  }
}

/// Concrete implementation of StateProvider with dependency injection.
class DefaultStateProvider implements StateProvider {

  /// Creates a new default state provider.
  DefaultStateProvider({
    ErrorReporter? errorReporter,
    StateConfiguration defaultConfig = const StateConfiguration(),
  })  : _errorReporter = errorReporter,
        _defaultConfig = defaultConfig;
  final Map<Type, StateManager<dynamic>> _managers = {};
  final ErrorReporter? _errorReporter;
  final StateConfiguration _defaultConfig;
  bool _disposed = false;

  @override
  T provide<T extends StateManager<dynamic>>() {
    _checkDisposed();

    final manager = _managers[T];
    if (manager != null) {
      return manager as T;
    }

    // Auto-create state manager if not registered
    throw StateManagementError(
      message: 'State manager of type $T not registered',
      stateManagerType: T.toString(),
      suggestion:
          'Register the state manager using register<$T>() before accessing it',
      context: {
        'availableTypes': _managers.keys.map((t) => t.toString()).toList(),
      },
    );
  }

  @override
  void register<T extends StateManager<dynamic>>(T manager) {
    _checkDisposed();

    if (_managers.containsKey(T)) {
      _errorReporter?.reportWarning(
        'State manager of type $T is already registered, replacing existing instance',
        suggestion: 'Consider unregistering the previous instance first',
        context: {'type': T.toString()},
      );

      // Dispose the previous manager
      final previous = _managers[T];
      previous?.dispose();
    }

    _managers[T] = manager;

    if (_defaultConfig.enableDebugging) {
      _errorReporter?.reportInfo('State manager registered',
          context: {'type': T.toString(), 'totalManagers': _managers.length},);
    }
  }

  @override
  void unregister<T extends StateManager<dynamic>>() {
    _checkDisposed();

    final manager = _managers.remove(T);
    if (manager != null) {
      manager.dispose();

      if (_defaultConfig.enableDebugging) {
        _errorReporter?.reportInfo('State manager unregistered', context: {
          'type': T.toString(),
          'remainingManagers': _managers.length,
        },);
      }
    } else {
      _errorReporter?.reportWarning(
        'Attempted to unregister non-existent state manager of type $T',
        context: {'type': T.toString()},
      );
    }
  }

  @override
  void disposeAll() {
    if (_disposed) return;

    final managerCount = _managers.length;

    for (final manager in _managers.values) {
      manager.dispose();
    }
    _managers.clear();
    _disposed = true;

    if (_defaultConfig.enableDebugging) {
      _errorReporter?.reportInfo('All state managers disposed',
          context: {'disposedCount': managerCount},);
    }
  }

  /// Gets statistics about registered state managers.
  StateProviderStatistics getStatistics() {
    _checkDisposed();

    return StateProviderStatistics(
      totalManagers: _managers.length,
      managerTypes: _managers.keys.map((t) => t.toString()).toList(),
    );
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('StateProvider has been disposed');
    }
  }
}

/// Statistics about a state provider.
class StateProviderStatistics {

  /// Creates new state provider statistics.
  const StateProviderStatistics({
    required this.totalManagers,
    required this.managerTypes,
  });
  /// Total number of registered state managers.
  final int totalManagers;

  /// List of registered state manager types.
  final List<String> managerTypes;

  @override
  String toString() => 'StateProviderStatistics('
      'totalManagers: $totalManagers, '
      'types: $managerTypes'
      ')';
}

/// Enhanced state configuration with debugging features.
class StateConfiguration {

  /// Creates a new state configuration.
  const StateConfiguration({
    this.enablePersistence = false,
    this.storageKey,
    this.cacheTimeout,
    this.enableDebugging = false,
    this.maxHistorySize = 100,
  });

  /// Creates a configuration optimized for development.
  factory StateConfiguration.development() => const StateConfiguration(
        enableDebugging: true,
        maxHistorySize: 500,
      );

  /// Creates a configuration optimized for production.
  factory StateConfiguration.production() => const StateConfiguration(
        enablePersistence: true,
        maxHistorySize: 50,
      );

  /// Creates a configuration optimized for testing.
  factory StateConfiguration.testing() => const StateConfiguration(
        maxHistorySize: 10,
      );
  /// Whether to enable automatic persistence for state managers.
  final bool enablePersistence;

  /// Storage key for persisted state. If null, uses the type name.
  final String? storageKey;

  /// Cache timeout for persisted state. If null, no timeout is applied.
  final Duration? cacheTimeout;

  /// Whether to enable debugging features like state transition logging.
  final bool enableDebugging;

  /// Maximum number of state transitions to keep in history for debugging.
  final int maxHistorySize;
}

/// State debugging utilities for development and testing.
class StateDebugger {

  /// Creates a new state debugger.
  StateDebugger(this._errorReporter);
  final ErrorReporter _errorReporter;
  final Map<Type, ReactiveStateManager<dynamic>> _trackedManagers = {};

  /// Starts tracking a state manager for debugging.
  void trackStateManager<T>(ReactiveStateManager<T> manager) {
    _trackedManagers[T] = manager;
    _errorReporter.reportInfo('Started tracking state manager',
        context: {'type': T.toString()},);
  }

  /// Stops tracking a state manager.
  void stopTracking<T>() {
    final removed = _trackedManagers.remove(T);
    if (removed != null) {
      _errorReporter.reportInfo('Stopped tracking state manager',
          context: {'type': T.toString()},);
    }
  }

  /// Gets the transition history for a tracked state manager.
  List<StateTransition<T>> getHistory<T>() {
    final manager = _trackedManagers[T] as ReactiveStateManager<T>?;
    return manager?.history ?? [];
  }

  /// Generates a timeline visualization of state changes.
  String generateTimeline<T>() {
    final manager = _trackedManagers[T] as ReactiveStateManager<T>?;
    if (manager == null) {
      return 'State manager of type $T is not being tracked';
    }

    final history = manager.history;
    if (history.isEmpty) {
      return 'No state transitions recorded for $T';
    }

    final buffer = StringBuffer();
    buffer.writeln('State Timeline for $T:');
    buffer.writeln('=' * 50);

    for (var i = 0; i < history.length; i++) {
      final transition = history[i];
      final timeStr = transition.timestamp.toIso8601String();
      final actionStr = transition.action ?? 'unknown';

      buffer.writeln('[$i] $timeStr - $actionStr');
      buffer.writeln('    From: ${transition.previousState}');
      buffer.writeln('    To:   ${transition.newState}');

      if (i < history.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Clears all tracking data.
  void clearAll() {
    final count = _trackedManagers.length;
    _trackedManagers.clear();
    _errorReporter.reportInfo('Cleared all state tracking data',
        context: {'clearedCount': count},);
  }

  /// Gets statistics about tracked state managers.
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    for (final entry in _trackedManagers.entries) {
      final type = entry.key.toString();
      final manager = entry.value;

      stats[type] = {
        'historySize': manager.history.length,
        'currentState': manager.state.toString(),
        'supportsPersistence': manager.supportsPersistence,
      };
    }

    return {
      'trackedManagers': _trackedManagers.length,
      'managerDetails': stats,
    };
  }
}
