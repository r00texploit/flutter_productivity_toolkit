import 'dart:async';

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
  T provide<T extends StateManager>();

  /// Registers a state manager instance with the provider.
  ///
  /// The state manager will be available for dependency injection
  /// and its lifecycle will be managed by the provider.
  void register<T extends StateManager>(T manager);

  /// Unregisters and disposes of a state manager.
  ///
  /// The state manager will be removed from the provider and
  /// its dispose method will be called.
  void unregister<T extends StateManager>();

  /// Disposes of all registered state managers.
  ///
  /// Should be called when the provider is no longer needed
  /// to clean up all managed resources.
  void disposeAll();
}

/// Configuration for state management behavior.
class StateConfiguration {
  /// Whether to enable automatic persistence for state managers.
  final bool enablePersistence;

  /// Storage key for persisted state. If null, uses the type name.
  final String? storageKey;

  /// Cache timeout for persisted state. If null, no timeout is applied.
  final Duration? cacheTimeout;

  /// Whether to enable debugging features like state transition logging.
  final bool enableDebugging;

  /// Creates a new state configuration.
  const StateConfiguration({
    this.enablePersistence = false,
    this.storageKey,
    this.cacheTimeout,
    this.enableDebugging = false,
  });
}

/// Represents a state transition for debugging purposes.
class StateTransition<T> {
  /// The previous state value.
  final T previousState;

  /// The new state value.
  final T newState;

  /// When the transition occurred.
  final DateTime timestamp;

  /// Optional action name that triggered the transition.
  final String? action;

  /// Creates a new state transition record.
  const StateTransition({
    required this.previousState,
    required this.newState,
    required this.timestamp,
    this.action,
  });

  @override
  String toString() =>
      'StateTransition('
      'from: $previousState, '
      'to: $newState, '
      'at: $timestamp'
      '${action != null ? ', action: $action' : ''}'
      ')';
}
