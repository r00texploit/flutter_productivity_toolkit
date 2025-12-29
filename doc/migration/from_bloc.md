# Migrating from Bloc

This guide helps you migrate from the Bloc pattern to the Flutter Productivity Toolkit's state management system. The migration can be done incrementally, allowing you to migrate one feature at a time.

## Overview

The Flutter Productivity Toolkit provides a more streamlined approach to state management compared to Bloc, with automatic code generation and built-in persistence. Here's how the concepts map:

| Bloc Concept | Toolkit Equivalent | Notes |
|--------------|-------------------|-------|
| `Bloc` | `StateManager` | Generated automatically |
| `Event` | `StateAction` | Methods on state class |
| `State` | `State` | Immutable data classes |
| `BlocBuilder` | `StateBuilder` | Similar widget builder pattern |
| `BlocListener` | `StateListener` | Listen to state changes |
| `BlocProvider` | `StateProvider` | Dependency injection |

## Step-by-Step Migration

### 1. Identify Your Current Bloc Structure

First, analyze your existing Bloc implementation:

```dart
// Existing Bloc code
abstract class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

class CounterState {
  final int count;
  const CounterState(this.count);
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(0)) {
    on<Increment>((event, emit) => emit(CounterState(state.count + 1)));
    on<Decrement>((event, emit) => emit(CounterState(state.count - 1)));
  }
}
```

### 2. Create the Equivalent State Class

Convert your Bloc state to a toolkit state class:

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

Replace Bloc widgets with toolkit equivalents:

```dart
// Before: Using BlocBuilder
BlocBuilder<CounterBloc, CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)

// After: Using StateBuilder
StateBuilder<CounterState>(
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
)
```

### 5. Update Event Dispatching

Replace event dispatching with direct method calls:

```dart
// Before: Dispatching events
context.read<CounterBloc>().add(Increment());

// After: Calling state actions
context.read<CounterStateManager>().increment();
```

### 6. Update Provider Setup

Replace BlocProvider with StateProvider:

```dart
// Before: BlocProvider
BlocProvider(
  create: (context) => CounterBloc(),
  child: MyApp(),
)

// After: StateProvider
StateProvider<CounterState>(
  create: (context) => CounterStateManager(),
  child: MyApp(),
)
```

## Advanced Migration Scenarios

### Complex State with Multiple Properties

```dart
// Before: Bloc with complex state
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const UserState({this.user, this.isLoading = false, this.error});
}

abstract class UserEvent {}
class LoadUser extends UserEvent {
  final String userId;
  LoadUser(this.userId);
}
class UserLoaded extends UserEvent {
  final User user;
  UserLoaded(this.user);
}
class UserError extends UserEvent {
  final String error;
  UserError(this.error);
}

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(const UserState()) {
    on<LoadUser>(_onLoadUser);
    on<UserLoaded>((event, emit) => emit(UserState(user: event.user)));
    on<UserError>((event, emit) => emit(UserState(error: event.error)));
  }
  
  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(const UserState(isLoading: true));
    try {
      final user = await userRepository.getUser(event.userId);
      emit(UserState(user: user));
    } catch (e) {
      emit(UserState(error: e.toString()));
    }
  }
}
```

```dart
// After: Toolkit state with async actions
@GenerateState()
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  @StateAction()
  UserState setLoading() => copyWith(isLoading: true, error: null);
  
  @StateAction()
  UserState setUser(User user) => copyWith(
    user: user,
    isLoading: false,
    error: null,
  );
  
  @StateAction()
  UserState setError(String error) => copyWith(
    error: error,
    isLoading: false,
  );
  
  @StateAction()
  Future<UserState> loadUser(String userId) async {
    final loadingState = setLoading();
    try {
      final user = await userRepository.getUser(userId);
      return loadingState.setUser(user);
    } catch (e) {
      return loadingState.setError(e.toString());
    }
  }
}
```

### Stream-Based Blocs

```dart
// Before: Stream-based Bloc
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  late StreamSubscription _locationSubscription;
  
  LocationBloc() : super(LocationInitial()) {
    on<StartLocationTracking>(_onStartTracking);
    on<LocationUpdated>((event, emit) => emit(LocationLoaded(event.location)));
  }
  
  Future<void> _onStartTracking(StartLocationTracking event, Emitter<LocationState> emit) async {
    _locationSubscription = locationService.locationStream.listen(
      (location) => add(LocationUpdated(location)),
    );
  }
  
  @override
  Future<void> close() {
    _locationSubscription.cancel();
    return super.close();
  }
}
```

