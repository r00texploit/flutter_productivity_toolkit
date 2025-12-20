import 'package:flutter_dev_toolkit/src/testing/test_helper.dart';
import 'package:test/test.dart';

void main() {
  group('Testing Utilities - Pure Dart', () {
    late DefaultTestDataFactory dataFactory;

    setUp(() {
      dataFactory = DefaultTestDataFactory();
    });

    group('TestDataFactory', () {
      test('should create basic string types', () {
        // Act
        final result = dataFactory.create<String>();

        // Assert
        expect(result, isA<String>());
        expect(result, isNotEmpty);
      });

      test('should create basic int types', () {
        // Act
        final result = dataFactory.create<int>();

        // Assert
        expect(result, isA<int>());
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(1000));
      });

      test('should create basic double types', () {
        // Act
        final result = dataFactory.create<double>();

        // Assert
        expect(result, isA<double>());
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1000.0));
      });

      test('should create basic bool types', () {
        // Act
        final result = dataFactory.create<bool>();

        // Assert
        expect(result, isA<bool>());
      });

      test('should create DateTime types', () {
        // Act
        final result = dataFactory.create<DateTime>();

        // Assert
        expect(result, isA<DateTime>());
      });

      test('should create types with overrides', () {
        // Arrange
        const expectedString = 'Custom Value';
        const expectedInt = 999;

        // Act
        final customString = dataFactory.create<String>(
          overrides: {'value': expectedString},
        );
        final customInt = dataFactory.create<int>(
          overrides: {'value': expectedInt},
        );

        // Assert
        expect(customString, equals(expectedString));
        expect(customInt, equals(expectedInt));
      });

      test('should create deterministic data with seeds', () {
        // Arrange
        const seed = 12345;

        // Act
        final first = dataFactory.create<int>(seed: seed);
        final second = dataFactory.create<int>(seed: seed);

        // Assert
        expect(first, equals(second));
      });

      test('should create lists of specified length', () {
        // Act
        final stringList = dataFactory.createList<String>(5);

        // Assert
        expect(stringList.length, equals(5));
        expect(stringList.every((s) => s is String), isTrue);
      });

      test('should create lists with base data', () {
        // Arrange
        final baseData = {'prefix': 'test'};

        // Act
        final stringList = dataFactory.createList<String>(
          3,
          baseData: baseData,
          addVariations: false,
        );

        // Assert
        expect(stringList.length, equals(3));
        expect(stringList.every((s) => s is String), isTrue);
      });

      test('should support custom factories', () {
        // Arrange
        dataFactory.registerFactory<String>((overrides) => 'Custom: ${overrides?['suffix'] ?? 'default'}');

        // Act
        final custom = dataFactory.create<String>(
          overrides: {'suffix': 'test'},
        );

        // Assert
        expect(custom, equals('Custom: test'));
      });

      test('should create MockRoute objects', () {
        // Act
        final route = dataFactory.create<MockRoute>();

        // Assert
        expect(route, isA<MockRoute>());
        expect(route.path, isNotEmpty);
        expect(route.parameters, isA<Map<String, dynamic>>());
      });

      test('should create Map objects', () {
        // Act
        final map = dataFactory.create<Map<String, dynamic>>();

        // Assert
        expect(map, isA<Map<String, dynamic>>());
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('email'), isTrue);
      });

      test('should create related objects', () {
        // Act
        final related = dataFactory.createRelatedObjects(
          [String, int, bool],
          relationships: {'customKey': 'customValue'},
        );

        // Assert
        expect(related.containsKey('String'), isTrue);
        expect(related.containsKey('int'), isTrue);
        expect(related.containsKey('bool'), isTrue);
        expect(related['customKey'], equals('customValue'));
        expect(related['String'], isA<String>());
        expect(related['int'], isA<int>());
        expect(related['bool'], isA<bool>());
      });

      test('should throw for unsupported types', () {
        // Act & Assert
        expect(
          () => dataFactory.create<List<String>>(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('should handle int range overrides', () {
        // Act
        final result = dataFactory.create<int>(
          overrides: {'min': 100, 'max': 200},
        );

        // Assert
        expect(result, greaterThanOrEqualTo(100));
        expect(result, lessThanOrEqualTo(200));
      });

      test('should handle double range overrides', () {
        // Act
        final result = dataFactory.create<double>(
          overrides: {'min': 10.5, 'max': 20.5},
        );

        // Assert
        expect(result, greaterThanOrEqualTo(10.5));
        expect(result, lessThanOrEqualTo(20.5));
      });
    });

    group('MockStateManager', () {
      test('should create with initial state', () {
        // Arrange & Act
        final mockState = MockStateManager<int>(42);

        // Assert
        expect(mockState.state, equals(42));
        expect(mockState.supportsPersistence, isFalse);
      });

      test('should create with persistence support', () {
        // Arrange & Act
        final mockState = MockStateManager<int>(
          42,
          supportsPersistence: true,
        );

        // Assert
        expect(mockState.state, equals(42));
        expect(mockState.supportsPersistence, isTrue);
      });

      test('should handle state updates', () async {
        // Arrange
        final mockState = MockStateManager<int>(0);
        final states = <int>[];

        // Listen to stream
        final subscription = mockState.stream.listen(states.add);

        // Act - first update
        mockState.update((current) => current + 1);

        // Assert first update
        expect(mockState.state, equals(1));

        // Act - second update
        mockState.update((current) => current * 2);

        // Assert final state
        expect(mockState.state, equals(2));

        // Wait a moment for stream events to be processed
        await Future<void>.delayed(const Duration(milliseconds: 1));

        // Assert stream received both updates
        expect(states.length, equals(2));
        expect(states[0], equals(1));
        expect(states[1], equals(2));

        // Cleanup
        subscription.cancel();
        mockState.dispose();
      });

      test('should not update when new state equals current state', () async {
        // Arrange
        final mockState = MockStateManager<int>(5);
        final states = <int>[];
        final subscription = mockState.stream.listen(states.add);

        // Act
        mockState.update((current) => current); // No change

        // No need to wait since stream is synchronous

        // Assert
        expect(mockState.state, equals(5));
        expect(states, isEmpty);

        // Cleanup
        subscription.cancel();
        mockState.dispose();
      });

      test('should throw when accessing disposed state manager', () {
        // Arrange
        final mockState = MockStateManager<int>(42);
        mockState.dispose();

        // Act & Assert
        expect(() => mockState.state, throwsA(isA<StateError>()));
        expect(
          () => mockState.update((current) => current + 1),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle persistence operations when supported', () async {
        // Arrange
        final mockState = MockStateManager<int>(
          42,
          supportsPersistence: true,
        );

        // Act & Assert - should not throw
        await mockState.persist();
        await mockState.restore();

        // Cleanup
        mockState.dispose();
      });

      test('should throw when persistence not supported', () async {
        // Arrange
        final mockState = MockStateManager<int>(42);

        // Act & Assert
        expect(mockState.persist(), throwsA(isA<UnsupportedError>()));
        expect(mockState.restore(), throwsA(isA<UnsupportedError>()));

        // Cleanup
        mockState.dispose();
      });
    });

    group('MockNavigationStack', () {
      test('should create empty stack', () {
        // Arrange & Act
        final stack = MockNavigationStack();

        // Assert
        expect(stack.history, isEmpty);
        expect(stack.canPop, isFalse);
      });

      test('should create with initial routes', () {
        // Arrange
        final initialRoutes = [
          const MockRoute(path: '/home'),
          const MockRoute(path: '/profile'),
        ];

        // Act
        final stack = MockNavigationStack(initialRoutes);

        // Assert
        expect(stack.history.length, equals(2));
        expect(stack.history.first.path, equals('/home'));
        expect(stack.history.last.path, equals('/profile'));
        expect(stack.canPop, isTrue);
      });

      test('should handle push operations', () {
        // Arrange
        final stack = MockNavigationStack();
        const route = MockRoute(path: '/test');

        // Act
        stack.push(route);

        // Assert
        expect(stack.history.length, equals(1));
        expect(stack.history.first.path, equals('/test'));
        expect(stack.canPop, isFalse); // Only one route
      });

      test('should handle pop operations', () {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');

        stack.push(route1);
        stack.push(route2);

        // Act
        stack.pop();

        // Assert
        expect(stack.history.length, equals(1));
        expect(stack.history.last.path, equals('/first'));
      });

      test('should handle pop when only one route', () {
        // Arrange
        final stack = MockNavigationStack();
        const route = MockRoute(path: '/only');
        stack.push(route);

        // Act
        stack.pop();

        // Assert
        expect(stack.history, isEmpty);
        expect(stack.canPop, isFalse);
      });

      test('should handle push replacement', () {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');

        stack.push(route1);

        // Act
        stack.pushReplacement(route2);

        // Assert
        expect(stack.history.length, equals(1));
        expect(stack.history.last.path, equals('/second'));
      });

      test('should handle push and remove until', () {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/home');
        const route2 = MockRoute(path: '/profile');
        const route3 = MockRoute(path: '/settings');
        const route4 = MockRoute(path: '/login');

        stack.push(route1);
        stack.push(route2);
        stack.push(route3);

        // Act
        stack.pushAndRemoveUntil(
          route4,
          (route) => route.path == '/home',
        );

        // Assert
        expect(stack.history.length, equals(2));
        expect(stack.history.first.path, equals('/home'));
        expect(stack.history.last.path, equals('/login'));
      });

      test('should handle clear operation', () {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');

        stack.push(route1);
        stack.push(route2);

        // Act
        stack.clear();

        // Assert
        expect(stack.history, isEmpty);
        expect(stack.canPop, isFalse);
      });

      test('should emit stack changes on stream', () async {
        // Arrange
        final stack = MockNavigationStack();
        final stackChanges = <List<MockRoute>>[];
        final subscription = stack.stackStream.listen(stackChanges.add);

        const route = MockRoute(path: '/test');

        // Act
        stack.push(route);

        // Allow async operations to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(stackChanges.length, equals(1));
        expect(stackChanges.first.length, equals(1));
        expect(stackChanges.first.first.path, equals('/test'));

        // Cleanup
        await subscription.cancel();
        stack.dispose();
      });
    });

    group('NavigationTestHelper', () {
      test('should create test routes', () {
        // Arrange
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        final navigationHelper = NavigationTestHelper(mockRouteBuilder);

        // Act
        final route = navigationHelper.createTestRoute(
          path: '/test/custom',
          parameters: {'id': '456'},
          metadata: {'source': 'unit_test'},
        );

        // Assert
        expect(route.path, equals('/test/custom'));
        expect(route.parameters['id'], equals('456'));
        expect(route.metadata['source'], equals('unit_test'));

        // Cleanup
        mockRouteBuilder.dispose();
      });

      test('should verify parameter types', () {
        // Arrange
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        final navigationHelper = NavigationTestHelper(mockRouteBuilder);
        final parameters = {'id': 123, 'name': 'Test'};
        final expectedTypes = {'id': int, 'name': String};

        // Act
        final isValid = navigationHelper.verifyParameterTypes(
          parameters,
          expectedTypes,
        );

        // Assert
        expect(isValid, isTrue);

        // Cleanup
        mockRouteBuilder.dispose();
      });

      test('should track deep link simulation', () async {
        // Arrange
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        final navigationHelper = NavigationTestHelper(mockRouteBuilder);
        const testUrl = 'testapp://example.com/user/123?name=John';

        // Act
        await navigationHelper.simulateDeepLink(testUrl);

        // Assert
        expect(navigationHelper.simulatedDeepLinkHistory, contains(testUrl));

        // Cleanup
        mockRouteBuilder.dispose();
      });

      test('should clear deep link history', () async {
        // Arrange
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        final navigationHelper = NavigationTestHelper(mockRouteBuilder);
        const testUrl = 'testapp://example.com/user/123';

        await navigationHelper.simulateDeepLink(testUrl);

        // Act
        navigationHelper.clearDeepLinkHistory();

        // Assert
        expect(navigationHelper.simulatedDeepLinkHistory, isEmpty);

        // Cleanup
        mockRouteBuilder.dispose();
      });
    });

    group('DeepLinkTestHelper', () {
      test('should generate test URLs', () {
        // Arrange
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        final navigationHelper = NavigationTestHelper(mockRouteBuilder);
        final deepLinkHelper = DeepLinkTestHelper(navigationHelper);

        // Act
        final urls = deepLinkHelper.generateTestUrls(
          scheme: 'myapp',
          host: 'test.com',
          paths: ['/user', '/product'],
          paramVariations: 2,
        );

        // Assert
        expect(urls.length, equals(6)); // 2 paths × (1 base + 2 variations)
        expect(
            urls.any((url) => url.contains('myapp://test.com/user')), isTrue,);
        expect(urls.any((url) => url.contains('myapp://test.com/product')),
            isTrue,);

        // Cleanup
        mockRouteBuilder.dispose();
      });

      test('should test deep link flows', () async {
        // Arrange
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        final navigationHelper = NavigationTestHelper(mockRouteBuilder);
        final deepLinkHelper = DeepLinkTestHelper(navigationHelper);
        const testUrl = 'myapp://test.com/user/123?name=John';

        // Act
        final result = await deepLinkHelper.testDeepLinkFlow(
          testUrl,
          expectedParams: {'name': 'John'},
          expectSuccess: false, // Expecting failure since route not registered
        );

        // Assert
        expect(result.url, equals(testUrl));
        expect(result.isValid, isTrue); // Should match expectation
        expect(result.actualParams?['name'], equals('John'));

        // Cleanup
        mockRouteBuilder.dispose();
      });
    });

    group('Navigation Stack Operations', () {
      test('PushOperation should work correctly', () async {
        // Arrange
        final stack = MockNavigationStack();
        const route = MockRoute(path: '/test');
        final operation = PushOperation(route, 1);

        // Act
        await operation.execute(stack);

        // Assert - should not throw
        operation.verify(stack);
      });

      test('PopOperation should work correctly', () async {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');
        stack.push(route1);
        stack.push(route2);

        final operation = PopOperation(1, expectedTopRoute: '/first');

        // Act
        await operation.execute(stack);

        // Assert - should not throw
        operation.verify(stack);
      });

      test('PushReplacementOperation should work correctly', () async {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');
        stack.push(route1);

        final operation = PushReplacementOperation(route2, 1);

        // Act
        await operation.execute(stack);

        // Assert - should not throw
        operation.verify(stack);
        expect(stack.history.last.path, equals('/second'));
      });
    });
  });
}
