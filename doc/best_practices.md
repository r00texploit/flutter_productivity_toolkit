# Best Practices

This guide outlines recommended patterns and practices when using the Flutter Productivity Toolkit to ensure optimal performance, maintainability, and developer experience.

## State Management Best Practices

### 1. Keep State Classes Immutable

Always use immutable state classes with `const` constructors:

```dart
@GenerateState()
class UserState {
  final String name;
  final int age;
  final List<String> interests;
  
  const UserState({
    required this.name,
    required this.age,
    this.interests = const [],
  });
  
  @StateAction()
  UserState updateName(String newName) {
    return UserState(
      name: newName,
      age: age,
      interests: interests,
    );
  }
}
```

### 2. Use Specific State Actions

Create focused, single-purpose state actions:

```dart
// ✅ Good - specific actions
@StateAction()
UserState updateName(String name) => copyWith(name: name);

@StateAction()
UserState updateAge(int age) => copyWith(age: age);

// ❌ Avoid - generic update methods
@StateAction()
UserState update(Map<String, dynamic> changes) { /* ... */ }
```

### 3. Implement Proper Error Handling

Handle errors gracefully in state actions:

```dart
@GenerateState()
class ApiState<T> {
  final T? data;
  final String? error;
  final bool isLoading;
  
  const ApiState({
    this.data,
    this.error,
    this.isLoading = false,
  });
  
  @StateAction()
  ApiState<T> startLoading() => copyWith(isLoading: true, error: null);
  
  @StateAction()
  ApiState<T> setData(T data) => copyWith(
    data: data,
    isLoading: false,
    error: null,
  );
  
  @StateAction()
  ApiState<T> setError(String error) => copyWith(
    error: error,
    isLoading: false,
  );
}
```

## Navigation Best Practices

### 1. Use Type-Safe Routes

Always define routes with proper typing:

```dart
@GenerateRoute('/user/:id/profile')
class UserProfileRoute {
  final String userId;
  final String? tab;
  
  const UserProfileRoute({
    required this.userId,
    this.tab,
  });
}

// Navigate with type safety
await navigator.navigate<UserProfileRoute, UserProfile?>(
  '/user/123/profile',
  params: UserProfileRoute(userId: '123', tab: 'settings'),
);
```

### 2. Implement Route Guards

Use route guards for authentication and authorization:

```dart
@GenerateRoute('/admin/dashboard')
@RouteGuard(AdminGuard)
class AdminDashboardRoute {
  const AdminDashboardRoute();
}

class AdminGuard implements RouteGuard {
  @override
  Future<bool> canActivate(RouteContext context) async {
    final user = await AuthService.getCurrentUser();
    return user?.isAdmin ?? false;
  }
}
```

### 3. Handle Deep Links Properly

Ensure your routes handle deep links correctly:

```dart
@GenerateRoute('/product/:id')
class ProductRoute {
  final String productId;
  
  const ProductRoute({required this.productId});
  
  // Validate parameters
  static ProductRoute? fromPath(String path) {
    final uri = Uri.parse(path);
    final id = uri.pathSegments.elementAtOrNull(1);
    
    if (id == null || id.isEmpty) return null;
    
    return ProductRoute(productId: id);
  }
}
```

## Testing Best Practices

### 1. Use Test Factories

Create reusable test data factories:

```dart
class UserTestFactory {
  static User createUser({
    String? name,
    int? age,
    List<String>? interests,
  }) {
    return User(
      name: name ?? 'Test User',
      age: age ?? 25,
      interests: interests ?? ['testing', 'flutter'],
    );
  }
  
  static List<User> createUsers(int count) {
    return List.generate(count, (i) => createUser(name: 'User $i'));
  }
}
```

### 2. Test State Transitions

Focus on testing state changes:

```dart
void main() {
  group('UserState', () {
    test('should update name correctly', () {
      const initialState = UserState(name: 'John', age: 30);
      final newState = initialState.updateName('Jane');
      
      expect(newState.name, equals('Jane'));
      expect(newState.age, equals(30)); // Unchanged
    });
  });
}
```

### 3. Use Property-Based Testing

Test with generated data for comprehensive coverage:

```dart
void main() {
  group('UserState Properties', () {
    testProperty('name updates preserve other fields', () {
      forAll(
        tuple2(userStateGen, stringGen),
        (data) {
          final (state, newName) = data;
          final updated = state.updateName(newName);
          
          return updated.name == newName &&
                 updated.age == state.age &&
                 updated.interests == state.interests;
        },
      );
    });
  });
}
```

## Performance Best Practices

### 1. Monitor Widget Rebuilds

Use the performance monitor to identify unnecessary rebuilds:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PerformanceTracker(
      name: 'MyWidget',
      child: StateBuilder<UserState>(
        builder: (context, state) {
          return Text(state.name);
        },
      ),
    );
  }
}
```

### 2. Optimize State Selectors

Use specific selectors to minimize rebuilds:

```dart
// ✅ Good - specific selector
StateBuilder<UserState>(
  selector: (state) => state.name,
  builder: (context, name) => Text(name),
)

