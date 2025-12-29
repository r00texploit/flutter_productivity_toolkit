# Migrating from Riverpod

This guide helps you migrate from Riverpod to the Flutter Productivity Toolkit's state management system. The migration can be done incrementally, allowing you to migrate one provider at a time.

## Overview

The Flutter Productivity Toolkit provides a different approach to state management compared to Riverpod, with automatic code generation and built-in persistence. Here's how the concepts map:

| Riverpod Concept | Toolkit Equivalent | Notes |
|------------------|-------------------|-------|
| `Provider` | `StateManager` | Generated automatically |
| `StateNotifier` | `StateManager` | Similar functionality |
| `ConsumerWidget` | `StateBuilder` | Widget builder pattern |
| `Consumer` | `StateBuilder` | Listen to state changes |
| `ProviderScope` | `StateProvider` | Dependency injection |
| `ref.read()` | `context.read()` | Access state manager |
| `ref.watch()` | `StateBuilder` | Watch state changes |

## Step-by-Step Migration

### 1. Identify Your Current Riverpod Structure

First, analyze your existing Riverpod implementation:

```dart
// Existing Riverpod code
class CounterState {
  final int count;
  const CounterState(this.count);
}

class CounterNotifier extends StateNotifier<CounterState> {
  CounterNotifier() : super(const CounterState(0));
  
  void increment() => state = CounterState(state.count + 1);
  void decrement() => state = CounterState(state.count - 1);
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterState>(
  (ref) => CounterNotifier(),
);
```

### 2. Create the Equivalent State Class

Convert your Riverpod state to a toolkit state class:

```dart
// New toolkit state
@GenerateState()
class CounterState {
  final int count;
  
  const CounterState({this.count = 0});
  
  @StateAction()
  CounterState increment() => CounterState(count: count + 1);
  
  @StateAction()
  CounterState decrement() => CounterState(count: count - 1);
}
```

### 3. Run Code Generation

Generate the state manager:

```bash
flutter packages pub run build_runner build
```

This creates `CounterStateManager` automatically.

### 4. Update Your Widgets

Replace Riverpod widgets with toolkit equivalents:

```dart
// Before: Using Consumer
Consumer(
  builder: (context, ref, child) {
    final count = ref.watch(counterProvider).count;
    return Text('Count: $count');
  },
)

// After: Using StateBuilder
StateBuilder<CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

### 5. Update State Modifications

Replace ref.read() calls with direct method calls:

```dart
// Before: Using ref.read()
ref.read(counterProvider.notifier).increment();

// After: Calling state actions
context.read<CounterStateManager>().increment();
```

### 6. Update Provider Setup

Replace ProviderScope with StateProvider:

```dart
// Before: ProviderScope
ProviderScope(
  child: MyApp(),
)

// After: StateProvider
StateProvider<CounterState>(
  create: (context) => CounterStateManager(),
  child: MyApp(),
)
```

## Advanced Migration Scenarios

### Family Providers

```dart
// Before: Family provider
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await userRepository.getUser(userId);
});

// Usage
Consumer(
  builder: (context, ref, child) {
    final userAsync = ref.watch(userProvider('123'));
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  },
)
```

```dart
// After: Parameterized state actions
@GenerateState()
class UserState {
  final Map<String, User> users;
  final Set<String> loadingUsers;
  final Map<String, String> userErrors;
  
  const UserState({
    this.users = const {},
    this.loadingUsers = const {},
    this.userErrors = const {},
  });
  
  @StateAction()
  UserState setUserLoading(String userId) => copyWith(
    loadingUsers: {...loadingUsers, userId},
    userErrors: Map.from(userErrors)..remove(userId),
  );
  
  @StateAction()
  UserState setUser(String userId, User user) => copyWith(
    users: {...users, userId: user},
    loadingUsers: Set.from(loadingUsers)..remove(userId),
  );
  
  @StateAction()
  UserState setUserError(String userId, String error) => copyWith(
    userErrors: {...userErrors, userId: error},
    loadingUsers: Set.from(loadingUsers)..remove(userId),
  );
  
  @StateAction()
  Future<UserState> loadUser(String userId) async {
    if (users.containsKey(userId)) return this;
    
    final loadingState = setUserLoading(userId);
    try {
      final user = await userRepository.getUser(userId);
      return loadingState.setUser(userId, user);
    } catch (e) {
      return loadingState.setUserError(userId, e.toString());
    }
  }
  
  User? getUser(String userId) => users[userId];
  bool isUserLoading(String userId) => loadingUsers.contains(userId);
  String? getUserError(String userId) => userErrors[userId];
}

// Usage
StateBuilder<UserState>(
  selector: (state) => (
    user: state.getUser('123'),
    isLoading: state.isUserLoading('123'),
    error: state.getUserError('123'),
  ),
  builder: (context, data) {
    if (data.isLoading) return CircularProgressIndicator();
    if (data.error != null) return Text('Error: ${data.error}');
    if (data.user != null) return Text(data.user!.name);
    return Text('No user found');
  },
)
```

### Auto-Dispose Providers

```dart
// Before: Auto-dispose provider
final timerProvider = StateNotifierProvider.autoDispose<TimerNotifier, int>(
  (ref) => TimerNotifier(),
);

class TimerNotifier extends StateNotifier<int> {
  Timer? _timer;
  
