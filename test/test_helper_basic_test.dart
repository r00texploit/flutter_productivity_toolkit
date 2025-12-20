import 'package:flutter_dev_toolkit/src/state_management/state_manager.dart';
import 'package:flutter_dev_toolkit/src/testing/test_helper.dart';
import 'package:test/test.dart';

void main() {
  group('Basic Testing Utilities', () {
    late DefaultTestHelper testHelper;
    late DefaultTestDataFactory dataFactory;

    setUp(() {
      testHelper = DefaultTestHelper();
      dataFactory = DefaultTestDataFactory();
    });

    tearDown(() async {
      await testHelper.cleanup();
    });

    group('TestDataFactory', () {
      test('should create basic types', () {
        // Act & Assert
        expect(dataFactory.create<String>(), isA<String>());
        expect(dataFactory.create<int>(), isA<int>());
        expect(dataFactory.create<double>(), isA<double>());
        expect(dataFactory.create<bool>(), isA<bool>());
        expect(dataFactory.create<DateTime>(), isA<DateTime>());
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

      test('should create lists', () {
        // Act
        final stringList = dataFactory.createList<String>(5);

        // Assert
        expect(stringList.length, equals(5));
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
    });

    group('MockStateManager', () {
      test('should create mock state managers', () {
        // Arrange & Act
        final mockState = testHelper.createMockState<int>(
          initialState: 42,
          enablePersistence: true,
        );

        // Assert
        expect(mockState.state, equals(42));
        expect(mockState.supportsPersistence, isTrue);
      });

      test('should handle state updates', () {
        // Arrange
        final mockState = testHelper.createMockState<int>(initialState: 0);
        final states = <int>[];
        final subscription = mockState.stream.listen(states.add);

        // Act
        mockState.update((current) => current + 1);
        mockState.update((current) => current * 2);

        // Assert
        expect(mockState.state, equals(2));
        expect(states, equals([1, 2]));

        // Cleanup
        subscription.cancel();
        mockState.dispose();
      });
    });

    group('MockNavigationStack', () {
      test('should create mock navigation stacks', () {
        // Arrange
        final initialRoutes = [
          const MockRoute(path: '/home'),
          const MockRoute(path: '/profile'),
        ];

        // Act
        final mockNavigation = testHelper.createMockNavigation(
          initialStack: initialRoutes,
        );

        // Assert
        expect(mockNavigation.history.length, equals(2));
        expect(mockNavigation.history.first.path, equals('/home'));
        expect(mockNavigation.canPop, isTrue);
      });

      test('should handle navigation operations', () {
        // Arrange
        final mockNavigation = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');

        // Act & Assert
        mockNavigation.push(route1);
        expect(mockNavigation.history.length, equals(1));

        mockNavigation.push(route2);
        expect(mockNavigation.history.length, equals(2));

        mockNavigation.pop();
        expect(mockNavigation.history.length, equals(1));
        expect(mockNavigation.history.last.path, equals('/first'));
      });
    });

    group('TestEnvironment', () {
      test('should setup complete test environment', () async {
        // Arrange & Act
        final environment = await testHelper.setupTestEnvironment();

        // Assert
        expect(environment.helper, equals(testHelper));
        expect(environment.dataFactory, isA<TestDataFactory>());
        expect(environment.stateProvider, isA<StateProvider>());
        expect(environment.navigationStack, isA<MockNavigationStack>());

        // Cleanup
        await environment.dispose();
      });
    });

    group('NavigationTestHelper', () {
      late MockRouteBuilder mockRouteBuilder;
      late NavigationTestHelper navigationHelper;

      setUp(() {
        mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        navigationHelper = NavigationTestHelper(mockRouteBuilder);
      });

      tearDown(() {
        mockRouteBuilder.dispose();
      });

      test('should create test routes', () {
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
      });

      test('should verify parameter types', () {
        // Arrange
        final parameters = {'id': 123, 'name': 'Test'};
        final expectedTypes = {'id': int, 'name': String};

        // Act
        final isValid = navigationHelper.verifyParameterTypes(
          parameters,
          expectedTypes,
        );

        // Assert
        expect(isValid, isTrue);
      });

      test('should track deep link simulation', () async {
        // Arrange
        const testUrl = 'testapp://example.com/user/123?name=John';

        // Act
        await navigationHelper.simulateDeepLink(testUrl);

        // Assert
        expect(navigationHelper.simulatedDeepLinkHistory, contains(testUrl));
      });
    });
  });
}
