# Quick Start Guide

Get up and running with the Flutter Developer Productivity Toolkit in minutes. This guide walks you through creating a simple todo app that demonstrates the core features.

## Prerequisites

- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher
- Basic knowledge of Flutter development

## Installation

### 1. Add Dependencies

Add the toolkit to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_productivity_toolkit: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.7
  flutter_test:
    sdk: flutter
```

### 2. Install Packages

```bash
flutter pub get
```

## Creating Your First App

Let's build a simple todo app that showcases state management, navigation, and testing features.

### Step 1: Initialize the Toolkit

Update your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize toolkit with development configuration
  final config = ToolkitConfiguration.development();
  await config.initialize();
  
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodoListScreen(),
    );
  }
}
```

### Step 2: Define Your State

Create `lib/models/todo_state.dart`:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

@GenerateModel()
class Todo {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  
  const Todo({
    required this.id,
    required this.title,
    this.completed = false,
    required this.createdAt,
  });
}

@GenerateState(persist: true, storageKey: 'todos')
class TodoState {
  final List<Todo> todos;
  final String filter; // 'all', 'active', 'completed'
  
  const TodoState({
    this.todos = const [],
    this.filter = 'all',
  });
  
  TodoState copyWith({
    List<Todo>? todos,
    String? filter,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
    );
  }
  
  // State actions
  TodoState addTodo(String title) {
    if (title.trim().isEmpty) return this;
    
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      createdAt: DateTime.now(),
    );
    
