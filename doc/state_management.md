# State Management Guide

The Flutter Productivity Toolkit provides a powerful, reactive state management system that combines the simplicity of immutable state with advanced features like persistence, debugging, and performance optimization. This guide covers everything from basic concepts to advanced patterns.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Basic Usage](#basic-usage)
3. [Advanced State Patterns](#advanced-state-patterns)
4. [State Persistence](#state-persistence)
5. [Async Operations](#async-operations)
6. [Performance Optimization](#performance-optimization)
7. [Debugging and Development](#debugging-and-development)
8. [Integration with Flutter](#integration-with-flutter)
9. [Testing State Management](#testing-state-management)
10. [Troubleshooting](#troubleshooting)

## Core Concepts

### State Manager Architecture

The toolkit's state management is built around several key components:

- **StateManager**: Abstract base class for all state managers
- **ReactiveStateManager**: Concrete implementation with reactive updates
- **StateProvider**: Dependency injection container for state managers
- **StateConfiguration**: Configuration for persistence, debugging, and optimization
- **StateDebugger**: Development tools for state inspection and debugging

### Immutable State Pattern

All state in the toolkit follows an immutable pattern:

```dart
// ❌ Mutable state (avoid)
class BadState {
  List<String> items = [];
  
  void addItem(String item) {
    items.add(item); // Mutates existing state
  }
}

// ✅ Immutable state (recommended)
class GoodState {
  final List<String> items;
  
  const GoodState({this.items = const []});
  
  GoodState addItem(String item) {
    return GoodState(items: [...items, item]); // Returns new state
  }
}
```

### Reactive Updates

State changes automatically trigger UI updates through streams:

```dart
// State manager provides a stream of state changes
Stream<MyState> get stream => stateManager.stream;

// UI listens to state changes
StreamBuilder<MyState>(
  stream: stateManager.stream,
  builder: (context, snapshot) {
    final state = snapshot.data!;
    return Text('Count: ${state.count}');
  },
)
```

## Basic Usage

### Creating a State Class

Define your state as an immutable class with a `copyWith` method:

```dart
class CounterState {
  final int count;
  final DateTime lastUpdated;
  final bool isLoading;
  
  const CounterState({
    this.count = 0,
    required this.lastUpdated,
    this.isLoading = false,
  });
  
  CounterState copyWith({
    int? count,
    DateTime? lastUpdated,
    bool? isLoading,
  }) {
    return CounterState(
      count: count ?? this.count,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounterState &&
          count == other.count &&
          lastUpdated == other.lastUpdated &&
          isLoading == other.isLoading;
  
  @override
  int get hashCode => count.hashCode ^ lastUpdated.hashCode ^ isLoading.hashCode;
}
```

### Creating a State Manager

Create and configure a state manager:

```dart
class CounterManager {
  late final ReactiveStateManager<CounterState> _stateManager;
  
  CounterManager({ErrorReporter? errorReporter}) {
    _stateManager = ReactiveStateManager<CounterState>(
      CounterState(lastUpdated: DateTime.now()),
      config: const StateConfiguration(
        enableDebugging: true,
        enablePersistence: true,
        storageKey: 'counter_state',
      ),
      errorReporter: errorReporter,
    );
  }
  
  // Expose state and stream
  CounterState get state => _stateManager.state;
  Stream<CounterState> get stream => _stateManager.stream;
  
  // State operations
  void increment() {
    _stateManager.update((current) => current.copyWith(
      count: current.count + 1,
      lastUpdated: DateTime.now(),
    ));
  }
  
  void decrement() {
    _stateManager.update((current) => current.copyWith(
      count: current.count - 1,
      lastUpdated: DateTime.now(),
    ));
  }
  
  void reset() {
    _stateManager.update((current) => CounterState(
      lastUpdated: DateTime.now(),
    ));
  }
  
  void dispose() {
    _stateManager.dispose();
  }
}
```

### Using State in Widgets

Integrate state managers with your Flutter widgets:

```dart
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late CounterManager _counterManager;
  
  @override
  void initState() {
    super.initState();
    _counterManager = CounterManager();
  }
  
  @override
  void dispose() {
    _counterManager.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CounterState>(
      stream: _counterManager.stream,
      initialData: _counterManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        return Column(
          children: [
            Text('Count: ${state.count}'),
            Text('Last updated: ${state.lastUpdated}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _counterManager.decrement,
                  child: Text('-'),
                ),
                ElevatedButton(
                  onPressed: _counterManager.increment,
                  child: Text('+'),
                ),
                ElevatedButton(
                  onPressed: _counterManager.reset,
                  child: Text('Reset'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

## Advanced State Patterns

### Nested State Management

Handle complex state structures with nested state managers:

```dart
// User profile state
class UserProfileState {
  final String name;
  final String email;
  final UserPreferences preferences;
  
  const UserProfileState({
    required this.name,
    required this.email,
    required this.preferences,
  });
  
  UserProfileState copyWith({
    String? name,
    String? email,
    UserPreferences? preferences,
  }) {
    return UserProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      preferences: preferences ?? this.preferences,
    );
  }
}

// Nested preferences state
class UserPreferences {
  final String theme;
  final bool notifications;
  final String language;
  
  const UserPreferences({
    required this.theme,
    required this.notifications,
    required this.language,
  });
  
  UserPreferences copyWith({
    String? theme,
    bool? notifications,
    String? language,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
    );
  }
}

// Manager with nested state operations
class UserProfileManager {
  late final ReactiveStateManager<UserProfileState> _stateManager;
  
  UserProfileManager() {
    _stateManager = ReactiveStateManager<UserProfileState>(
      const UserProfileState(
        name: '',
        email: '',
        preferences: UserPreferences(
          theme: 'light',
          notifications: true,
          language: 'en',
        ),
      ),
      config: const StateConfiguration(
        enablePersistence: true,
        storageKey: 'user_profile',
      ),
    );
  }
  
  UserProfileState get state => _stateManager.state;
  Stream<UserProfileState> get stream => _stateManager.stream;
  
  // Update user info
  void updateProfile({String? name, String? email}) {
    _stateManager.update((current) => current.copyWith(
      name: name,
      email: email,
    ));
  }
  
  // Update nested preferences
  void updatePreferences({
    String? theme,
    bool? notifications,
    String? language,
  }) {
    _stateManager.update((current) => current.copyWith(
      preferences: current.preferences.copyWith(
        theme: theme,
        notifications: notifications,
        language: language,
      ),
    ));
  }
  
  void dispose() {
    _stateManager.dispose();
  }
}
```

### State Composition

Combine multiple state managers for complex applications:

```dart
class AppStateManager {
  final UserProfileManager userManager;
  final CounterManager counterManager;
  final TodoListManager todoManager;
  
  AppStateManager({
    required this.userManager,
    required this.counterManager,
    required this.todoManager,
  });
  
  // Combined state stream
  Stream<AppState> get combinedState => Rx.combineLatest3(
    userManager.stream,
    counterManager.stream,
    todoManager.stream,
    (user, counter, todos) => AppState(
      user: user,
      counter: counter,
      todos: todos,
    ),
  );
  
  void dispose() {
    userManager.dispose();
    counterManager.dispose();
    todoManager.dispose();
  }
}

class AppState {
  final UserProfileState user;
  final CounterState counter;
  final TodoListState todos;
  
  const AppState({
    required this.user,
    required this.counter,
    required this.todos,
  });
}
```

### State Validation

Implement validation logic in your state updates:

```dart
class ValidatedFormState {
  final String email;
  final String password;
  final Map<String, String> errors;
  
  const ValidatedFormState({
    this.email = '',
    this.password = '',
    this.errors = const {},
  });
  
  ValidatedFormState copyWith({
    String? email,
    String? password,
    Map<String, String>? errors,
  }) {
    return ValidatedFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      errors: errors ?? this.errors,
    );
  }
  
  // Validation logic
  ValidatedFormState validate() {
    final newErrors = <String, String>{};
    
    if (email.isEmpty) {
      newErrors['email'] = 'Email is required';
    } else if (!_isValidEmail(email)) {
      newErrors['email'] = 'Invalid email format';
    }
    
    if (password.isEmpty) {
      newErrors['password'] = 'Password is required';
    } else if (password.length < 8) {
      newErrors['password'] = 'Password must be at least 8 characters';
    }
    
    return copyWith(errors: newErrors);
  }
  
  bool get isValid => errors.isEmpty;
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

class FormManager {
  late final ReactiveStateManager<ValidatedFormState> _stateManager;
  
  FormManager() {
    _stateManager = ReactiveStateManager<ValidatedFormState>(
      const ValidatedFormState(),
      config: const StateConfiguration(enableDebugging: true),
    );
  }
  
  ValidatedFormState get state => _stateManager.state;
  Stream<ValidatedFormState> get stream => _stateManager.stream;
  
  void updateEmail(String email) {
    _stateManager.update((current) => 
      current.copyWith(email: email).validate()
    );
  }
  
  void updatePassword(String password) {
    _stateManager.update((current) => 
      current.copyWith(password: password).validate()
    );
  }
  
  void dispose() {
    _stateManager.dispose();
  }
}
```

## State Persistence

State persistence allows your application data to survive app restarts and device reboots. The toolkit provides both automatic and manual persistence options. For performance considerations when working with large persistent datasets, see the [Performance Guide](performance.md#large-dataset-handling).

### Automatic Persistence

Enable automatic persistence for state that should survive app restarts:

```dart
final stateManager = ReactiveStateManager<MyState>(
  initialState,
  config: const StateConfiguration(
    enablePersistence: true,
    storageKey: 'my_state_key', // Optional: defaults to type name
  ),
);

// State is automatically persisted on updates
// and restored when the manager is created
```

### Manual Persistence Control

For more control over when state is persisted:

```dart
class PersistentManager {
  late final ReactiveStateManager<MyState> _stateManager;
  
  PersistentManager() {
    _stateManager = ReactiveStateManager<MyState>(
      initialState,
      config: const StateConfiguration(
        enablePersistence: true,
        // Disable auto-persistence
      ),
    );
    
    // Restore state on initialization
    _restoreState();
  }
  
  Future<void> _restoreState() async {
    try {
      await _stateManager.restore();
    } catch (e) {
      // Handle restoration errors
      print('Failed to restore state: $e');
    }
  }
  
  Future<void> saveState() async {
    try {
      await _stateManager.persist();
    } catch (e) {
      // Handle persistence errors
      print('Failed to save state: $e');
    }
  }
  
  // Save state at specific points
  void updateWithSave(MyState Function(MyState) updater) {
    _stateManager.update(updater);
    saveState(); // Manual save
  }
}
```

### Custom Serialization

For complex state objects, implement custom serialization:

```dart
class ComplexState {
  final DateTime timestamp;
  final List<CustomObject> items;
  final Map<String, dynamic> metadata;
  
  const ComplexState({
    required this.timestamp,
    required this.items,
    required this.metadata,
  });
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'metadata': metadata,
    };
  }
  
  // Create from JSON
  factory ComplexState.fromJson(Map<String, dynamic> json) {
    return ComplexState(
      timestamp: DateTime.parse(json['timestamp']),
      items: (json['items'] as List)
          .map((item) => CustomObject.fromJson(item))
          .toList(),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

// Custom state manager with serialization
class CustomSerializationManager extends ReactiveStateManager<ComplexState> {
  CustomSerializationManager(ComplexState initialState)
      : super(initialState, config: const StateConfiguration(
          enablePersistence: true,
        ));
  
  @override
  String _serializeState(ComplexState state) {
    return jsonEncode(state.toJson());
  }
  
  @override
  ComplexState _deserializeState(String serialized) {
    final json = jsonDecode(serialized) as Map<String, dynamic>;
    return ComplexState.fromJson(json);
  }
}
```

## Async Operations

Managing asynchronous operations is crucial for modern applications. The state management system provides patterns for handling loading states, error conditions, and data synchronization. For testing async operations, see the [Testing Guide](testing.md#async-testing-patterns).

### Handling Async State Updates

Manage loading states and async operations:

```dart
class AsyncState<T> {
  final T? data;
  final bool isLoading;
  final String? error;
  
  const AsyncState({
    this.data,
    this.isLoading = false,
    this.error,
  });
  
  AsyncState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
  }) {
    return AsyncState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
  
  // Convenience constructors
  AsyncState<T>.loading() : this(isLoading: true);
  AsyncState<T>.success(T data) : this(data: data);
  AsyncState<T>.error(String error) : this(error: error);
  
  bool get hasData => data != null;
  bool get hasError => error != null;
}

class ApiDataManager {
  late final ReactiveStateManager<AsyncState<List<User>>> _stateManager;
  final ApiService _apiService;
  
  ApiDataManager(this._apiService) {
    _stateManager = ReactiveStateManager<AsyncState<List<User>>>(
      const AsyncState<List<User>>(),
      config: const StateConfiguration(enableDebugging: true),
    );
  }
  
  AsyncState<List<User>> get state => _stateManager.state;
  Stream<AsyncState<List<User>>> get stream => _stateManager.stream;
  
  Future<void> loadUsers() async {
    // Set loading state
    _stateManager.update((current) => current.copyWith(
      isLoading: true,
      error: null,
    ));
    
    try {
      final users = await _apiService.getUsers();
      
      // Set success state
      _stateManager.update((current) => AsyncState<List<User>>.success(users));
    } catch (e) {
      // Set error state
      _stateManager.update((current) => AsyncState<List<User>>.error(e.toString()));
    }
  }
  
  Future<void> refreshUsers() async {
    // Keep existing data while refreshing
    _stateManager.update((current) => current.copyWith(
      isLoading: true,
      error: null,
    ));
    
    try {
      final users = await _apiService.getUsers();
      _stateManager.update((current) => AsyncState<List<User>>.success(users));
    } catch (e) {
      _stateManager.update((current) => current.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  void dispose() {
    _stateManager.dispose();
  }
}
```

### Async State in UI

Handle async states in your widgets:

```dart
class UserListWidget extends StatefulWidget {
  @override
  _UserListWidgetState createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  late ApiDataManager _dataManager;
  
  @override
  void initState() {
    super.initState();
    _dataManager = ApiDataManager(ApiService());
    _dataManager.loadUsers(); // Start loading
  }
  
  @override
  void dispose() {
    _dataManager.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<List<User>>>(
      stream: _dataManager.stream,
      initialData: _dataManager.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Users'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: state.isLoading ? null : _dataManager.refreshUsers,
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }
  
  Widget _buildBody(AsyncState<List<User>> state) {
    if (state.hasError) {
      return _buildErrorState(state.error!);
    }
    
    if (state.isLoading && !state.hasData) {
      return _buildLoadingState();
    }
    
    if (state.hasData) {
      return _buildDataState(state.data!, state.isLoading);
    }
    
    return _buildEmptyState();
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading users...'),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Error: $error'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _dataManager.loadUsers,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataState(List<User> users, bool isRefreshing) {
    return Stack(
      children: [
        ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text(user.email),
            );
          },
        ),
        if (isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No users found'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _dataManager.loadUsers,
            child: Text('Load Users'),
          ),
        ],
      ),
    );
  }
}
```

## Performance Optimization

Optimizing state management performance is essential for smooth user experiences. This section covers techniques for minimizing rebuilds, managing memory efficiently, and handling large datasets. For comprehensive performance monitoring and debugging, see the [Performance Guide](performance.md).

### Selective Updates

Optimize performance by preventing unnecessary rebuilds:

```dart
class OptimizedState {
  final String title;
  final int count;
  final DateTime lastUpdated;
  final List<String> items;
  
  const OptimizedState({
    required this.title,
    required this.count,
    required this.lastUpdated,
    required this.items,
  });
  
  OptimizedState copyWith({
    String? title,
    int? count,
    DateTime? lastUpdated,
    List<String>? items,
  }) {
    return OptimizedState(
      title: title ?? this.title,
      count: count ?? this.count,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      items: items ?? this.items,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizedState &&
          title == other.title &&
          count == other.count &&
          lastUpdated == other.lastUpdated &&
          _listEquals(items, other.items);
  
  @override
  int get hashCode => 
      title.hashCode ^ 
      count.hashCode ^ 
      lastUpdated.hashCode ^ 
      items.hashCode;
  
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// Use distinct streams to prevent unnecessary rebuilds
class OptimizedWidget extends StatelessWidget {
  final Stream<OptimizedState> stateStream;
  
  const OptimizedWidget({required this.stateStream});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only rebuild when title changes
        StreamBuilder<String>(
          stream: stateStream.map((state) => state.title).distinct(),
          builder: (context, snapshot) {
            return Text('Title: ${snapshot.data ?? ''}');
          },
        ),
        
        // Only rebuild when count changes
        StreamBuilder<int>(
          stream: stateStream.map((state) => state.count).distinct(),
          builder: (context, snapshot) {
            return Text('Count: ${snapshot.data ?? 0}');
          },
        ),
        
        // Only rebuild when items change
        StreamBuilder<List<String>>(
          stream: stateStream.map((state) => state.items).distinct(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) => Text(items[index]),
            );
          },
        ),
      ],
    );
  }
}
```

### Memory Management

Implement proper memory management for large state objects:

```dart
class LargeDataState {
  final List<LargeObject> items;
  final int pageSize;
  final int currentPage;
  
  const LargeDataState({
    required this.items,
    this.pageSize = 50,
    this.currentPage = 0,
  });
  
  // Paginated access to prevent memory issues
  List<LargeObject> get currentPageItems {
    final startIndex = currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, items.length);
    return items.sublist(startIndex, endIndex);
  }
  
  int get totalPages => (items.length / pageSize).ceil();
  bool get hasNextPage => currentPage < totalPages - 1;
  bool get hasPreviousPage => currentPage > 0;
  
  LargeDataState copyWith({
    List<LargeObject>? items,
    int? pageSize,
    int? currentPage,
  }) {
    return LargeDataState(
      items: items ?? this.items,
      pageSize: pageSize ?? this.pageSize,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class LargeDataManager {
  late final ReactiveStateManager<LargeDataState> _stateManager;
  
  LargeDataManager() {
    _stateManager = ReactiveStateManager<LargeDataState>(
      const LargeDataState(items: []),
      config: const StateConfiguration(
        enableDebugging: false, // Disable for performance
        maxHistorySize: 10, // Limit history size
      ),
    );
  }
  
  LargeDataState get state => _stateManager.state;
  Stream<LargeDataState> get stream => _stateManager.stream;
  
  void nextPage() {
    _stateManager.update((current) {
      if (current.hasNextPage) {
        return current.copyWith(currentPage: current.currentPage + 1);
      }
      return current;
    });
  }
  
  void previousPage() {
    _stateManager.update((current) {
      if (current.hasPreviousPage) {
        return current.copyWith(currentPage: current.currentPage - 1);
      }
      return current;
    });
  }
  
  void dispose() {
    _stateManager.dispose();
  }
}
```

## Debugging and Development

### State Debugging

Use the built-in debugging tools during development:

```dart
class DebuggableManager {
  late final ReactiveStateManager<MyState> _stateManager;
  late final StateDebugger _debugger;
  
  DebuggableManager({required ErrorReporter errorReporter}) {
    _stateManager = ReactiveStateManager<MyState>(
      initialState,
      config: StateConfiguration.development(), // Enables debugging
      errorReporter: errorReporter,
    );
    
    _debugger = StateDebugger(errorReporter);
    _debugger.trackStateManager(_stateManager);
  }
  
  MyState get state => _stateManager.state;
  Stream<MyState> get stream => _stateManager.stream;
  
  // Debug methods
  void printStateHistory() {
    final timeline = _debugger.generateTimeline<MyState>();
    print(timeline);
  }
  
  List<StateTransition<MyState>> getHistory() {
    return _debugger.getHistory<MyState>();
  }
  
  Map<String, dynamic> getDebugStatistics() {
    return _debugger.getStatistics();
  }
  
  void clearDebugHistory() {
    _stateManager.clearHistory();
  }
  
  void dispose() {
    _debugger.stopTracking<MyState>();
    _stateManager.dispose();
  }
}
```

### Development vs Production Configuration

Use different configurations for development and production:

```dart
class ConfigurableManager {
  late final ReactiveStateManager<MyState> _stateManager;
  
  ConfigurableManager({required bool isProduction}) {
    final config = isProduction 
        ? StateConfiguration.production()
        : StateConfiguration.development();
    
    _stateManager = ReactiveStateManager<MyState>(
      initialState,
      config: config,
    );
  }
}

// In your app initialization
void main() {
  const isProduction = bool.fromEnvironment('dart.vm.product');
  
  runApp(MyApp(
    stateManager: ConfigurableManager(isProduction: isProduction),
  ));
}
```

## Integration with Flutter

### Provider Integration

Integrate state managers with Flutter's Provider pattern:

```dart
class StateManagerProvider<T> extends ChangeNotifier {
  final ReactiveStateManager<T> _stateManager;
  late StreamSubscription<T> _subscription;
  
  StateManagerProvider(this._stateManager) {
    _subscription = _stateManager.stream.listen((_) {
      notifyListeners();
    });
  }
  
  T get state => _stateManager.state;
  
  void update(T Function(T) updater) {
    _stateManager.update(updater);
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    _stateManager.dispose();
    super.dispose();
  }
}

// Usage with Provider
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => StateManagerProvider(
            ReactiveStateManager<CounterState>(
              CounterState(lastUpdated: DateTime.now()),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: CounterScreen(),
      ),
    );
  }
}

class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<StateManagerProvider<CounterState>>(
      builder: (context, provider, child) {
        final state = provider.state;
        
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${state.count}'),
                ElevatedButton(
                  onPressed: () => provider.update(
                    (current) => current.copyWith(
                      count: current.count + 1,
                      lastUpdated: DateTime.now(),
                    ),
                  ),
                  child: Text('Increment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### Dependency Injection

Use the StateProvider for dependency injection:

```dart
class AppStateProvider {
  static final instance = AppStateProvider._();
  AppStateProvider._();
  
  final DefaultStateProvider _provider = DefaultStateProvider();
  
  void initialize() {
    // Register all state managers
    _provider.register<ReactiveStateManager<UserState>>(
      ReactiveStateManager<UserState>(
        const UserState(),
        config: const StateConfiguration(enablePersistence: true),
      ),
    );
    
    _provider.register<ReactiveStateManager<AppSettings>>(
      ReactiveStateManager<AppSettings>(
        const AppSettings(),
        config: const StateConfiguration(enablePersistence: true),
      ),
    );
  }
  
  T getStateManager<T extends StateManager<dynamic>>() {
    return _provider.provide<T>();
  }
  
  void dispose() {
    _provider.disposeAll();
  }
}

// Usage in widgets
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late ReactiveStateManager<UserState> _userStateManager;
  
  @override
  void initState() {
    super.initState();
    _userStateManager = AppStateProvider.instance
        .getStateManager<ReactiveStateManager<UserState>>();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserState>(
      stream: _userStateManager.stream,
      initialData: _userStateManager.state,
      builder: (context, snapshot) {
        // Build UI based on state
        return Container();
      },
    );
  }
}
```

## Testing State Management

Thorough testing ensures your state management logic is reliable and maintainable. The toolkit provides comprehensive testing utilities for unit testing, widget testing, and integration testing. For complete testing strategies and examples, see the [Testing Guide](testing.md#testing-state-managers).

### Unit Testing State Logic

Test your state classes and business logic:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterState', () {
    test('should increment count correctly', () {
      final initialState = CounterState(
        count: 0,
        lastUpdated: DateTime.now(),
      );
      
      final newState = initialState.copyWith(count: 1);
      
      expect(newState.count, equals(1));
      expect(newState.lastUpdated, equals(initialState.lastUpdated));
    });
    
    test('should maintain immutability', () {
      final state1 = CounterState(
        count: 0,
        lastUpdated: DateTime.now(),
      );
      
      final state2 = state1.copyWith(count: 1);
      
      expect(state1.count, equals(0));
      expect(state2.count, equals(1));
      expect(identical(state1, state2), isFalse);
    });
  });
  
  group('CounterManager', () {
    late CounterManager manager;
    
    setUp(() {
      manager = CounterManager();
    });
    
    tearDown(() {
      manager.dispose();
    });
    
    test('should start with initial state', () {
      expect(manager.state.count, equals(0));
    });
    
    test('should increment count', () {
      manager.increment();
      expect(manager.state.count, equals(1));
    });
    
    test('should emit state changes', () async {
      final states = <CounterState>[];
      final subscription = manager.stream.listen(states.add);
      
      manager.increment();
      manager.increment();
      
      await Future.delayed(Duration.zero); // Allow stream to emit
      
      expect(states.length, equals(2));
      expect(states[0].count, equals(1));
      expect(states[1].count, equals(2));
      
      subscription.cancel();
    });
  });
}
```

### Widget Testing with State

Test widgets that use state managers:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterWidget', () {
    testWidgets('should display initial count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CounterWidget()),
      );
      
      expect(find.text('Count: 0'), findsOneWidget);
    });
    
    testWidgets('should increment when button pressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CounterWidget()),
      );
      
      await tester.tap(find.text('+'));
      await tester.pump();
      
      expect(find.text('Count: 1'), findsOneWidget);
    });
    
    testWidgets('should update timestamp on increment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CounterWidget()),
      );
      
      final initialTimestamp = find.textContaining('Last updated:');
      expect(initialTimestamp, findsOneWidget);
      
      await tester.tap(find.text('+'));
      await tester.pump();
      
      // Timestamp should have changed
      expect(find.textContaining('Last updated:'), findsOneWidget);
    });
  });
}
```

### Mock State Managers

Create mock state managers for testing:

```dart
class MockStateManager<T> extends StateManager<T> {
  T _state;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  
  MockStateManager(this._state);
  
  @override
  T get state => _state;
  
  @override
  Stream<T> get stream => _controller.stream;
  
  @override
  void update(T Function(T) updater) {
    _state = updater(_state);
    _controller.add(_state);
  }
  
  @override
  void dispose() {
    _controller.close();
  }
  
  // Test helpers
  void setState(T newState) {
    _state = newState;
    _controller.add(_state);
  }
  
  void emitState(T state) {
    _controller.add(state);
  }
}

// Usage in tests
void main() {
  group('Widget with Mock State', () {
    late MockStateManager<CounterState> mockManager;
    
    setUp(() {
      mockManager = MockStateManager(
        CounterState(count: 0, lastUpdated: DateTime.now()),
      );
    });
    
    tearDown(() {
      mockManager.dispose();
    });
    
    testWidgets('should respond to state changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StreamBuilder<CounterState>(
            stream: mockManager.stream,
            initialData: mockManager.state,
            builder: (context, snapshot) {
              return Text('Count: ${snapshot.data!.count}');
            },
          ),
        ),
      );
      
      expect(find.text('Count: 0'), findsOneWidget);
      
      // Simulate state change
      mockManager.setState(
        CounterState(count: 5, lastUpdated: DateTime.now()),
      );
      await tester.pump();
      
      expect(find.text('Count: 5'), findsOneWidget);
    });
  });
}
```

## Troubleshooting

### Common Issues and Solutions

#### State Not Updating in UI

**Problem**: UI doesn't rebuild when state changes.

**Solutions**:
1. Ensure you're using `StreamBuilder` with the state manager's stream
2. Check that `initialData` is provided to `StreamBuilder`
3. Verify that state updates are actually changing the state (implement proper `==` operator)

```dart
// ❌ Missing initialData
StreamBuilder<MyState>(
  stream: stateManager.stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    // ...
  },
)

// ✅ Proper StreamBuilder usage
StreamBuilder<MyState>(
  stream: stateManager.stream,
  initialData: stateManager.state, // Important!
  builder: (context, snapshot) {
    final state = snapshot.data!;
    // ...
  },
)
```

#### Memory Leaks

**Problem**: State managers not being disposed properly.

**Solutions**:
1. Always call `dispose()` in widget's `dispose()` method
2. Use `StateProvider` for automatic lifecycle management
3. Implement proper cleanup in custom managers

```dart
class _MyWidgetState extends State<MyWidget> {
  late MyStateManager _stateManager;
  
  @override
  void initState() {
    super.initState();
    _stateManager = MyStateManager();
  }
  
  @override
  void dispose() {
    _stateManager.dispose(); // Don't forget this!
    super.dispose();
  }
}
```

#### Persistence Not Working

**Problem**: State is not persisting between app sessions.

**Solutions**:
1. Ensure `enablePersistence: true` in configuration
2. Check that state class is serializable
3. Verify storage permissions on device
4. Implement custom serialization for complex objects

```dart
// ✅ Proper persistence setup
final stateManager = ReactiveStateManager<MyState>(
  initialState,
  config: const StateConfiguration(
    enablePersistence: true,
    storageKey: 'unique_key', // Optional but recommended
  ),
);

// Restore state after creation
await stateManager.restore();
```

#### Performance Issues

**Problem**: UI rebuilds too frequently or app becomes slow.

**Solutions**:
1. Use `distinct()` on streams to prevent unnecessary rebuilds
2. Implement proper `==` operator for state classes
3. Break down large state objects into smaller, focused managers
4. Disable debugging in production builds

```dart
// ✅ Prevent unnecessary rebuilds
StreamBuilder<String>(
  stream: stateManager.stream
      .map((state) => state.title)
      .distinct(), // Only rebuild when title changes
  builder: (context, snapshot) {
    return Text(snapshot.data ?? '');
  },
)
```

#### State Validation Errors

**Problem**: Invalid state updates causing app crashes.

**Solutions**:
1. Implement validation in state update methods
2. Use try-catch blocks around state updates
3. Add error reporting for debugging
4. Create factory constructors with validation

```dart
class ValidatedState {
  final String email;
  final int age;
  
  ValidatedState._({required this.email, required this.age});
  
  factory ValidatedState({required String email, required int age}) {
    if (email.isEmpty) throw ArgumentError('Email cannot be empty');
    if (age < 0) throw ArgumentError('Age cannot be negative');
    
    return ValidatedState._(email: email, age: age);
  }
}
```

### Debugging Tips

1. **Enable Debug Mode**: Use `StateConfiguration.development()` during development
2. **Use State Debugger**: Track state transitions with `StateDebugger`
3. **Add Logging**: Implement custom error reporting for state operations
4. **Monitor Performance**: Use Flutter's performance tools with state management
5. **Test State Logic**: Write comprehensive unit tests for state classes

### Best Practices Summary

1. **Keep State Immutable**: Always return new state objects, never mutate existing ones
2. **Implement Proper Equality**: Override `==` and `hashCode` for efficient change detection
3. **Use Descriptive Names**: Name your state classes and properties clearly
4. **Separate Concerns**: Keep business logic in state classes, UI logic in widgets
5. **Handle Errors Gracefully**: Implement proper error handling for async operations
6. **Optimize for Performance**: Use selective updates and proper stream management
7. **Test Thoroughly**: Write tests for both state logic and UI integration
8. **Document Complex Logic**: Add comments for complex state transformations
9. **Use Type Safety**: Leverage Dart's type system for safer state management
10. **Plan for Persistence**: Design state classes with serialization in mind

## Next Steps

Now that you understand the state management system, explore these related topics:

- [Navigation Guide](navigation.md) - Learn about type-safe routing and navigation patterns that integrate seamlessly with state management
- [Testing Guide](testing.md) - Comprehensive testing strategies for state management, including unit tests, widget tests, and property-based testing
- [Performance Guide](performance.md) - Advanced performance optimization techniques for state management and UI rendering
- [API Reference](api_reference.md) - Complete API documentation for all state management classes and methods

For more examples and advanced patterns, check out the [example applications](../example/) in the repository.