  TimerNotifier() : super(0) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      state++;
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

```dart
// After: Custom state manager with disposal
@GenerateState()
class TimerState {
  final int seconds;
  
  const TimerState({this.seconds = 0});
  
  @StateAction()
  TimerState tick() => TimerState(seconds: seconds + 1);
}

class TimerStateManager extends StateManager<TimerState> {
  Timer? _timer;
  
  TimerStateManager() : super(const TimerState()) {
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      updateState((state) => state.tick());
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

### Provider Dependencies

```dart
// Before: Provider with dependencies
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) throw Exception('Not authenticated');
  
  final api = ref.read(apiServiceProvider);
  return await api.getUserProfile(auth.user!.id);
});
```

```dart
// After: Dependency injection with state managers
@GenerateState()
class AuthState {
  final User? user;
  final bool isLoading;
  
  const AuthState({this.user, this.isLoading = false});
  
  @StateAction()
  AuthState setUser(User user) => copyWith(user: user, isLoading: false);
  
  @StateAction()
  AuthState setLoading() => copyWith(isLoading: true);
}

@GenerateState()
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  
  const UserProfileState({this.profile, this.isLoading = false, this.error});
  
  @StateAction()
  Future<UserProfileState> loadProfile(User user, ApiService apiService) async {
    final loadingState = copyWith(isLoading: true, error: null);
    try {
      final profile = await apiService.getUserProfile(user.id);
      return loadingState.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      return loadingState.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// Setup with dependency injection
MultiStateProvider(
  providers: [
    StateProvider<AuthState>(
      create: (context) => AuthStateManager(),
    ),
    StateProvider<UserProfileState>(
      create: (context) => UserProfileStateManager(),
    ),
  ],
  child: MyApp(),
)
```

## Migration Checklist

### Phase 1: Preparation
- [ ] Identify all providers in your application
- [ ] Document current provider structure and dependencies
- [ ] Plan migration order (start with simple providers)
- [ ] Set up code generation in your project

### Phase 2: State Migration
- [ ] Create state classes with `@GenerateState()`
- [ ] Convert StateNotifiers to state actions
- [ ] Handle provider families with parameterized actions
- [ ] Run code generation
- [ ] Test state logic in isolation

### Phase 3: Widget Migration
- [ ] Replace `Consumer` with `StateBuilder`
- [ ] Replace `ConsumerWidget` with regular widgets + `StateBuilder`
- [ ] Update `ref.watch()` calls to `StateBuilder` selectors
- [ ] Update `ref.read()` calls to `context.read()`
- [ ] Test UI interactions

### Phase 4: Provider Migration
- [ ] Replace `ProviderScope` with `StateProvider`
- [ ] Handle provider dependencies with dependency injection
- [ ] Update auto-dispose providers with custom disposal logic
- [ ] Test provider hierarchy
- [ ] Verify state persistence (if needed)

### Phase 5: Cleanup
- [ ] Remove Riverpod dependencies
- [ ] Clean up unused provider definitions
- [ ] Update tests
- [ ] Update documentation

## Common Migration Patterns

### 1. Simple State Access

```dart
// Before
final count = ref.watch(counterProvider).count;

// After
StateBuilder<CounterState>(
  selector: (state) => state.count,
  builder: (context, count) => Text('$count'),
)
```

### 2. State Modifications

```dart
// Before
ref.read(counterProvider.notifier).increment();

// After
context.read<CounterStateManager>().increment();
```

### 3. Conditional Rebuilds

```dart
// Before
final isEven = ref.watch(counterProvider.select((state) => state.count.isEven));

// After
StateBuilder<CounterState>(
  selector: (state) => state.count.isEven,
  builder: (context, isEven) => Text('Even: $isEven'),
)
```

### 4. Multiple Provider Watching

```dart
// Before
Consumer(
  builder: (context, ref, child) {
    final user = ref.watch(userProvider);
    final settings = ref.watch(settingsProvider);
    return UserWidget(user: user, settings: settings);
  },
)

// After
MultiStateBuilder(
  builder: (context) {
    final user = context.watch<UserState>();
    final settings = context.watch<SettingsState>();
    return UserWidget(user: user, settings: settings);
  },
)
```

## Benefits After Migration

1. **Code Generation**: Automatic state manager generation reduces boilerplate
2. **Type Safety**: Compile-time validation of state actions
3. **Built-in Persistence**: Automatic state saving and restoration
4. **Simpler Testing**: Direct method calls instead of provider mocking
5. **Better Performance**: Optimized rebuilds with selectors
6. **Unified API**: Consistent patterns across all state management

## Troubleshooting

### Common Issues

1. **Missing Code Generation**: Ensure you run `build_runner` after creating state classes
2. **Provider Not Found**: Make sure `StateProvider` is properly set up in widget tree
3. **State Not Persisting**: Add `persist: true` to `@GenerateState()` annotation
4. **Async Actions**: Use `Future<StateType>` return type for async state actions
5. **Dependency Injection**: Use `MultiStateProvider` for multiple state managers

### Performance Considerations

1. **Use Selectors**: Always use selectors in `StateBuilder` to minimize rebuilds
2. **Avoid Large State Objects**: Split large state into smaller, focused state classes
3. **Lazy Loading**: Implement lazy loading for expensive operations
4. **Dispose Resources**: Override `dispose()` in custom state managers for cleanup

## Next Steps

After completing the migration:
1. Explore additional toolkit features like navigation and testing utilities
2. Set up performance monitoring to track state management efficiency
3. Consider using code generation for other parts of your app
4. Review the [best practices guide](best_practices.md) for optimization tips
5. Set up automated testing for your new state management code

## Getting Help

If you encounter issues during migration:
- Check the [troubleshooting guide](troubleshooting.md)
- Review the [API reference](api_reference.md)
- Ask questions in [GitHub Discussions](https://github.com/r00texploit/flutter_productivity_toolkit/discussions)
- Look at the [examples](../example/) for common patterns