// ❌ Avoid - rebuilds on any state change
StateBuilder<UserState>(
  builder: (context, state) => Text(state.name),
)
```

### 3. Use Lazy Loading

Implement lazy loading for expensive operations:

```dart
@GenerateState()
class DataState {
  final List<Item>? items;
  final bool isLoading;
  
  const DataState({this.items, this.isLoading = false});
  
  @StateAction()
  Future<DataState> loadItems() async {
    if (items != null) return this; // Already loaded
    
    final newState = copyWith(isLoading: true);
    try {
      final loadedItems = await ApiService.getItems();
      return newState.copyWith(items: loadedItems, isLoading: false);
    } catch (e) {
      return newState.copyWith(isLoading: false);
    }
  }
}
```

## Code Generation Best Practices

### 1. Organize Generated Code

Keep generated code in a dedicated directory:

```
lib/
  generated/
    models/
    routes/
    state/
  src/
    models/
    screens/
    services/
```

### 2. Use Meaningful Annotations

Provide clear, descriptive annotations:

```dart
@GenerateModel(
  tableName: 'users',
  generateToJson: true,
  generateFromJson: true,
  generateCopyWith: true,
)
class User {
  @JsonKey(name: 'user_id')
  final String id;
  
  @JsonKey(includeIfNull: false)
  final String? email;
  
  const User({required this.id, this.email});
}
```

### 3. Version Control Generated Files

Include generated files in version control for consistency:

```gitignore
# Don't ignore generated files
!lib/generated/
```

## Error Handling Best Practices

### 1. Use Structured Error Types

Define specific error types for different scenarios:

```dart
abstract class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  final int statusCode;
  const NetworkError(super.message, this.statusCode);
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(super.message, this.fieldErrors);
}
```

### 2. Implement Global Error Handling

Set up global error handling for unhandled exceptions:

```dart
void main() {
  FlutterError.onError = (details) {
    ErrorReporter.reportError(details.exception, details.stack);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.reportError(error, stack);
    return true;
  };
  
  runApp(MyApp());
}
```

### 3. Provide User-Friendly Error Messages

Show meaningful error messages to users:

```dart
String getErrorMessage(AppError error) {
  return switch (error) {
    NetworkError() => 'Network connection failed. Please try again.',
    ValidationError() => 'Please check your input and try again.',
    _ => 'An unexpected error occurred.',
  };
}
```

## Development Workflow Best Practices

### 1. Use Continuous Code Generation

Run code generation in watch mode during development:

```bash
flutter packages pub run build_runner watch --delete-conflicting-outputs
```

### 2. Implement Pre-commit Hooks

Set up pre-commit hooks to ensure code quality:

```bash
#!/bin/sh
# .git/hooks/pre-commit

flutter analyze
flutter test
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. Use Consistent Naming Conventions

Follow consistent naming patterns:

- State classes: `*State` (e.g., `UserState`, `CartState`)
- Route classes: `*Route` (e.g., `HomeRoute`, `ProfileRoute`)
- Service classes: `*Service` (e.g., `ApiService`, `AuthService`)
- Test files: `*_test.dart`

## Documentation Best Practices

### 1. Document Public APIs

Provide comprehensive documentation for public APIs:

```dart
/// Manages user authentication and session state.
/// 
/// This service handles login, logout, and session persistence.
/// Use [login] to authenticate users and [logout] to end sessions.
/// 
/// Example:
/// ```dart
/// final authService = AuthService();
/// final user = await authService.login('email', 'password');
/// ```
class AuthService {
  /// Authenticates a user with email and password.
  /// 
  /// Returns the authenticated [User] on success.
  /// Throws [AuthException] if authentication fails.
  Future<User> login(String email, String password) async {
    // Implementation
  }
}
```

### 2. Include Usage Examples

Provide practical examples in documentation:

```dart
/// Example usage:
/// ```dart
/// @GenerateState()
/// class CounterState {
///   final int count;
///   const CounterState({this.count = 0});
///   
///   @StateAction()
///   CounterState increment() => CounterState(count: count + 1);
/// }
/// ```
```

### 3. Keep Documentation Updated

Ensure documentation stays current with code changes:

- Update examples when APIs change
- Review documentation during code reviews
- Use automated tools to check documentation coverage

## Security Best Practices

### 1. Validate Input Data

Always validate and sanitize input data:

```dart
@GenerateModel()
class User {
  @Validate(EmailValidator())
  final String email;
  
  @Validate(LengthValidator(min: 8, max: 100))
  final String password;
  
  const User({required this.email, required this.password});
}
```

### 2. Handle Sensitive Data Properly

Use secure storage for sensitive information:

```dart
class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

### 3. Implement Proper Authentication

Use secure authentication patterns:

```dart
@RouteGuard(AuthGuard)
class ProtectedRoute {
  const ProtectedRoute();
}

class AuthGuard implements RouteGuard {
  @override
  Future<bool> canActivate(RouteContext context) async {
    final token = await SecureStorage.getToken();
    return token != null && await AuthService.validateToken(token);
  }
}
```

Following these best practices will help you build robust, maintainable, and performant Flutter applications with the Flutter Productivity Toolkit.