import 'dart:async';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../errors/error_reporter.dart';
import '../navigation/route_builder.dart';
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
    Widget child, {
    List<Provider>? providers,
    ThemeData? theme,
    Locale? locale,
  });

  /// Pumps a widget and waits for all animations and async operations
  /// to settle.
  ///
  /// This is a convenience method that combines pumpWidget and pumpAndSettle
  /// with additional waiting for common async operations.
  Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
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
  /// Creates a new mock state manager with the specified initial state.
  MockStateManager(
    this._state, {
    bool supportsPersistence = false,
  }) : _supportsPersistence = supportsPersistence;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  final bool _supportsPersistence;
  bool _disposed = false;
  T _state;

  @override
  T get state {
    if (_disposed) {
      throw StateError('StateManager has been disposed');
    }
    return _state;
  }

  @override
  Stream<T> get stream => _controller.stream;

  @override
  void update(T Function(T current) updater) {
    if (_disposed) {
      throw StateError('StateManager has been disposed');
    }
    final previousState = _state;
    final newState = updater(_state);
    if (newState != previousState) {
      _state = newState;
      if (!_controller.isClosed) {
        _controller.add(_state);
      }
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
  /// Creates a new mock route.
  const MockRoute({
    required this.path,
    this.parameters = const {},
  });

  /// The route path.
  final String path;

  /// Route parameters.
  final Map<String, dynamic> parameters;

  @override
  String toString() => 'MockRoute(path: $path, params: $parameters)';
}

/// Mock implementation of NavigationStack for testing.
class MockNavigationStack {
  /// Creates a new mock navigation stack with optional initial routes.
  MockNavigationStack([List<MockRoute>? initialStack])
      : _stack = List.from(initialStack ?? []);
  final List<MockRoute> _stack;
  final StreamController<List<MockRoute>> _stackController =
      StreamController<List<MockRoute>>.broadcast();

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
    if (_stack.isNotEmpty) {
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
  /// Creates a new test environment.
  const TestEnvironment({
    required this.helper,
    required this.dataFactory,
    required this.stateProvider,
    required this.navigationStack,
  });

  /// The test helper instance.
  final TestHelper helper;

  /// The test data factory instance.
  final TestDataFactory dataFactory;

  /// Mock state provider for dependency injection.
  final StateProvider stateProvider;

  /// Mock navigation system.
  final MockNavigationStack navigationStack;

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

/// Concrete implementation of TestHelper with pre-configured test environments.
class DefaultTestHelper extends TestHelper {
  /// Creates a new DefaultTestHelper.
  DefaultTestHelper({ErrorReporter? errorReporter})
      : _errorReporter = errorReporter ?? DefaultErrorReporter();
  final ErrorReporter _errorReporter;
  final List<TestEnvironment> _activeEnvironments = [];

  @override
  dynamic wrapWithProviders(
    Widget child, {
    List<Provider>? providers,
    ThemeData? theme,
    Locale? locale,
  }) {
    // For non-Flutter testing, just return the child
    // In a real Flutter implementation, this would wrap with MaterialApp
    return child;
  }

  @override
  Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration? timeout,
  }) async {
    // For non-Flutter testing, just wait a bit
    // In a real Flutter implementation, this would pump the widget
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  MockStateManager<T> createMockState<T>({
    T? initialState,
    bool enablePersistence = false,
  }) {
    if (initialState == null) {
      throw ArgumentError('Initial state must be provided for mock creation');
    }

    return MockStateManager<T>(
      initialState,
      supportsPersistence: enablePersistence,
    );
  }

  @override
  MockNavigationStack createMockNavigation({
    List<MockRoute>? initialStack,
  }) =>
      MockNavigationStack(initialStack);

  @override
  Future<TestEnvironment> setupTestEnvironment({
    Map<Type, dynamic>? overrides,
  }) async {
    final dataFactory = DefaultTestDataFactory();
    final stateProvider = DefaultStateProvider(
      errorReporter: _errorReporter,
      defaultConfig: StateConfiguration.testing(),
    );
    final navigationStack = createMockNavigation();

    // Apply overrides if provided
    if (overrides != null) {
      for (final entry in overrides.entries) {
        final instance = entry.value;

        if (instance is StateManager) {
          stateProvider.register(instance);
        }
      }
    }

    final environment = TestEnvironment(
      helper: this,
      dataFactory: dataFactory,
      stateProvider: stateProvider,
      navigationStack: navigationStack,
    );

    _activeEnvironments.add(environment);
    return environment;
  }

  @override
  Future<void> cleanup() async {
    for (final environment in _activeEnvironments) {
      await environment.dispose();
    }
    _activeEnvironments.clear();
    // Note: ErrorReporter doesn't have dispose method in current implementation
  }
}

/// Concrete implementation of TestDataFactory with realistic data generation.
class DefaultTestDataFactory extends TestDataFactory {
  final Faker _faker = Faker();
  Random _random = Random();
  final Map<Type, Function> _customFactories = {};

  @override
  T create<T>({
    Map<String, dynamic>? overrides,
    int? seed,
  }) {
    if (seed != null) {
      _random = Random(seed);
    }

    // Check for custom factory first
    if (_customFactories.containsKey(T)) {
      final factory = _customFactories[T]! as T Function(Map<String, dynamic>?);
      return factory(overrides);
    }

    // Built-in type factories
    if (T == String) {
      return _createString(overrides) as T;
    } else if (T == int) {
      return _createInt(overrides) as T;
    } else if (T == double) {
      return _createDouble(overrides) as T;
    } else if (T == bool) {
      return _createBool(overrides) as T;
    } else if (T == DateTime) {
      return _createDateTime(overrides) as T;
    } else if (T == MockRoute) {
      return _createMockRoute(overrides) as T;
    } else if (T == Map<String, dynamic>) {
      return _createMap(overrides) as T;
    }

    throw UnsupportedError(
      'No factory registered for type $T. Use registerFactory<$T>() to add one.',
    );
  }

  @override
  List<T> createList<T>(
    int count, {
    Map<String, dynamic>? baseData,
    bool addVariations = true,
    int? seed,
  }) {
    if (seed != null) {
      _random = Random(seed);
    }

    final items = <T>[];
    for (var i = 0; i < count; i++) {
      final overrides = <String, dynamic>{};

      // Apply base data
      if (baseData != null) {
        overrides.addAll(baseData);
      }

      // Add variations if enabled
      if (addVariations) {
        overrides.addAll(_generateVariations(i));
      }

      items.add(create<T>(overrides: overrides));
    }

    return items;
  }

  @override
  Map<String, dynamic> createRelatedObjects(
    List<Type> types, {
    Map<String, dynamic>? relationships,
  }) {
    final objects = <String, dynamic>{};

    // Create base objects
    for (final type in types) {
      final typeName = type.toString();
      objects[typeName] = _createObjectByType(type);
    }

    // Apply relationships if specified
    if (relationships != null) {
      for (final entry in relationships.entries) {
        final key = entry.key;
        final value = entry.value;
        objects[key] = value;
      }
    }

    return objects;
  }

  @override
  void registerFactory<T>(T Function(Map<String, dynamic>?) factory) {
    _customFactories[T] = factory;
  }

  String _createString(Map<String, dynamic>? overrides) {
    if (overrides?.containsKey('value') == true) {
      return overrides!['value'] as String;
    }

    final options = [
      _faker.person.name(),
      _faker.lorem.sentence(),
      _faker.internet.email(),
      _faker.address.city(),
      _faker.company.name(),
    ];

    return options[_random.nextInt(options.length)];
  }

  int _createInt(Map<String, dynamic>? overrides) {
    if (overrides?.containsKey('value') == true) {
      return overrides!['value'] as int;
    }

    final min = overrides?['min'] as int? ?? 0;
    final max = overrides?['max'] as int? ?? 1000;

    return min + _random.nextInt(max - min);
  }

  double _createDouble(Map<String, dynamic>? overrides) {
    if (overrides?.containsKey('value') == true) {
      return overrides!['value'] as double;
    }

    final min = overrides?['min'] as double? ?? 0.0;
    final max = overrides?['max'] as double? ?? 1000.0;

    return min + _random.nextDouble() * (max - min);
  }

  bool _createBool(Map<String, dynamic>? overrides) {
    if (overrides?.containsKey('value') == true) {
      return overrides!['value'] as bool;
    }

    return _random.nextBool();
  }

  DateTime _createDateTime(Map<String, dynamic>? overrides) {
    if (overrides?.containsKey('value') == true) {
      return overrides!['value'] as DateTime;
    }

    final now = DateTime.now();
    final daysOffset = _random.nextInt(365) - 182; // ±6 months
    return now.add(Duration(days: daysOffset));
  }

  MockRoute _createMockRoute(Map<String, dynamic>? overrides) {
    final path =
        overrides?['path'] as String? ?? '/test/${_faker.lorem.word()}';
    final parameters = overrides?['parameters'] as Map<String, dynamic>? ??
        {
          'id': _random.nextInt(1000).toString(),
          'name': _faker.person.firstName(),
        };

    return MockRoute(path: path, parameters: parameters);
  }

  Map<String, dynamic> _createMap(Map<String, dynamic>? overrides) {
    final baseMap = {
      'id': _random.nextInt(1000),
      'name': _faker.person.name(),
      'email': _faker.internet.email(),
      'active': _random.nextBool(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (overrides != null) {
      for (final entry in overrides.entries) {
        baseMap[entry.key] = entry.value as Object;
      }
    }

    return baseMap;
  }

  Map<String, dynamic> _generateVariations(int index) => {
        'index': index,
        'variation': _random.nextInt(10),
        'timestamp': DateTime.now().millisecondsSinceEpoch + index,
      };

  dynamic _createObjectByType(Type type) {
    if (type == String) {
      return create<String>();
    }
    if (type == int) {
      return create<int>();
    }
    if (type == double) {
      return create<double>();
    }
    if (type == bool) {
      return create<bool>();
    }
    if (type == DateTime) {
      return create<DateTime>();
    }
    if (type == MockRoute) {
      return create<MockRoute>();
    }

    throw UnsupportedError('Cannot create object of type $type');
  }
}

/// Navigation testing utilities for simulating deep links and route transitions.
class NavigationTestHelper {
  /// Creates a new NavigationTestHelper.
  NavigationTestHelper(this._routeBuilder);
  final DefaultRouteBuilder _routeBuilder;
  final List<String> _simulatedDeepLinks = [];

  /// Simulates a deep link navigation for testing.
  ///
  /// This method allows testing deep link handling without requiring
  /// actual platform integration.
  Future<bool> simulateDeepLink(
    String url, {
    Map<String, String>? additionalParams,
  }) async {
    _simulatedDeepLinks.add(url);

    // Parse the URL and extract parameters
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);

    if (additionalParams != null) {
      params.addAll(additionalParams);
    }

    // Simulate the deep link handling
    return _routeBuilder.handleDeepLink(url);
  }

  /// Creates a test route with specified parameters for testing navigation.
  NavigationRoute createTestRoute({
    String? path,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? metadata,
  }) =>
      NavigationRoute(
        path: path ?? '/test/route/${DateTime.now().millisecondsSinceEpoch}',
        parameters: parameters ?? {'testParam': 'testValue'},
        metadata: metadata ?? {'source': 'test'},
      );

  /// Simulates a route transition with timing and animation testing.
  Future<void> simulateRouteTransition(
    NavigationRoute from,
    NavigationRoute to, {
    Duration? transitionDuration,
    bool expectSuccess = true,
  }) async {
    final startTime = DateTime.now();

    try {
      // Simulate navigation from one route to another
      await _routeBuilder.navigate(to.path, params: to.parameters);

      final endTime = DateTime.now();
      final actualDuration = endTime.difference(startTime);

      if (transitionDuration != null) {
        // Verify transition timing
        const tolerance = Duration(milliseconds: 100);
        final withinTolerance =
            actualDuration <= transitionDuration + tolerance;

        if (!withinTolerance && expectSuccess) {
          throw AssertionError(
            'Route transition took ${actualDuration.inMilliseconds}ms, '
            'expected ${transitionDuration.inMilliseconds}ms ± ${tolerance.inMilliseconds}ms',
          );
        }
      }
    } catch (e) {
      if (expectSuccess) {
        rethrow;
      }
      // Expected failure, continue
    }
  }

  /// Tests navigation stack operations with verification.
  Future<void> testNavigationStack(
    MockNavigationStack stack,
    List<NavigationStackOperation> operations,
  ) async {
    for (final operation in operations) {
      await operation.execute(stack);
      operation.verify(stack);
    }
  }

  /// Verifies that navigation parameters are correctly typed and validated.
  bool verifyParameterTypes(
    Map<String, dynamic> parameters,
    Map<String, Type> expectedTypes,
  ) =>
      RouteParameterValidator.validateParameters(
        parameters,
        expectedTypes,
      );

  /// Gets the history of simulated deep links for testing verification.
  List<String> get simulatedDeepLinkHistory =>
      List.unmodifiable(_simulatedDeepLinks);

  /// Clears the deep link simulation history.
  void clearDeepLinkHistory() {
    _simulatedDeepLinks.clear();
  }

  /// Creates a mock route builder for isolated navigation testing.
  static MockRouteBuilder createMockRouteBuilder({
    DeepLinkConfiguration? deepLinkConfig,
  }) =>
      MockRouteBuilder(deepLinkConfig: deepLinkConfig);
}

/// Abstract base class for navigation stack operations in tests.
abstract class NavigationStackOperation {
  /// Executes the operation on the navigation stack.
  Future<void> execute(MockNavigationStack stack);

  /// Verifies that the operation had the expected effect.
  void verify(MockNavigationStack stack);
}

/// Push operation for navigation stack testing.
class PushOperation extends NavigationStackOperation {
  /// Creates a new push operation.
  PushOperation(this.route, this.expectedStackSize);
  final MockRoute route;
  final int expectedStackSize;

  @override
  Future<void> execute(MockNavigationStack stack) async {
    stack.push(route);
  }

  @override
  void verify(MockNavigationStack stack) {
    if (stack.history.length != expectedStackSize) {
      throw AssertionError(
        'Expected stack size $expectedStackSize, got ${stack.history.length}',
      );
    }

    if (stack.history.last.path != route.path) {
      throw AssertionError(
        'Expected top route to be ${route.path}, got ${stack.history.last.path}',
      );
    }
  }
}

/// Pop operation for navigation stack testing.
class PopOperation extends NavigationStackOperation {
  /// Creates a new pop operation.
  PopOperation(this.expectedStackSize, {this.expectedTopRoute});
  final int expectedStackSize;
  final String? expectedTopRoute;

  @override
  Future<void> execute(MockNavigationStack stack) async {
    stack.pop();
  }

  @override
  void verify(MockNavigationStack stack) {
    if (stack.history.length != expectedStackSize) {
      throw AssertionError(
        'Expected stack size $expectedStackSize, got ${stack.history.length}',
      );
    }

    if (expectedTopRoute != null && stack.history.isNotEmpty) {
      if (stack.history.last.path != expectedTopRoute) {
        throw AssertionError(
          'Expected top route to be $expectedTopRoute, got ${stack.history.last.path}',
        );
      }
    }
  }
}

/// Push replacement operation for navigation stack testing.
class PushReplacementOperation extends NavigationStackOperation {
  /// Creates a new push replacement operation.
  PushReplacementOperation(this.route, this.expectedStackSize);
  final MockRoute route;
  final int expectedStackSize;

  @override
  Future<void> execute(MockNavigationStack stack) async {
    stack.pushReplacement(route);
  }

  @override
  void verify(MockNavigationStack stack) {
    if (stack.history.length != expectedStackSize) {
      throw AssertionError(
        'Expected stack size $expectedStackSize, got ${stack.history.length}',
      );
    }

    if (stack.history.last.path != route.path) {
      throw AssertionError(
        'Expected top route to be ${route.path}, got ${stack.history.last.path}',
      );
    }
  }
}

/// Mock route builder for isolated navigation testing.
class MockRouteBuilder extends DefaultRouteBuilder {
  /// Creates a new MockRouteBuilder.
  MockRouteBuilder({super.deepLinkConfig});
  final List<String> _navigationHistory = [];
  final Map<String, dynamic> _lastNavigationParams = {};

  @override
  Future<R?> navigate<T, R>(String path, {T? params}) async {
    _navigationHistory.add(path);
    if (params != null) {
      _lastNavigationParams[path] = params;
    }

    // Call parent implementation for actual navigation logic
    return super.navigate<T, R>(path, params: params);
  }

  /// Gets the navigation history for testing verification.
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// Gets the last parameters used for navigation to a specific path.
  T? getLastNavigationParams<T>(String path) =>
      _lastNavigationParams[path] as T?;

  /// Clears the navigation history.
  void clearNavigationHistory() {
    _navigationHistory.clear();
    _lastNavigationParams.clear();
  }

  /// Simulates a navigation failure for testing error handling.
  void simulateNavigationFailure(String path) {
    // Remove the route to cause navigation to fail
    // Note: Access to _routes from parent class
    super.unregisterDeepLinkHandler(path);
  }
}

/// Deep link testing utilities for comprehensive URL handling verification.
class DeepLinkTestHelper {
  /// Creates a new DeepLinkTestHelper.
  DeepLinkTestHelper(this._navigationHelper);
  final NavigationTestHelper _navigationHelper;

  /// Tests a complete deep link flow from URL to final navigation.
  Future<DeepLinkTestResult> testDeepLinkFlow(
    String url, {
    Map<String, String>? expectedParams,
    String? expectedFinalRoute,
    bool expectSuccess = true,
  }) async {
    final startTime = DateTime.now();

    try {
      final success = await _navigationHelper.simulateDeepLink(url);
      final endTime = DateTime.now();

      return DeepLinkTestResult(
        url: url,
        success: success,
        duration: endTime.difference(startTime),
        expectedSuccess: expectSuccess,
        actualParams: _extractParamsFromUrl(url),
        expectedParams: expectedParams,
      );
    } catch (e) {
      final endTime = DateTime.now();

      return DeepLinkTestResult(
        url: url,
        success: false,
        duration: endTime.difference(startTime),
        expectedSuccess: expectSuccess,
        error: e.toString(),
      );
    }
  }

  /// Generates test URLs with various parameter combinations.
  List<String> generateTestUrls({
    String scheme = 'testapp',
    String host = 'example.com',
    List<String> paths = const ['/user', '/product', '/settings'],
    int paramVariations = 3,
  }) {
    final urls = <String>[];

    for (final path in paths) {
      // Base URL without parameters
      urls.add('$scheme://$host$path');

      // URLs with various parameter combinations
      for (var i = 0; i < paramVariations; i++) {
        final params = _generateTestParams(i);
        final queryString = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');

        urls.add('$scheme://$host$path?$queryString');
      }
    }

    return urls;
  }

  Map<String, String> _extractParamsFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters;
  }

  Map<String, String> _generateTestParams(int variation) {
    final faker = Faker();

    switch (variation % 3) {
      case 0:
        return {
          'id': (variation + 1).toString(),
          'name': faker.person.firstName(),
        };
      case 1:
        return {
          'category': faker.lorem.word(),
          'sort': ['asc', 'desc'][variation % 2],
          'limit': (10 + variation * 5).toString(),
        };
      case 2:
        return {
          'token': faker.guid.guid(),
          'redirect': '/dashboard',
        };
      default:
        return {};
    }
  }
}

/// Result of a deep link test operation.
class DeepLinkTestResult {
  /// Creates a new DeepLinkTestResult.
  const DeepLinkTestResult({
    required this.url,
    required this.success,
    required this.duration,
    required this.expectedSuccess,
    this.actualParams,
    this.expectedParams,
    this.error,
  });

  /// The URL that was tested.
  final String url;

  /// Whether the deep link handling succeeded.
  final bool success;

  /// How long the deep link processing took.
  final Duration duration;

  /// Whether success was expected.
  final bool expectedSuccess;

  /// The actual parameters extracted from the URL.
  final Map<String, String>? actualParams;

  /// The expected parameters.
  final Map<String, String>? expectedParams;

  /// Error message if the test failed.
  final String? error;

  /// Whether the test result matches expectations.
  bool get isValid => success == expectedSuccess;

  /// Whether the parameters match expectations.
  bool get parametersMatch {
    if (expectedParams == null) {
      return true;
    }
    if (actualParams == null) {
      return false;
    }

    for (final entry in expectedParams!.entries) {
      if (actualParams![entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  String toString() => 'DeepLinkTestResult('
      'url: $url, '
      'success: $success, '
      'duration: ${duration.inMilliseconds}ms, '
      'valid: $isValid'
      ')';
}
