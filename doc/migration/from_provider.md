# Migrating from Provider

This guide helps you migrate from the Provider package to the Flutter Developer Productivity Toolkit's state management system.

## Overview

The toolkit's state management provides similar functionality to Provider but with additional features like automatic code generation, built-in persistence, and enhanced debugging capabilities.

## Key Differences

| Feature | Provider | Flutter Dev Toolkit |
|---------|----------|-------------------|
| Setup | Manual provider registration | Automatic with annotations |
| State Updates | Manual notifyListeners() | Automatic reactive updates |
| Persistence | Manual implementation | Built-in with @GenerateState |
| Type Safety | Runtime checks | Compile-time generation |
| Debugging | Basic debugging | Advanced state timeline |
| Testing | Manual mocking | Automatic mock generation |

## Migration Steps

### Step 1: Replace Dependencies

**Before (Provider):**
```yaml
dependencies:
  provider: ^6.0.0
```

**After (Toolkit):**
```yaml
dependencies:
  flutter_dev_toolkit: ^0.1.0
dev_dependencies:
  build_runner: ^2.4.7
```

### Step 2: Convert ChangeNotifier Classes

**Before (Provider):**
```dart
class CounterNotifier extends ChangeNotifier {
  int _count = 0;
  
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
  
  void decrement() {
    _count--;
    notifyListeners();
  }
}
```

**After (Toolkit):**
```dart
@GenerateState(persist: true)
class CounterState {
  final int count;
  
  const CounterState({this.count = 0});
  
  CounterState copyWith({int? count}) {
    return CounterState(count: count ?? this.count);
  }
  
  // Actions are defined as methods that return new state
  CounterState increment() => copyWith(count: count + 1);
  CounterState decrement() => copyWith(count: count - 1);
}

// Generated: CounterStateManager will be created automatically
```

### Step 3: Update Provider Registration

**Before (Provider):**
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterNotifier()),
        ChangeNotifierProvider(create: (_) => UserNotifier()),
      ],
      child: MyApp(),
    ),
  );
}
```

**After (Toolkit):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = ToolkitConfiguration.development();
  await config.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}
```

### Step 4: Update Widget Consumption

