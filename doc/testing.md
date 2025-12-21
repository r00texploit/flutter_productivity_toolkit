# Testing Guide

Comprehensive testing strategies and utilities for Flutter applications using the Flutter Productivity Toolkit. This guide covers unit testing, widget testing, property-based testing, and integration testing approaches with practical examples and best practices.

## Prerequisites

- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher
- Basic understanding of Flutter testing concepts
- Flutter Productivity Toolkit installed and configured

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Unit Testing](#unit-testing)
3. [Widget Testing](#widget-testing)
4. [Property-Based Testing](#property-based-testing)
5. [Integration Testing](#integration-testing)
6. [Testing State Managers](#testing-state-managers)
7. [Mock Setup and Configuration](#mock-setup-and-configuration)
8. [Test Environment Configuration](#test-environment-configuration)
9. [Async Testing Patterns](#async-testing-patterns)
10. [Test Data Management](#test-data-management)
11. [API Mocking Strategies](#api-mocking-strategies)
12. [Performance Testing](#performance-testing)
13. [Troubleshooting](#troubleshooting)

## Testing Overview

The Flutter Productivity Toolkit provides comprehensive testing utilities that simplify test setup, mock generation, and integration testing. The testing framework is designed around three core principles:

- **Isolation**: Tests should be independent and not affect each other
- **Determinism**: Tests should produce consistent results across runs
- **Realism**: Mocks should behave as closely as possible to real implementations

### Testing Architecture

```dart
// Core testing components
TestHelper          // Main testing utilities
TestDataFactory     // Realistic test data generation
TestEnvironment     // Complete test setup
MockStateManager    // State management mocking
MockNavigationStack // Navigation testing
```

### Test Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
  mockito: ^5.4.0
  faker: ^2.1.0
  flutter_productivity_toolkit: ^0.1.0
```

## Unit Testing

Unit tests verify individual functions, classes, and business logic in isolation. The toolkit provides utilities to simplify unit test setup and execution.

### Basic Unit Test Structure

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('Calculator Tests', () {
    late Calculator calculator;
    late TestDataFactory dataFactory;

    setUp(() {
      calculator = Calculator();
      dataFactory = DefaultTestDataFactory();
    });

    test('should add two numbers correctly', () {
      // Arrange
      final a = dataFactory.create<int>(overrides: {'min': 1, 'max': 100});
      final b = dataFactory.create<int>(overrides: {'min': 1, 'max': 100});
      
      // Act
      final result = calculator.add(a, b);
      
      // Assert
      expect(result, equals(a + b));
    });

    test('should handle edge cases', () {
      // Test with zero
      expect(calculator.add(0, 5), equals(5));
      
      // Test with negative numbers
      expect(calculator.add(-3, 7), equals(4));
      
      // Test with large numbers
      expect(calculator.add(999999, 1), equals(1000000));
    });
  });
}
```

### Testing Business Logic

```dart
// Example: Testing a todo service
class TodoService {
  final List<Todo> _todos = [];
  
  void addTodo(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      completed: false,
      createdAt: DateTime.now(),
    );
    
    _todos.add(todo);
  }
  
  List<Todo> getTodos() => List.unmodifiable(_todos);
  
  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = _todos[index];
      _todos[index] = Todo(
        id: todo.id,
        title: todo.title,
        completed: !todo.completed,
        createdAt: todo.createdAt,
      );
    }
  }
}

// Unit tests for TodoService
void main() {
  group('TodoService Tests', () {
    late TodoService service;
    late TestDataFactory dataFactory;

    setUp(() {
      service = TodoService();
      dataFactory = DefaultTestDataFactory();
    });

    test('should add valid todo', () {
      // Arrange
      final title = dataFactory.create<String>();
      
      // Act
      service.addTodo(title);
      
      // Assert
      final todos = service.getTodos();
      expect(todos.length, equals(1));
      expect(todos.first.title, equals(title));
      expect(todos.first.completed, isFalse);
    });

    test('should reject empty title', () {
      // Act & Assert
      expect(() => service.addTodo(''), throwsArgumentError);
      expect(() => service.addTodo('   '), throwsArgumentError);
    });

    test('should toggle todo completion', () {
      // Arrange
      service.addTodo('Test todo');
      final todoId = service.getTodos().first.id;
      
      // Act
      service.toggleTodo(todoId);
      
      // Assert
      final todos = service.getTodos();
      expect(todos.first.completed, isTrue);
      
      // Toggle back
      service.toggleTodo(todoId);
      expect(service.getTodos().first.completed, isFalse);
    });
  });
}
```

## Widget Testing

Widget tests verify UI components and their interactions. The toolkit provides utilities to simplify widget testing with proper provider setup and mock dependencies.

### Basic Widget Testing

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() {
  group('TodoListWidget Tests', () {
    late TestHelper testHelper;
    late TestEnvironment testEnv;

    setUp(() async {
      testHelper = DefaultTestHelper();
      testEnv = await testHelper.setupTestEnvironment();
    });

    tearDown(() async {
      await testEnv.dispose();
    });

    testWidgets('should display empty state when no todos', (tester) async {
      // Arrange
      final mockTodoState = testHelper.createMockState<TodoState>(
        initialState: const TodoState(todos: []),
      );

      // Act
      await testHelper.pumpAndSettle(
        tester,
        TodoListWidget(),
        providers: [mockTodoState],
      );

      // Assert
      expect(find.text('No todos yet'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should display todos when available', (tester) async {
      // Arrange
      final todos = testEnv.dataFactory.createList<Todo>(3);
      final mockTodoState = testHelper.createMockState<TodoState>(
        initialState: TodoState(todos: todos),
      );

      // Act
      await testHelper.pumpAndSettle(
        tester,
        TodoListWidget(),
        providers: [mockTodoState],
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
      
      for (final todo in todos) {
        expect(find.text(todo.title), findsOneWidget);
      }
    });

    testWidgets('should handle todo toggle interaction', (tester) async {
      // Arrange
      final todo = testEnv.dataFactory.create<Todo>();
      final mockTodoState = testHelper.createMockState<TodoState>(
        initialState: TodoState(todos: [todo]),
      );

      await testHelper.pumpAndSettle(
        tester,
        TodoListWidget(),
        providers: [mockTodoState],
      );

      // Act
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Assert
      // Verify that the state manager's update method was called
      expect(mockTodoState.state.todos.first.completed, isTrue);
    });
  });
}
```

### Testing Complex Widget Interactions

```dart
testWidgets('should handle form submission', (tester) async {
  // Arrange
  final mockTodoState = testHelper.createMockState<TodoState>(
    initialState: const TodoState(todos: []),
  );

  await testHelper.pumpAndSettle(
    tester,
    TodoFormWidget(),
    providers: [mockTodoState],
  );

  // Act
  await tester.enterText(find.byType(TextField), 'New todo item');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Assert
  expect(mockTodoState.state.todos.length, equals(1));
  expect(mockTodoState.state.todos.first.title, equals('New todo item'));
  
  // Verify form was cleared
  expect(find.text('New todo item'), findsOneWidget); // In the list
  expect(
    (tester.widget(find.byType(TextField)) as TextField).controller?.text,
    isEmpty,
  );
});
```

## Property-Based Testing

Property-based testing verifies that certain properties hold true across a wide range of inputs. This approach is particularly effective for finding edge cases and ensuring robust behavior. For more information on property-based testing theory and advanced patterns, see the [State Management Guide](state_management.md#testing-state-management) for state-specific examples.

### Setting Up Property-Based Tests

```dart
import 'package:test/test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() {
  group('Property-Based Tests', () {
    late TestDataFactory dataFactory;

    setUp(() {
      dataFactory = DefaultTestDataFactory();
    });

    test('todo list length should increase when adding valid todos', () {
      // Property: Adding a valid todo should always increase list length by 1
      for (int i = 0; i < 100; i++) {
        // Arrange
        final service = TodoService();
        final initialCount = service.getTodos().length;
        final title = dataFactory.create<String>(
          overrides: {'min_length': 1, 'max_length': 100},
        );

        // Act
        service.addTodo(title);

        // Assert
        expect(
          service.getTodos().length,
          equals(initialCount + 1),
          reason: 'Failed with title: "$title"',
        );
      }
    });

    test('todo toggle should be idempotent after two operations', () {
      // Property: Toggling a todo twice should return it to original state
      for (int i = 0; i < 100; i++) {
        // Arrange
        final service = TodoService();
        final title = dataFactory.create<String>();
        service.addTodo(title);
        final todoId = service.getTodos().first.id;
        final originalState = service.getTodos().first.completed;

        // Act
        service.toggleTodo(todoId);
        service.toggleTodo(todoId);

        // Assert
        expect(
          service.getTodos().first.completed,
          equals(originalState),
          reason: 'Failed with todo: $title',
        );
      }
    });
  });
}
```

### Advanced Property Testing

```dart
test('state serialization round-trip property', () {
  // Property: Serializing then deserializing should preserve state
  for (int i = 0; i < 100; i++) {
    // Arrange
    final originalState = dataFactory.create<TodoState>();
    final serializer = StateSerializer<TodoState>();

    // Act
    final serialized = serializer.serialize(originalState);
    final deserialized = serializer.deserialize(serialized);

    // Assert
    expect(
      deserialized,
      equals(originalState),
      reason: 'Round-trip failed for state: $originalState',
    );
  }
});

test('navigation parameter validation property', () {
  // Property: Valid parameters should always pass validation
  final validator = RouteParameterValidator();
  
  for (int i = 0; i < 100; i++) {
    // Arrange
    final params = dataFactory.create<Map<String, dynamic>>();
    final expectedTypes = _generateExpectedTypes(params);

    // Act & Assert
    expect(
      validator.validateParameters(params, expectedTypes),
      isTrue,
      reason: 'Validation failed for params: $params',
    );
  }
});
```

## Integration Testing

Integration tests verify that multiple components work together correctly. The toolkit provides utilities for setting up complete test environments.

### Setting Up Integration Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Todo App Integration Tests', () {
    late TestEnvironment testEnv;

    setUp(() async {
      testEnv = await DefaultTestHelper().setupTestEnvironment();
    });

    tearDown(() async {
      await testEnv.dispose();
    });

    testWidgets('complete todo workflow', (tester) async {
      // Arrange
      await tester.pumpWidget(TodoApp());
      await tester.pumpAndSettle();

      // Act & Assert - Add todo
      await tester.enterText(find.byType(TextField), 'Buy groceries');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);

      // Act & Assert - Toggle completion
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box), findsOneWidget);

      // Act & Assert - Filter completed
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);

      // Act & Assert - Delete todo
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsNothing);
      expect(find.text('No todos yet'), findsOneWidget);
    });
  });
}
```

### Testing Navigation Flows

```dart
testWidgets('navigation between screens', (tester) async {
  // Arrange
  final navigationHelper = NavigationTestHelper(
    NavigationTestHelper.createMockRouteBuilder(),
  );

  await tester.pumpWidget(TodoApp());
  await tester.pumpAndSettle();

  // Act & Assert - Navigate to settings
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  expect(find.text('Settings'), findsOneWidget);

  // Act & Assert - Navigate back
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();

  expect(find.text('Todo List'), findsOneWidget);

  // Verify navigation history
  final history = navigationHelper.simulatedDeepLinkHistory;
  expect(history.length, greaterThan(0));
});
```

## Testing State Managers

State managers are central to application logic and require thorough testing to ensure reliability.

### Basic State Manager Testing

```dart
void main() {
  group('TodoStateManager Tests', () {
    late TodoStateManager stateManager;
    late TestHelper testHelper;

    setUp(() {
      testHelper = DefaultTestHelper();
      stateManager = TodoStateManager(
        initialState: const TodoState(todos: []),
        config: StateConfiguration.testing(),
      );
    });

    tearDown(() {
      stateManager.dispose();
    });

    test('should update state correctly', () async {
      // Arrange
      final states = <TodoState>[];
      final subscription = stateManager.stream.listen(states.add);

      // Act
      stateManager.update((current) => current.addTodo('Test todo'));
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(stateManager.state.todos.length, equals(1));
      expect(stateManager.state.todos.first.title, equals('Test todo'));
      expect(states.length, equals(1));

      // Cleanup
      await subscription.cancel();
    });

    test('should handle concurrent updates', () async {
      // Arrange
      final futures = <Future<void>>[];

      // Act - Perform multiple concurrent updates
      for (int i = 0; i < 10; i++) {
        futures.add(
          Future(() => stateManager.update(
            (current) => current.addTodo('Todo $i'),
          )),
        );
      }

      await Future.wait(futures);

      // Assert
      expect(stateManager.state.todos.length, equals(10));
      
      // Verify all todos were added
      for (int i = 0; i < 10; i++) {
        expect(
          stateManager.state.todos.any((todo) => todo.title == 'Todo $i'),
          isTrue,
        );
      }
    });
  });
}
```

### Testing State Persistence

```dart
test('should persist and restore state', () async {
  // Arrange
  final stateManager = TodoStateManager(
    initialState: const TodoState(todos: []),
    config: const StateConfiguration(enablePersistence: true),
  );

  // Add some todos
  stateManager.update((current) => current.addTodo('Persistent todo'));

  // Act - Persist state
  await stateManager.persist();

  // Create new state manager
  final newStateManager = TodoStateManager(
    initialState: const TodoState(todos: []),
    config: const StateConfiguration(enablePersistence: true),
  );

  // Restore state
  await newStateManager.restore();

  // Assert
  expect(newStateManager.state.todos.length, equals(1));
  expect(newStateManager.state.todos.first.title, equals('Persistent todo'));

  // Cleanup
  stateManager.dispose();
  newStateManager.dispose();
});
```

## Mock Setup and Configuration

Proper mock setup is crucial for isolated and reliable tests.

### Creating Mock State Managers

```dart
void main() {
  group('Mock State Manager Tests', () {
    late TestHelper testHelper;

    setUp(() {
      testHelper = DefaultTestHelper();
    });

    test('should create mock with initial state', () {
      // Arrange & Act
      final mockState = testHelper.createMockState<int>(
        initialState: 42,
        enablePersistence: true,
      );

      // Assert
      expect(mockState.state, equals(42));
      expect(mockState.supportsPersistence, isTrue);
    });

    test('should handle state updates in mock', () {
      // Arrange
      final mockState = testHelper.createMockState<List<String>>(
        initialState: <String>[],
      );

      final states = <List<String>>[];
      final subscription = mockState.stream.listen(states.add);

      // Act
      mockState.update((current) => [...current, 'item1']);
      mockState.update((current) => [...current, 'item2']);

      // Assert
      expect(mockState.state.length, equals(2));
      expect(states.length, equals(2));
      expect(states.last, equals(['item1', 'item2']));

      // Cleanup
      subscription.cancel();
      mockState.dispose();
    });
  });
}
```

### Mock Navigation Setup

```dart
test('should create mock navigation stack', () {
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

  // Test navigation operations
  mockNavigation.push(const MockRoute(path: '/settings'));
  expect(mockNavigation.history.length, equals(3));

  mockNavigation.pop();
  expect(mockNavigation.history.length, equals(2));
  expect(mockNavigation.history.last.path, equals('/profile'));
});
```

## Test Environment Configuration

The toolkit provides comprehensive test environment setup for consistent testing conditions.

### Basic Test Environment

```dart
void main() {
  group('Test Environment Tests', () {
    late TestEnvironment testEnv;

    setUp(() async {
      testEnv = await DefaultTestHelper().setupTestEnvironment();
    });

    tearDown(() async {
      await testEnv.dispose();
    });

    test('should provide all necessary components', () {
      // Assert
      expect(testEnv.helper, isNotNull);
      expect(testEnv.dataFactory, isNotNull);
      expect(testEnv.stateProvider, isNotNull);
      expect(testEnv.navigationStack, isNotNull);
    });

    test('should support custom overrides', () async {
      // Arrange
      final customStateManager = ReactiveStateManager<String>(
        'custom_state',
        config: StateConfiguration.testing(),
      );

      // Act
      final customEnv = await DefaultTestHelper().setupTestEnvironment(
        overrides: {
          ReactiveStateManager<String>: customStateManager,
        },
      );

      // Assert
      final retrievedManager = customEnv.stateProvider
          .provide<ReactiveStateManager<String>>();
      expect(retrievedManager.state, equals('custom_state'));

      // Cleanup
      await customEnv.dispose();
    });
  });
}
```

### Environment Configuration Options

```dart
// Custom test environment with specific configuration
Future<TestEnvironment> setupCustomTestEnvironment() async {
  final testHelper = DefaultTestHelper(
    errorReporter: TestErrorReporter(), // Custom error handling
  );

  return testHelper.setupTestEnvironment(
    overrides: {
      // Custom state managers
      TodoStateManager: TodoStateManager(
        initialState: TodoState(
          todos: [
            Todo(
              id: '1',
              title: 'Test todo',
              completed: false,
              createdAt: DateTime.now(),
            ),
          ],
        ),
        config: const StateConfiguration(
          enableDebugging: true,
          enablePersistence: false,
        ),
      ),
      
      // Custom navigation configuration
      NavigationConfiguration: const NavigationConfiguration(
        enableDeepLinking: true,
        defaultTransitionDuration: Duration(milliseconds: 200),
      ),
    },
  );
}
```

## Async Testing Patterns

Testing asynchronous operations requires special consideration to ensure reliable and deterministic tests.

### Testing Async State Updates

```dart
test('should handle async state updates', () async {
  // Arrange
  final stateManager = AsyncTodoStateManager();
  final states = <AsyncTodoState>[];
  final subscription = stateManager.stream.listen(states.add);

  // Act
  await stateManager.loadTodos();

  // Assert
  expect(states.length, greaterThanOrEqualTo(2)); // Loading + Loaded states
  expect(states.first.isLoading, isTrue);
  expect(states.last.isLoading, isFalse);
  expect(states.last.todos, isNotEmpty);

  // Cleanup
  await subscription.cancel();
  stateManager.dispose();
});
```

### Testing Error Handling

```dart
test('should handle async errors gracefully', () async {
  // Arrange
  final stateManager = AsyncTodoStateManager();
  final errorReporter = TestErrorReporter();
  stateManager.setErrorReporter(errorReporter);

  // Simulate network failure
  stateManager.simulateNetworkError(true);

  // Act
  await stateManager.loadTodos();

  // Assert
  expect(stateManager.state.hasError, isTrue);
  expect(stateManager.state.error, isNotNull);
  expect(errorReporter.reportedErrors.length, equals(1));
});
```

### Testing Timeouts and Cancellation

```dart
test('should handle operation timeouts', () async {
  // Arrange
  final stateManager = AsyncTodoStateManager();
  
  // Act & Assert
  await expectLater(
    stateManager.loadTodosWithTimeout(const Duration(milliseconds: 100)),
    throwsA(isA<TimeoutException>()),
  );
  
  expect(stateManager.state.isLoading, isFalse);
});

test('should support operation cancellation', () async {
  // Arrange
  final stateManager = AsyncTodoStateManager();
  
  // Act
  final future = stateManager.loadTodos();
  stateManager.cancelCurrentOperation();
  
  // Assert
  await expectLater(future, throwsA(isA<OperationCancelledException>()));
});
```

## Test Data Management

Effective test data management ensures consistent and realistic test scenarios.

### Using TestDataFactory

```dart
void main() {
  group('Test Data Factory', () {
    late TestDataFactory dataFactory;

    setUp(() {
      dataFactory = DefaultTestDataFactory();
    });

    test('should create realistic test data', () {
      // Act
      final user = dataFactory.create<User>();
      final todos = dataFactory.createList<Todo>(5);

      // Assert
      expect(user.name, isNotEmpty);
      expect(user.email, contains('@'));
      expect(todos.length, equals(5));
      expect(todos.every((todo) => todo.title.isNotEmpty), isTrue);
    });

    test('should support custom data generation', () {
      // Arrange
      dataFactory.registerFactory<User>((overrides) => User(
        id: overrides?['id'] as String? ?? 'test-user',
        name: overrides?['name'] as String? ?? 'Test User',
        email: overrides?['email'] as String? ?? 'test@example.com',
      ));

      // Act
      final user = dataFactory.create<User>(
        overrides: {'name': 'Custom Name'},
      );

      // Assert
      expect(user.name, equals('Custom Name'));
      expect(user.email, equals('test@example.com'));
    });

    test('should create related objects', () {
      // Act
      final related = dataFactory.createRelatedObjects(
        [User, Todo, Project],
        relationships: {
          'user_id': 'user-123',
          'project_id': 'project-456',
        },
      );

      // Assert
      expect(related.containsKey('User'), isTrue);
      expect(related.containsKey('Todo'), isTrue);
      expect(related.containsKey('Project'), isTrue);
      expect(related['user_id'], equals('user-123'));
    });
  });
}
```

### Deterministic Test Data

```dart
test('should generate deterministic data with seeds', () {
  // Arrange
  const seed = 12345;

  // Act
  final first = dataFactory.create<Todo>(seed: seed);
  final second = dataFactory.create<Todo>(seed: seed);

  // Assert
  expect(first.title, equals(second.title));
  expect(first.id, equals(second.id));
  expect(first.createdAt, equals(second.createdAt));
});
```

## API Mocking Strategies

Testing applications that interact with external APIs requires effective mocking strategies.

### HTTP Client Mocking

```dart
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([http.Client])
void main() {
  group('API Service Tests', () {
    late MockClient mockClient;
    late TodoApiService apiService;
    late TestDataFactory dataFactory;

    setUp(() {
      mockClient = MockClient();
      apiService = TodoApiService(client: mockClient);
      dataFactory = DefaultTestDataFactory();
    });

    test('should fetch todos successfully', () async {
      // Arrange
      final mockTodos = dataFactory.createList<Todo>(3);
      final mockResponse = http.Response(
        jsonEncode(mockTodos.map((t) => t.toJson()).toList()),
        200,
        headers: {'content-type': 'application/json'},
      );

      when(mockClient.get(any)).thenAnswer((_) async => mockResponse);

      // Act
      final todos = await apiService.fetchTodos();

      // Assert
      expect(todos.length, equals(3));
      verify(mockClient.get(Uri.parse('${apiService.baseUrl}/todos')));
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      // Act & Assert
      await expectLater(
        apiService.fetchTodos(),
        throwsA(isA<ApiException>()),
      );
    });

    test('should handle network timeouts', () async {
      // Arrange
      when(mockClient.get(any)).thenThrow(
        const SocketException('Network unreachable'),
      );

      // Act & Assert
      await expectLater(
        apiService.fetchTodos(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

### GraphQL Mocking

```dart
test('should handle GraphQL queries', () async {
  // Arrange
  final mockGraphQLClient = MockGraphQLClient();
  final todoService = GraphQLTodoService(client: mockGraphQLClient);
  
  final mockResult = QueryResult(
    data: {
      'todos': dataFactory.createList<Map<String, dynamic>>(2),
    },
    loading: false,
    hasException: false,
  );

  when(mockGraphQLClient.query(any)).thenAnswer((_) async => mockResult);

  // Act
  final todos = await todoService.fetchTodos();

  // Assert
  expect(todos.length, equals(2));
  verify(mockGraphQLClient.query(any));
});
```

### WebSocket Mocking

```dart
test('should handle real-time updates', () async {
  // Arrange
  final mockWebSocket = MockWebSocketChannel();
  final realtimeService = RealtimeTodoService(webSocket: mockWebSocket);
  
  final updates = <TodoUpdate>[];
  realtimeService.updates.listen(updates.add);

  // Act
  mockWebSocket.simulateMessage({
    'type': 'todo_added',
    'data': dataFactory.create<Todo>().toJson(),
  });

  await Future.delayed(const Duration(milliseconds: 100));

  // Assert
  expect(updates.length, equals(1));
  expect(updates.first.type, equals(TodoUpdateType.added));
});
```

## Performance Testing

Testing performance characteristics ensures your application meets performance requirements.

### State Manager Performance

```dart
test('should handle large state updates efficiently', () async {
  // Arrange
  final stateManager = TodoStateManager(
    initialState: const TodoState(todos: []),
  );
  
  final stopwatch = Stopwatch()..start();

  // Act - Add 1000 todos
  for (int i = 0; i < 1000; i++) {
    stateManager.update((current) => current.addTodo('Todo $i'));
  }

  stopwatch.stop();

  // Assert
  expect(stateManager.state.todos.length, equals(1000));
  expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
  
  stateManager.dispose();
});
```

### Memory Usage Testing

```dart
test('should not leak memory with frequent updates', () async {
  // Arrange
  final initialMemory = ProcessInfo.currentRss;
  final stateManagers = <TodoStateManager>[];

  // Act - Create and dispose many state managers
  for (int i = 0; i < 100; i++) {
    final manager = TodoStateManager(
      initialState: const TodoState(todos: []),
    );
    
    // Perform some operations
    manager.update((current) => current.addTodo('Test $i'));
    
    stateManagers.add(manager);
  }

  // Dispose all managers
  for (final manager in stateManagers) {
    manager.dispose();
  }

  // Force garbage collection
  await Future.delayed(const Duration(milliseconds: 100));

  // Assert
  final finalMemory = ProcessInfo.currentRss;
  final memoryIncrease = finalMemory - initialMemory;
  
  expect(memoryIncrease, lessThan(10 * 1024 * 1024)); // Less than 10MB
});
```

## Troubleshooting

### Common Testing Issues

#### Test Isolation Problems

```dart
// Problem: Tests affecting each other
test('first test', () {
  GlobalState.instance.setValue('test');
  expect(GlobalState.instance.getValue(), equals('test'));
});

test('second test', () {
  // This might fail if first test didn't clean up
  expect(GlobalState.instance.getValue(), isNull);
});

// Solution: Proper setup and teardown
setUp(() {
  GlobalState.instance.reset();
});

tearDown(() {
  GlobalState.instance.reset();
});
```

#### Async Test Timing Issues

```dart
// Problem: Race conditions in async tests
test('async operation', () async {
  final future = someAsyncOperation();
  // Don't do this - might not wait long enough
  await Future.delayed(const Duration(milliseconds: 100));
  expect(result, equals(expectedValue));
});

// Solution: Proper async handling
test('async operation', () async {
  final result = await someAsyncOperation();
  expect(result, equals(expectedValue));
});
```

#### Mock Configuration Issues

```dart
// Problem: Mocks not behaving as expected
test('mock test', () {
  final mock = MockService();
  // This won't work without proper setup
  final result = mock.getData();
  expect(result, isNotNull);
});

// Solution: Proper mock configuration
test('mock test', () {
  final mock = MockService();
  when(mock.getData()).thenReturn('test data');
  
  final result = mock.getData();
  expect(result, equals('test data'));
});
```

### Debugging Test Failures

#### Enable Debug Logging

```dart
setUp(() {
  // Enable debug logging for tests
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
});
```

#### Use Test-Specific Error Reporting

```dart
class TestErrorReporter extends ErrorReporter {
  final List<ErrorReport> reportedErrors = [];

  @override
  void reportError(ErrorReport error) {
    reportedErrors.add(error);
    print('Test Error: ${error.message}');
  }
}
```

### Performance Debugging

```dart
test('performance debugging', () async {
  final stopwatch = Stopwatch()..start();
  
  // Your test code here
  await someOperation();
  
  stopwatch.stop();
  print('Operation took: ${stopwatch.elapsedMilliseconds}ms');
  
  // Add assertions about performance
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));
});
```

## Next Steps

After mastering the testing utilities:

1. **Explore Advanced Testing**: Learn about [Performance Monitoring](performance.md) integration
2. **State Management Testing**: Deep dive into [State Management](state_management.md) testing patterns
3. **Navigation Testing**: Advanced [Navigation](navigation.md) testing scenarios
4. **API Integration**: Complete [API Reference](api_reference.md) for testing utilities

## Related Topics

- [State Management Guide](state_management.md) - Testing state management patterns, including unit testing state classes and integration testing with UI components
- [Navigation Guide](navigation.md) - Testing navigation flows, route guards, and deep linking functionality
- [Performance Guide](performance.md) - Performance testing strategies, benchmarking, and monitoring integration
- [API Reference](api_reference.md) - Complete testing API documentation with detailed method signatures and examples
- [Troubleshooting](troubleshooting.md) - Common testing issues and their solutions, including debugging techniques

The testing utilities in the Flutter Productivity Toolkit provide a comprehensive foundation for building reliable, well-tested Flutter applications. By following these patterns and best practices, you can ensure your applications are robust, maintainable, and perform well under various conditions.