```dart
// After: Toolkit with stream handling
@GenerateState()
class LocationState {
  final Location? location;
  final bool isTracking;
  
  const LocationState({this.location, this.isTracking = false});
  
  @StateAction()
  LocationState startTracking() => copyWith(isTracking: true);
  
  @StateAction()
  LocationState stopTracking() => copyWith(isTracking: false);
  
  @StateAction()
  LocationState updateLocation(Location location) => copyWith(location: location);
}

// In your state manager
class LocationStateManager extends StateManager<LocationState> {
  StreamSubscription? _locationSubscription;
  
  LocationStateManager() : super(const LocationState());
  
  void startLocationTracking() {
    updateState((state) => state.startTracking());
    
    _locationSubscription = locationService.locationStream.listen(
      (location) => updateState((state) => state.updateLocation(location)),
    );
  }
  
  void stopLocationTracking() {
    updateState((state) => state.stopTracking());
    _locationSubscription?.cancel();
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
```

## Migration Checklist

### Phase 1: Preparation
- [ ] Identify all Blocs in your application
- [ ] Document current state structure and events
- [ ] Plan migration order (start with simple Blocs)
- [ ] Set up code generation in your project

### Phase 2: State Migration
- [ ] Create state classes with `@GenerateState()`
- [ ] Convert events to state actions
- [ ] Run code generation
- [ ] Test state logic in isolation

### Phase 3: Widget Migration
- [ ] Replace `BlocBuilder` with `StateBuilder`
- [ ] Replace `BlocListener` with `StateListener`
- [ ] Update event dispatching to method calls
- [ ] Test UI interactions

### Phase 4: Provider Migration
- [ ] Replace `BlocProvider` with `StateProvider`
- [ ] Update dependency injection
- [ ] Test provider hierarchy
- [ ] Verify state persistence (if needed)

### Phase 5: Cleanup
- [ ] Remove old Bloc dependencies
- [ ] Clean up unused event classes
- [ ] Update tests
- [ ] Update documentation

## Common Migration Patterns

### 1. Simple State Updates

```dart
// Before
context.read<CounterBloc>().add(Increment());

// After
context.read<CounterStateManager>().increment();
```

### 2. Conditional State Updates

```dart
// Before
if (state.canIncrement) {
  context.read<CounterBloc>().add(Increment());
}

// After
final manager = context.read<CounterStateManager>();
if (manager.state.canIncrement) {
  manager.increment();
}
```

### 3. Listening to State Changes

```dart
// Before
BlocListener<CounterBloc, CounterState>(
  listener: (context, state) {
    if (state.count > 10) {
      showDialog(/* ... */);
    }
  },
  child: MyWidget(),
)

// After
StateListener<CounterState>(
  listener: (context, state) {
    if (state.count > 10) {
      showDialog(/* ... */);
    }
  },
  child: MyWidget(),
)
```

## Benefits After Migration

1. **Less Boilerplate**: No need to define separate event classes
2. **Type Safety**: Direct method calls instead of event dispatching
3. **Code Generation**: Automatic state manager generation
4. **Built-in Persistence**: Automatic state saving and restoration
5. **Better Testing**: Easier to test state logic directly
6. **Performance**: Optimized rebuilds with selectors

## Troubleshooting

### Common Issues

1. **Missing Code Generation**: Ensure you run `build_runner` after creating state classes
2. **Provider Not Found**: Make sure `StateProvider` is properly set up in widget tree
3. **State Not Persisting**: Add `persist: true` to `@GenerateState()` annotation
4. **Async Actions**: Use `Future<StateType>` return type for async state actions

### Getting Help

If you encounter issues during migration:
- Check the [troubleshooting guide](troubleshooting.md)
- Review the [API reference](api_reference.md)
- Ask questions in [GitHub Discussions](https://github.com/r00texploit/flutter_productivity_toolkit/discussions)

## Next Steps

After completing the migration:
1. Explore additional toolkit features like navigation and testing utilities
2. Set up performance monitoring
3. Consider using code generation for other parts of your app
4. Review the [best practices guide](best_practices.md) for optimization tips