**Before (Provider):**
```dart
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CounterNotifier>(
      builder: (context, counter, child) {
        return Column(
          children: [
            Text('Count: ${counter.count}'),
            ElevatedButton(
              onPressed: counter.increment,
              child: Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

**After (Toolkit):**
```dart
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stateManager = context.state<CounterStateManager>();
    
    return StreamBuilder<CounterState>(
      stream: stateManager.stream,
      initialData: stateManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        return Column(
          children: [
            Text('Count: ${state.count}'),
            ElevatedButton(
              onPressed: () => stateManager.update((current) => current.increment()),
              child: Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

### Step 5: Handle Complex State Updates

**Before (Provider):**
```dart
class TodoNotifier extends ChangeNotifier {
  List<Todo> _todos = [];
  
  List<Todo> get todos => _todos;
  
  void addTodo(String title) {
    _todos.add(Todo(id: DateTime.now().toString(), title: title));
    notifyListeners();
  }
  
  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(completed: !_todos[index].completed);
      notifyListeners();
    }
  }
}
```

**After (Toolkit):**
```dart
@GenerateState(persist: true, storageKey: 'todos')
class TodoState {
  final List<Todo> todos;
  
  const TodoState({this.todos = const []});
  
  TodoState copyWith({List<Todo>? todos}) {
    return TodoState(todos: todos ?? this.todos);
  }
  
  TodoState addTodo(String title) {
    final newTodo = Todo(
      id: DateTime.now().toString(),
      title: title,
      completed: false,
    );
    return copyWith(todos: [...todos, newTodo]);
  }
  
  TodoState toggleTodo(String id) {
    final updatedTodos = todos.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(completed: !todo.completed);
      }
      return todo;
    }).toList();
    
    return copyWith(todos: updatedTodos);
  }
}

@GenerateModel()
class Todo {
  final String id;
  final String title;
  final bool completed;
  
  const Todo({
    required this.id,
    required this.title,
    this.completed = false,
  });
}
```

## Advanced Migration Scenarios

### Selector Pattern Migration

**Before (Provider with Selector):**
```dart
Selector<CounterNotifier, int>(
  selector: (context, counter) => counter.count,
  builder: (context, count, child) {
    return Text('Count: $count');
  },
)
```

**After (Toolkit with Stream Transformation):**
```dart
StreamBuilder<int>(
  stream: stateManager.stream.map((state) => state.count).distinct(),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    return Text('Count: $count');
  },
)
```

### ProxyProvider Migration

**Before (Provider with ProxyProvider):**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthNotifier()),
    ChangeNotifierProxyProvider<AuthNotifier, UserNotifier>(
      create: (_) => UserNotifier(),
      update: (_, auth, user) => user!..updateAuth(auth),
    ),
  ],
  child: MyApp(),
)
```

**After (Toolkit with Dependency Injection):**
```dart
@GenerateState()
class AuthState {
  final User? user;
  final bool isAuthenticated;
  
  const AuthState({this.user, this.isAuthenticated = false});
}

@GenerateState()
class UserState {
  final List<User> users;
  final User? currentUser;
  
  const UserState({this.users = const [], this.currentUser});
  
  // State can depend on other state managers
  UserState updateFromAuth(AuthState authState) {
    return copyWith(currentUser: authState.user);
  }
}

// In your widget or service
class UserService {
  final UserStateManager userManager;
  final AuthStateManager authManager;
  
  UserService(this.userManager, this.authManager) {
    // Listen to auth changes and update user state
    authManager.stream.listen((authState) {
      userManager.update((current) => current.updateFromAuth(authState));
    });
  }
}
```

## Testing Migration

### Before (Provider Testing)
```dart
testWidgets('counter increments', (tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => CounterNotifier(),
      child: MaterialApp(home: CounterWidget()),
    ),
  );
  
  expect(find.text('Count: 0'), findsOneWidget);
  
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  expect(find.text('Count: 1'), findsOneWidget);
});
```

### After (Toolkit Testing)
```dart
testWidgets('counter increments', (tester) async {
  final testEnv = await TestHelper().setupTestEnvironment();
  final mockState = testEnv.helper.createMockState<CounterStateManager>();
  
  await testEnv.helper.pumpAndSettle(
    tester,
    CounterWidget(),
    providers: [mockState],
  );
  
  expect(find.text('Count: 0'), findsOneWidget);
  
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  expect(find.text('Count: 1'), findsOneWidget);
});
```

## Performance Considerations

### Provider Performance Issues
- Manual optimization with Selector
- Potential unnecessary rebuilds
- Manual state management

### Toolkit Advantages
- Automatic selective updates
- Built-in performance monitoring
- Optimized state diffing

**Example of automatic optimization:**
```dart
// Toolkit automatically optimizes this
StreamBuilder<CounterState>(
  stream: stateManager.stream,
  builder: (context, snapshot) {
    // Only rebuilds when state actually changes
    return Text('Count: ${snapshot.data?.count ?? 0}');
  },
)
```

## Common Migration Pitfalls

### 1. Forgetting to Run Code Generation
```bash
# Always run after adding @GenerateState annotations
flutter packages pub run build_runner build
```

### 2. Not Disposing State Managers
```dart
// In StatefulWidget
@override
void dispose() {
  stateManager.dispose(); // Important!
  super.dispose();
}
```

### 3. Mixing Provider and Toolkit
```dart
// Don't mix - choose one approach
// Bad: Using both Provider and Toolkit in same widget tree
```

## Migration Checklist

- [ ] Replace Provider dependency with Flutter Dev Toolkit
- [ ] Convert ChangeNotifier classes to state classes with @GenerateState
- [ ] Run code generation to create state managers
- [ ] Update widget consumption from Consumer to StreamBuilder
- [ ] Replace MultiProvider with toolkit configuration
- [ ] Update tests to use TestHelper
- [ ] Remove Provider-specific code (notifyListeners, etc.)
- [ ] Test all functionality works as expected
- [ ] Add persistence configuration if needed
- [ ] Enable performance monitoring for optimization

## Benefits After Migration

1. **Reduced Boilerplate**: No more manual notifyListeners() calls
2. **Type Safety**: Compile-time generation prevents runtime errors
3. **Built-in Persistence**: Automatic state saving/loading
4. **Better Testing**: Automatic mock generation
5. **Performance Monitoring**: Real-time performance insights
6. **Enhanced Debugging**: State timeline and transition history

## Need Help?

If you encounter issues during migration:

1. Check the [Troubleshooting Guide](../troubleshooting.md)
2. Review [API Reference](../api_reference.md)
3. See complete examples in the [examples directory](../../example/)
4. Ask questions in [GitHub Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)