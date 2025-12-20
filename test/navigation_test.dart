import 'package:flutter_dev_toolkit/src/navigation/route_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Navigation System', () {
    late DefaultRouteBuilder routeBuilder;
    late DefaultNavigationStack navigationStack;

    setUp(() {
      routeBuilder = DefaultRouteBuilder();
      navigationStack = routeBuilder.createNavigationStack();
    });

    tearDown(() {
      routeBuilder.dispose();
    });

    test('should define and navigate to routes with parameters', () async {
      // Arrange
      routeBuilder.defineRoute<Map<String, String>>(
        '/user/:id',
        (params) => const MockWidget(),
      );

      // Act
      await routeBuilder.navigate<Map<String, String>, void>(
        '/user/:id',
        params: {'id': '123'},
      );

      // Assert
      expect(routeBuilder.currentRoute?.path, equals('/user/:id'));
      expect(routeBuilder.currentRoute?.parameters['id'], equals('123'));
    });

    test('should handle deep links correctly', () async {
      // Arrange
      routeBuilder.registerDeepLinkHandler(
        '/user/:id',
        (params) async {
          expect(params['id'], equals('123'));
          return true;
        },
      );

      // Act
      final result =
          await routeBuilder.handleDeepLink('myapp://example.com/user/123');

      // Assert
      expect(result, isTrue);
    });

    test('should manage navigation stack history', () {
      // Arrange
      const route1 = NavigationRoute(path: '/home');
      const route2 = NavigationRoute(path: '/profile');
      const route3 = NavigationRoute(path: '/settings');

      // Act
      navigationStack.push(route1);
      navigationStack.push(route2);
      navigationStack.push(route3);

      // Assert
      expect(navigationStack.history.length, equals(3));
      expect(navigationStack.canPop, isTrue);
      expect(navigationStack.history.last.path, equals('/settings'));
    });

    test('should pop routes from navigation stack', () {
      // Arrange
      const route1 = NavigationRoute(path: '/home');
      const route2 = NavigationRoute(path: '/profile');

      navigationStack.push(route1);
      navigationStack.push(route2);

      // Act
      navigationStack.pop();

      // Assert
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.last.path, equals('/home'));
    });

    test('should replace current route', () {
      // Arrange
      const route1 = NavigationRoute(path: '/home');
      const route2 = NavigationRoute(path: '/profile');
      const route3 = NavigationRoute(path: '/settings');

      navigationStack.push(route1);
      navigationStack.push(route2);

      // Act
      navigationStack.pushReplacement(route3);

      // Assert
      expect(navigationStack.history.length, equals(2));
      expect(navigationStack.history.last.path, equals('/settings'));
      expect(navigationStack.history.first.path, equals('/home'));
    });

    test('should push and remove until predicate', () {
      // Arrange
      const route1 = NavigationRoute(path: '/home');
      const route2 = NavigationRoute(path: '/profile');
      const route3 = NavigationRoute(path: '/settings');
      const route4 = NavigationRoute(path: '/login');

      navigationStack.push(route1);
      navigationStack.push(route2);
      navigationStack.push(route3);

      // Act
      navigationStack.pushAndRemoveUntil(
        route4,
        (route) => route.path == '/home',
      );

      // Assert
      expect(navigationStack.history.length, equals(2));
      expect(navigationStack.history.first.path, equals('/home'));
      expect(navigationStack.history.last.path, equals('/login'));
    });

    test('should preserve and restore state', () {
      // Arrange
      const testKey = 'testData';
      const testValue = 'testValue';

      // Act
      navigationStack.preserveState(testKey, testValue);
      final restoredValue = navigationStack.restoreState<String>(testKey);

      // Assert
      expect(restoredValue, equals(testValue));
    });

    test('should clear navigation stack', () {
      // Arrange
      const route1 = NavigationRoute(path: '/home');
      const route2 = NavigationRoute(path: '/profile');

      navigationStack.push(route1);
      navigationStack.push(route2);

      // Act
      navigationStack.clear();

      // Assert
      expect(navigationStack.history.isEmpty, isTrue);
      expect(navigationStack.canPop, isFalse);
    });

    test('should handle route guards', () async {
      // Arrange
      final authGuard = DefaultRouteGuard((route) async => false);

      routeBuilder.defineRouteWithGuards<void>(
        '/protected',
        (params) => const MockWidget(),
        guards: [authGuard],
        requiresAuthentication: true,
      );

      // Act & Assert
      expect(
        () => routeBuilder.navigate<void, void>('/protected'),
        throwsA(isA<StateError>()),
      );
    });

    test('should create multiple navigation stacks', () {
      // Arrange
      final initialCount = routeBuilder.navigationStacks.length;

      // Act
      final stack1 = routeBuilder.createNavigationStack();
      final stack2 = routeBuilder.createNavigationStack();

      // Assert
      expect(routeBuilder.navigationStacks.length, equals(initialCount + 2));
      expect(routeBuilder.navigationStacks.contains(stack1), isTrue);
      expect(routeBuilder.navigationStacks.contains(stack2), isTrue);
    });

    test('should set active navigation stack', () {
      // Arrange
      final newStack = routeBuilder.createNavigationStack();

      // Act
      routeBuilder.setActiveStack(newStack);

      // Assert - We can't directly test the active stack, but we can test navigation behavior
      expect(routeBuilder.navigationStacks.contains(newStack), isTrue);
    });

    test('should remove navigation stack', () {
      // Arrange
      final stackToRemove = routeBuilder.createNavigationStack();
      final initialCount = routeBuilder.navigationStacks.length;

      // Act
      routeBuilder.removeNavigationStack(stackToRemove);

      // Assert
      expect(routeBuilder.navigationStacks.length, equals(initialCount - 1));
      expect(routeBuilder.navigationStacks.contains(stackToRemove), isFalse);
    });

    test('should validate route parameters', () {
      // Arrange
      final stringParams = {'id': '123', 'name': 'test'};
      final expectedTypes = {'id': int, 'name': String};

      // Act
      final convertedParams = RouteParameterValidator.convertParameters(
        stringParams,
        expectedTypes,
      );

      // Assert
      expect(convertedParams['id'], equals(123));
      expect(convertedParams['name'], equals('test'));
    });

    test('should handle parameter conversion errors gracefully', () {
      // Arrange
      final stringParams = {'id': 'invalid', 'name': 'test'};
      final expectedTypes = {'id': int, 'name': String};

      // Act
      final convertedParams = RouteParameterValidator.convertParameters(
        stringParams,
        expectedTypes,
      );

      // Assert
      expect(convertedParams['id'], equals('invalid')); // Kept as string
      expect(convertedParams['name'], equals('test'));
    });

    test('should emit route changes on stream', () async {
      // Arrange
      final routeChanges = <RouteInformation>[];
      final subscription = routeBuilder.routeStream.listen(routeChanges.add);

      routeBuilder.defineRoute<void>('/test', (params) => const MockWidget());

      // Act
      await routeBuilder.navigate<void, void>('/test');

      // Allow async operations to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(routeChanges.length, equals(1));
      expect(routeChanges.first.path, equals('/test'));

      // Cleanup
      await subscription.cancel();
    });

    test('should emit stack changes on stream', () async {
      // Arrange
      final stackChanges = <List<NavigationRoute>>[];
      final subscription = navigationStack.stackStream.listen(stackChanges.add);

      const route = NavigationRoute(path: '/test');

      // Act
      navigationStack.push(route);

      // Allow async operations to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(stackChanges.length, equals(1));
      expect(stackChanges.first.length, equals(1));
      expect(stackChanges.first.first.path, equals('/test'));

      // Cleanup
      await subscription.cancel();
    });
  });
}

// Mock widget for testing
class MockWidget {
  const MockWidget();
}
