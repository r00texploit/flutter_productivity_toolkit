import 'package:flutter/material.dart';
import 'package:flutter_dev_toolkit/src/state_management/state_manager.dart';
import 'package:flutter_dev_toolkit/src/testing/test_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Testing Utilities Framework', () {
    late DefaultTestHelper testHelper;
    late DefaultTestDataFactory dataFactory;

    setUp(() {
      testHelper = DefaultTestHelper();
      dataFactory = DefaultTestDataFactory();
    });

    tearDown(() async {
      await testHelper.cleanup();
    });

    group('TestHelper', () {
      testWidgets('should wrap widgets with providers correctly',
          (tester) async {
        // Arrange
        const testWidget = Text('Test Widget');
        final theme = ThemeData.dark();

        // Act
        final wrappedWidget = testHelper.wrapWithProviders(
          testWidget,
          theme: theme,
          locale: const Locale('en', 'US'),
        );

        // Assert
        expect(wrappedWidget, isA<MaterialApp>());
        await tester.pumpWidget(wrappedWidget as Widget);
        expect(find.text('Test Widget'), findsOneWidget);
      });

      testWidgets('should pump and settle widgets correctly', (tester) async {
        // Arrange
        const testWidget = MaterialApp(
          home: Scaffold(
            body: CircularProgressIndicator(),
          ),
        );

        // Act & Assert - should not throw
        await testHelper.pumpAndSettle(tester, testWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

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

    group('TestDataFactory', () {
      test('should create basic types with defaults', () {
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

      test('should create lists with variations', () {
        // Act
        final stringList = dataFactory.createList<String>(
          5,
        );

        // Assert
        expect(stringList.length, equals(5));
        expect(stringList.every((s) => s is String), isTrue);
        // Variations should make items different
        expect(stringList.toSet().length, greaterThan(1));
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

      test('should simulate deep links', () async {
        // Arrange
        const testUrl = 'testapp://example.com/user/123?name=John';

        // Act
        final result = await navigationHelper.simulateDeepLink(testUrl);

        // Assert
        expect(navigationHelper.simulatedDeepLinkHistory, contains(testUrl));
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

      test('should test navigation stack operations', () async {
        // Arrange
        final stack = MockNavigationStack();
        const route1 = MockRoute(path: '/first');
        const route2 = MockRoute(path: '/second');

        final operations = [
          PushOperation(route1, 1),
          PushOperation(route2, 2),
          PopOperation(1, expectedTopRoute: '/first'),
        ];

        // Act & Assert - should not throw
        await navigationHelper.testNavigationStack(stack, operations);
      });
    });

    group('DeepLinkTestHelper', () {
      late NavigationTestHelper navigationHelper;
      late DeepLinkTestHelper deepLinkHelper;

      setUp(() {
        final mockRouteBuilder = NavigationTestHelper.createMockRouteBuilder();
        navigationHelper = NavigationTestHelper(mockRouteBuilder);
        deepLinkHelper = DeepLinkTestHelper(navigationHelper);
      });

      test('should generate test URLs', () {
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
      });

      test('should test deep link flows', () async {
        // Arrange
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
      });
    });

    group('MockNavigationStack Operations', () {
      late MockNavigationStack stack;

      setUp(() {
        stack = MockNavigationStack();
      });

      test('PushOperation should work correctly', () async {
        // Arrange
        const route = MockRoute(path: '/test');
        final operation = PushOperation(route, 1);

        // Act
        await operation.execute(stack);

        // Assert - should not throw
        operation.verify(stack);
      });

      test('PopOperation should work correctly', () async {
        // Arrange
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

    group('Integration Tests', () {
      test('should create complete test environment with all components',
          () async {
        // Arrange & Act
        final environment = await testHelper.setupTestEnvironment(
          overrides: {
            ReactiveStateManager<String>: ReactiveStateManager<String>(
              'test_state',
              config: StateConfiguration.testing(),
            ),
          },
        );

        // Assert
        expect(environment.helper, isNotNull);
        expect(environment.dataFactory, isNotNull);
        expect(environment.stateProvider, isNotNull);
        expect(environment.navigationStack, isNotNull);

        // Test state provider integration
        final stringManager =
            environment.stateProvider.provide<ReactiveStateManager<String>>();
        expect(stringManager.state, equals('test_state'));

        // Test data factory integration
        final testData = environment.dataFactory.create<String>();
        expect(testData, isA<String>());

        // Test navigation integration
        const testRoute = MockRoute(path: '/integration_test');
        environment.navigationStack.push(testRoute);
        expect(environment.navigationStack.history.length, equals(1));

        // Cleanup
        await environment.dispose();
      });
    });
  });
}
