import 'dart:async';

import '../state_management/state_manager.dart';

/// Comprehensive testing utilities for Flutter applications.
///
/// Provides simplified test setup, mock generation, and integration
/// test helpers with minimal configuration required.
abstract class TestHelper {
  /// Wraps a widget with common test providers and dependencies.
  ///
  /// Automatically sets up MaterialApp, theme, and other common
  /// dependencies needed for widget testing.
  dynamic wrapWithProviders(
    dynamic child, {
    List<Provider>? providers,
    dynamic theme,
    dynamic locale,
  });

  /// Pumps a widget and waits for all animations and async operations
  /// to settle.
  ///
  /// This is a convenience method that combines pumpWidget and pumpAndSettle
  /// with additional waiting for common async operations.
  Future<void> pumpAndSettle(
    dynamic tester,
    dynamic widget, {
    Duration? timeout,
  });

  /// Creates a mock state manager for testing purposes.
  ///
  /// The mock will behave identically to a real state manager but allows
  /// for controlled testing scenarios.
  MockStateManager<T> createMockState<T>({
    T? initialState,
    bool enablePersistence = false,
  });

  /// Creates a mock navigation system for testing route transitions.
  MockNavigationStack createMockNavigation({
    List<MockRoute>? initialStack,
  });

  /// Sets up a complete test environment with all toolkit components.
  ///
  /// This creates a fully configured test environment that mirrors
  /// a real application setup.
  Future<TestEnvironment> setupTestEnvironment({
    Map<Type, dynamic>? overrides,
  });

  /// Cleans up test resources and resets global state.
  ///
  /// Should be called after each test to ensure clean state
  /// for subsequent tests.
  Future<void> cleanup();
}

/// Factory for generating realistic test data.
///
/// Provides deterministic generation of test objects with
/// customizable properties and relationships.
abstract class TestDataFactory {
  /// Creates a single instance of the specified type.
  ///
  /// Uses sensible defaults but allows overriding specific properties
  /// through the overrides parameter.
  T create<T>({
    Map<String, dynamic>? overrides,
    int? seed,
  });

  /// Creates a list of instances with optional variations.
  ///
  /// Generates multiple instances with slight variations to simulate
  /// realistic data sets for testing.
  List<T> createList<T>(
    int count, {
    Map<String, dynamic>? baseData,
    bool addVariations = true,
    int? seed,
  });

  /// Creates related objects that reference each other.
  ///
  /// Useful for testing complex object relationships and
  /// ensuring referential integrity in tests.
  Map<String, dynamic> createRelatedObjects(
    List<Type> types, {
    Map<String, dynamic>? relationships,
  });

  /// Registers a custom factory function for a specific type.
  ///
  /// Allows customization of how specific types are generated
  /// while maintaining the standard factory interface.
  void registerFactory<T>(T Function(Map<String, dynamic>?) factory);
}

/// Mock implementation of StateManager for testing.
class MockStateManager<T> implements StateManager<T> {
  T _state;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  final bool _supportsPersistence;
  bool _disposed = false;

  /// Creates a new mock state manager with the specified initial state.
  MockStateManager(
    this._state, {
    bool supportsPersistence = false,
  }) : _supportsPersistence = supportsPersistence;

  @override
  T get state {
    if (_disposed) throw StateError('StateManager has been disposed');
    return _state;
  }

  @override
  Stream<T> get stream => _controller.stream;

  @override
  void update(T Function(T current) updater) {
    if (_disposed) throw StateError('StateManager has been disposed');
    final newState = updater(_state);
    if (newState != _state) {
      _state = newState;
      _controller.add(_state);
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _controller.close();
    }
  }

  @override
  bool get supportsPersistence => _supportsPersistence;

  @override
  Future<void> persist() async {
    if (!_supportsPersistence) {
      throw UnsupportedError('Persistence not supported');
    }
    // Mock persistence - in real implementation would save to storage
  }

  @override
  Future<void> restore() async {
    if (!_supportsPersistence) {
      throw UnsupportedError('Persistence not supported');
    }
    // Mock restoration - in real implementation would load from storage
  }
}

/// Mock route for testing navigation.
class MockRoute {
  /// The route path.
  final String path;

  /// Route parameters.
  final Map<String, dynamic> parameters;

  /// Creates a new mock route.
  const MockRoute({
    required this.path,
    this.parameters = const {},
  });

  @override
  String toString() => 'MockRoute(path: $path, params: $parameters)';
}

/// Mock implementation of NavigationStack for testing.
class MockNavigationStack {
  final List<MockRoute> _stack;
  final StreamController<List<MockRoute>> _stackController =
      StreamController<List<MockRoute>>.broadcast();

  /// Creates a new mock navigation stack with optional initial routes.
  MockNavigationStack([List<MockRoute>? initialStack])
      : _stack = List.from(initialStack ?? []);

  /// The current navigation history as a list of routes.
  List<MockRoute> get history => List.unmodifiable(_stack);

  /// Whether the stack can pop (has more than one route).
  bool get canPop => _stack.length > 1;

  /// Stream of navigation stack changes.
  Stream<List<MockRoute>> get stackStream => _stackController.stream;

  /// Pushes a new route onto the navigation stack.
  void push(MockRoute route) {
    _stack.add(route);
    _stackController.add(history);
  }

  /// Pops the current route from the stack with an optional result.
  void pop<T>([T? result]) {
    if (canPop) {
      _stack.removeLast();
      _stackController.add(history);
    }
  }

  /// Replaces the current route with a new one.
  void pushReplacement(MockRoute route) {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
    _stack.add(route);
    _stackController.add(history);
  }

  /// Pushes a route and removes all previous routes until the predicate
  /// returns true.
  void pushAndRemoveUntil(
    MockRoute route,
    bool Function(MockRoute) predicate,
  ) {
    while (_stack.isNotEmpty && !predicate(_stack.last)) {
      _stack.removeLast();
    }
    _stack.add(route);
    _stackController.add(history);
  }

  /// Clears all routes from the stack.
  void clear() {
    _stack.clear();
    _stackController.add(history);
  }

  /// Disposes of the mock navigation stack.
  void dispose() {
    _stackController.close();
  }
}

/// Complete test environment setup with all toolkit components.
class TestEnvironment {
  /// The test helper instance.
  final TestHelper helper;

  /// The test data factory instance.
  final TestDataFactory dataFactory;

  /// Mock state provider for dependency injection.
  final StateProvider stateProvider;

  /// Mock navigation system.
  final MockNavigationStack navigationStack;

  /// Creates a new test environment.
  const TestEnvironment({
    required this.helper,
    required this.dataFactory,
    required this.stateProvider,
    required this.navigationStack,
  });

  /// Disposes of all test environment resources.
  Future<void> dispose() async {
    await helper.cleanup();
    navigationStack.dispose();
  }
}

/// Provider interface for dependency injection in tests.
abstract class Provider {
  /// The type this provider handles.
  Type get type;

  /// Creates an instance of the provided type.
  dynamic create();
}