    return copyWith(todos: [...todos, newTodo]);
  }
  
  TodoState toggleTodo(String id) {
    final updatedTodos = todos.map((todo) {
      if (todo.id == id) {
        return Todo(
          id: todo.id,
          title: todo.title,
          completed: !todo.completed,
          createdAt: todo.createdAt,
        );
      }
      return todo;
    }).toList();
    
    return copyWith(todos: updatedTodos);
  }
  
  TodoState deleteTodo(String id) {
    final updatedTodos = todos.where((todo) => todo.id != id).toList();
    return copyWith(todos: updatedTodos);
  }
  
  TodoState setFilter(String newFilter) {
    return copyWith(filter: newFilter);
  }
  
  // Computed properties
  List<Todo> get filteredTodos {
    switch (filter) {
      case 'active':
        return todos.where((todo) => !todo.completed).toList();
      case 'completed':
        return todos.where((todo) => todo.completed).toList();
      default:
        return todos;
    }
  }
  
  int get activeCount => todos.where((todo) => !todo.completed).length;
  int get completedCount => todos.where((todo) => todo.completed).length;
}
```

### Step 3: Generate Code

Run code generation to create the state manager:

```bash
flutter packages pub run build_runner build
```

This creates `todo_state.g.dart` with the `TodoStateManager` class.

### Step 4: Create the UI

Create `lib/screens/todo_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';
import '../models/todo_state.dart';

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late TodoStateManager stateManager;
  final TextEditingController _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Get or create the state manager
    stateManager = StateProvider.instance.provide<TodoStateManager>();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    stateManager.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              // Show performance metrics
              PerformanceMonitor.instance.showMetrics(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAddTodoSection(),
          _buildFilterSection(),
          Expanded(child: _buildTodoList()),
          _buildStatsSection(),
        ],
      ),
    );
  }
  
  Widget _buildAddTodoSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add a new todo...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _addTodo,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _addTodo(_controller.text),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return StreamBuilder<TodoState>(
      stream: stateManager.stream,
      initialData: stateManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('All', 'all', state.filter),
              _buildFilterChip('Active', 'active', state.filter),
              _buildFilterChip('Completed', 'completed', state.filter),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFilterChip(String label, String value, String currentFilter) {
    return FilterChip(
      label: Text(label),
      selected: currentFilter == value,
      onSelected: (selected) {
        if (selected) {
          stateManager.update((current) => current.setFilter(value));
        }
      },
    );
  }
  
  Widget _buildTodoList() {
    return StreamBuilder<TodoState>(
      stream: stateManager.stream,
      initialData: stateManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        final todos = state.filteredTodos;
        
        if (todos.isEmpty) {
          return Center(
            child: Text(
              'No todos yet. Add one above!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return _buildTodoItem(todo);
          },
        );
      },
    );
  }
  
  Widget _buildTodoItem(Todo todo) {
    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (_) {
          stateManager.update((current) => current.toggleTodo(todo.id));
        },
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        'Created: ${todo.createdAt.toString().split('.')[0]}',
        style: TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          stateManager.update((current) => current.deleteTodo(todo.id));
        },
      ),
    );
  }
  
  Widget _buildStatsSection() {
    return StreamBuilder<TodoState>(
      stream: stateManager.stream,
      initialData: stateManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        return Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', state.todos.length.toString()),
              _buildStatItem('Active', state.activeCount.toString()),
              _buildStatItem('Completed', state.completedCount.toString()),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
  
  void _addTodo(String title) {
    if (title.trim().isNotEmpty) {
      stateManager.update((current) => current.addTodo(title));
      _controller.clear();
    }
  }
}
```

### Step 5: Add Navigation (Optional)

Create a details screen with navigation. First, define the route:

```dart
// lib/routes/todo_routes.dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

@GenerateRoute('/todo/:id')
class TodoDetailRoute {
  final String todoId;
  
  const TodoDetailRoute({required this.todoId});
}
```

Create the detail screen:

```dart
// lib/screens/todo_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';
import '../models/todo_state.dart';
import '../routes/todo_routes.dart';

class TodoDetailScreen extends StatelessWidget {
  final TodoDetailRoute route;
  
  const TodoDetailScreen({required this.route});
  
  @override
  Widget build(BuildContext context) {
    final stateManager = StateProvider.instance.provide<TodoStateManager>();
    
    return StreamBuilder<TodoState>(
      stream: stateManager.stream,
      initialData: stateManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        final todo = state.todos.firstWhere(
          (t) => t.id == route.todoId,
          orElse: () => Todo(
            id: '',
            title: 'Not found',
            createdAt: DateTime.now(),
          ),
        );
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Todo Details'),
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(todo.title),
                SizedBox(height: 16),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(todo.completed ? 'Completed' : 'Active'),
                SizedBox(height: 16),
                Text(
                  'Created',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(todo.createdAt.toString()),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### Step 6: Add Testing

Create `test/todo_app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';
import '../lib/models/todo_state.dart';
import '../lib/screens/todo_list_screen.dart';

void main() {
  group('Todo App Tests', () {
    late TestEnvironment testEnv;
    late MockStateManager<TodoState> mockTodoState;
    
    setUp(() async {
      testEnv = await TestHelper().setupTestEnvironment();
      mockTodoState = testEnv.helper.createMockState<TodoStateManager>();
    });
    
    tearDown(() async {
      await testEnv.dispose();
    });
    
    testWidgets('should display empty state initially', (tester) async {
      mockTodoState.setupInitialState(TodoState());
      
      await testEnv.helper.pumpAndSettle(
        tester,
        TodoListScreen(),
        providers: [mockTodoState],
      );
      
      expect(find.text('No todos yet. Add one above!'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3)); // Total, Active, Completed
    });
    
    testWidgets('should add new todo', (tester) async {
      mockTodoState.setupInitialState(TodoState());
      
      await testEnv.helper.pumpAndSettle(
        tester,
        TodoListScreen(),
        providers: [mockTodoState],
      );
      
      // Enter todo text
      await tester.enterText(find.byType(TextField), 'Buy groceries');
      await tester.tap(find.text('Add'));
      await tester.pump();
      
      // Verify state was updated
      expect(mockTodoState.state.todos.length, equals(1));
      expect(mockTodoState.state.todos.first.title, equals('Buy groceries'));
    });
    
    testWidgets('should toggle todo completion', (tester) async {
      final initialState = TodoState().addTodo('Test todo');
      mockTodoState.setupInitialState(initialState);
      
      await testEnv.helper.pumpAndSettle(
        tester,
        TodoListScreen(),
        providers: [mockTodoState],
      );
      
      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      
      // Verify todo was toggled
      expect(mockTodoState.state.todos.first.completed, isTrue);
    });
    
    testWidgets('should filter todos correctly', (tester) async {
      final initialState = TodoState()
          .addTodo('Active todo')
          .addTodo('Completed todo');
      
      // Mark second todo as completed
      final stateWithCompleted = initialState.toggleTodo(
        initialState.todos.last.id,
      );
      
      mockTodoState.setupInitialState(stateWithCompleted);
      
      await testEnv.helper.pumpAndSettle(
        tester,
        TodoListScreen(),
        providers: [mockTodoState],
      );
      
      // Initially shows all todos
      expect(find.text('Active todo'), findsOneWidget);
      expect(find.text('Completed todo'), findsOneWidget);
      
      // Filter to active only
      await tester.tap(find.text('Active'));
      await tester.pump();
      
      expect(mockTodoState.state.filter, equals('active'));
    });
  });
}
```

### Step 7: Run Your App

```bash
# Generate code first
flutter packages pub run build_runner build

# Run the app
flutter run

# Run tests
flutter test
```

## What You've Built

Congratulations! You've created a fully functional todo app that demonstrates:

### ✅ State Management
- Reactive state updates with automatic UI rebuilds
- Persistent state that survives app restarts
- Type-safe state operations

### ✅ Performance Monitoring
- Real-time performance tracking
- Memory usage monitoring
- Widget rebuild optimization

### ✅ Testing
- Comprehensive test coverage
- Mock state managers for isolated testing
- Test environment setup and teardown

### ✅ Code Generation
- Automatic state manager generation
- Reduced boilerplate code
- Type-safe data models

## Next Steps

Now that you have a working app, explore more features:

1. **Add Navigation**: Create multiple screens with type-safe routing
2. **Performance Optimization**: Use the performance monitor to identify bottlenecks
3. **Advanced State Management**: Implement complex state relationships
4. **API Integration**: Generate API clients from OpenAPI specifications
5. **Enhanced Testing**: Add property-based tests for comprehensive coverage

## Key Concepts Learned

### State Management Pattern
```dart
// 1. Define state with @GenerateState
@GenerateState(persist: true)
class MyState { /* ... */ }

// 2. Use generated state manager
final manager = StateProvider.instance.provide<MyStateManager>();

// 3. Update state immutably
manager.update((current) => current.copyWith(field: newValue));

// 4. Listen to changes
StreamBuilder<MyState>(
  stream: manager.stream,
  builder: (context, snapshot) { /* ... */ },
)
```

### Testing Pattern
```dart
// 1. Setup test environment
final testEnv = await TestHelper().setupTestEnvironment();

// 2. Create mock state
final mockState = testEnv.helper.createMockState<MyStateManager>();

// 3. Test with mocks
await testEnv.helper.pumpAndSettle(tester, MyWidget(), providers: [mockState]);
```

## Troubleshooting

If you encounter issues:

1. **Code generation not working**: Run `flutter packages pub run build_runner clean` then `flutter packages pub run build_runner build`
2. **State not persisting**: Ensure you have the `persist: true` parameter in `@GenerateState`
3. **Performance issues**: Check the performance monitor for insights
4. **Tests failing**: Verify mock setup and test environment initialization

## Resources

- [Complete API Reference](api_reference.md) - Comprehensive API documentation for all toolkit components
- [State Management Deep Dive](state_management.md) - Advanced state management patterns, persistence, and performance optimization
- [Navigation Guide](navigation.md) - Type-safe routing, deep linking, and complex navigation flows
- [Testing Best Practices](testing.md) - Unit testing, widget testing, property-based testing, and integration testing
- [Performance Optimization](performance.md) - Performance monitoring, debugging, and optimization techniques
- [Example Applications](../example/README.md) - Complete example applications demonstrating toolkit features

Ready to build more complex applications? Check out our [comprehensive examples](../example/) and [advanced guides](README.md)!