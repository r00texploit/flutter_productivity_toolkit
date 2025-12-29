# Code Generation Guide

The Flutter Productivity Toolkit provides powerful code generation capabilities to reduce boilerplate and improve developer productivity. This guide covers all aspects of using the code generation features.

## Overview

The toolkit uses build_runner to generate code from annotations. This approach provides:

- **Type Safety**: Generated code is fully type-safe with compile-time validation
- **Consistency**: All generated code follows the same patterns and conventions
- **Maintainability**: Changes to annotations automatically update generated code
- **Performance**: Generated code is optimized for runtime performance

## Setup

### 1. Add Dependencies

Ensure you have the required dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_productivity_toolkit: ^0.1.4
  
dev_dependencies:
  build_runner: ^2.7.1
```

### 2. Configure Build

Create or update `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      flutter_productivity_toolkit|state_generator:
        enabled: true
      flutter_productivity_toolkit|route_generator:
        enabled: true
      flutter_productivity_toolkit|model_generator:
        enabled: true
```

### 3. Run Code Generation

Generate code using build_runner:

```bash
# One-time generation
flutter packages pub run build_runner build

# Watch mode for development
flutter packages pub run build_runner watch

# Clean and rebuild
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## State Management Generation

### Basic State Class

Use `@GenerateState()` to create reactive state managers:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

@GenerateState()
class CounterState {
  final int count;
  final String? message;
  
  const CounterState({
    this.count = 0,
    this.message,
  });
  
  @StateAction()
  CounterState increment() => CounterState(
    count: count + 1,
    message: message,
  );
  
  @StateAction()
  CounterState setMessage(String newMessage) => CounterState(
    count: count,
    message: newMessage,
  );
}
```

This generates:
- `CounterStateManager` class
- Reactive update methods
- Automatic change detection
- Optional persistence support

### Advanced State Features

#### Persistence

Enable automatic state persistence:

```dart
@GenerateState(persist: true, storageKey: 'counter_state')
class CounterState {
  // ... state definition
}
```

#### Debugging

Enable debugging features:

```dart
@GenerateState(enableDebugging: true, maxHistorySize: 500)
class CounterState {
  // ... state definition
}
```

#### Async Actions

Define async state actions:

```dart
@GenerateState()
class UserState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  const UserState({this.user, this.isLoading = false, this.error});
  
  @StateAction()
  Future<UserState> loadUser(String userId) async {
    final loadingState = copyWith(isLoading: true, error: null);
    try {
      final user = await UserService.getUser(userId);
      return loadingState.copyWith(user: user, isLoading: false);
    } catch (e) {
      return loadingState.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

## Route Generation

### Basic Routes

Use `@GenerateRoute()` to create type-safe navigation:

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
```

This generates:
- Route parsing logic
- Type-safe navigation methods
- Parameter validation
- Deep link support

### Advanced Routing

#### Route Guards

Add authentication and authorization:

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

#### Nested Routes

Define complex navigation hierarchies:

```dart
@GenerateRoute('/shop')
class ShopRoute {
  const ShopRoute();
}

@GenerateRoute('/shop/category/:categoryId')
class CategoryRoute {
  final String categoryId;
  const CategoryRoute({required this.categoryId});
}

@GenerateRoute('/shop/product/:productId')
class ProductRoute {
  final String productId;
  const ProductRoute({required this.productId});
}
```

## Model Generation

### Data Models

Use `@GenerateModel()` to create data classes with serialization:

```dart
@GenerateModel()
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final List<String> tags;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.tags = const [],
  });
}
```

This generates:
- `copyWith` method
- `toJson` and `fromJson` methods
- Equality operators
- `toString` method

### Advanced Model Features

#### Custom Serialization

Control JSON serialization:

```dart
@GenerateModel()
class User {
  @JsonKey(name: 'user_id')
  final String id;
  
  @JsonKey(includeIfNull: false)
  final String? nickname;
  
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime createdAt;
  
  const User({required this.id, this.nickname, required this.createdAt});
  
  static DateTime _dateFromJson(String date) => DateTime.parse(date);
  static String _dateToJson(DateTime date) => date.toIso8601String();
}
```

#### Validation

Add validation to models:

```dart
@GenerateModel()
class User {
  @Validate(EmailValidator())
  final String email;
  
  @Validate(LengthValidator(min: 2, max: 50))
  final String name;
  
  @Validate(RangeValidator(min: 0, max: 120))
  final int age;
  
  const User({required this.email, required this.name, required this.age});
}
```

## API Client Generation

### OpenAPI Integration

Generate API clients from OpenAPI specifications:

```dart
@GenerateApiClient('assets/api/openapi.yaml')
class ApiClient {
  // Generated methods will be added here
}
```

This generates:
- Type-safe API methods
- Request/response models
- Error handling
- Authentication support

### Custom API Endpoints

Define custom API endpoints:

```dart
@GenerateApiClient()
class UserApiClient {
  @Get('/users/:id')
  Future<User> getUser(@Path('id') String userId);
  
  @Post('/users')
  Future<User> createUser(@Body() CreateUserRequest request);
  
  @Put('/users/:id')
  Future<User> updateUser(
    @Path('id') String userId,
    @Body() UpdateUserRequest request,
  );
  
  @Delete('/users/:id')
  Future<void> deleteUser(@Path('id') String userId);
}
```

## Localization Generation

### Translation Files

Generate localization code from translation files:

```dart
@GenerateLocalizations(['en', 'es', 'fr'])
class AppLocalizations {
  // Generated localization methods will be added here
}
```

Place translation files in `lib/l10n/`:
- `app_en.json`
- `app_es.json`
- `app_fr.json`

### Usage

Access translations in your widgets:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.welcomeMessage);
  }
}
```

## Configuration

### Generation Options

Customize code generation behavior:

```dart
@GenerateState(
  generateCopyWith: true,
  generateToString: true,
  generateEquality: true,
  generateHashCode: true,
)
class MyState {
  // ... state definition
}
```

### Output Directory

Configure where generated files are placed:

```yaml
# build.yaml
targets:
  $default:
    builders:
      flutter_productivity_toolkit|state_generator:
        options:
          output_directory: 'lib/generated'
```

## Best Practices

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

### 2. Version Control

Include generated files in version control for consistency:

```gitignore
# Don't ignore generated files
!lib/generated/
```

### 3. Continuous Generation

Use watch mode during development:

```bash
flutter packages pub run build_runner watch --delete-conflicting-outputs
```

### 4. Clean Builds

Regularly clean and rebuild to avoid conflicts:

```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Troubleshooting

### Common Issues

#### Build Conflicts

If you encounter build conflicts:

```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### Missing Dependencies

Ensure all required dependencies are in `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.7.1
  json_annotation: ^4.8.1
```

#### Generation Errors

Check that your annotations are correct:

```dart
// ✅ Correct
@GenerateState()
class MyState {
  const MyState();
}

// ❌ Incorrect - missing const constructor
@GenerateState()
class MyState {
  MyState();
}
```

### Performance Tips

1. **Use watch mode** during development for faster rebuilds
2. **Exclude test files** from generation to improve build times
3. **Use specific builders** only for files that need them
4. **Keep generated files** in version control to avoid regeneration

## Advanced Usage

### Custom Generators

Create custom code generators for specific needs:

```dart
class CustomGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    // Custom generation logic
    return generatedCode;
  }
}
```

### Integration with CI/CD

Ensure generated code is up-to-date in CI:

```yaml
# .github/workflows/ci.yml
- name: Generate code
  run: flutter packages pub run build_runner build --delete-conflicting-outputs

- name: Check for changes
  run: git diff --exit-code
```

## Examples

See the [examples directory](../example/) for complete working examples of all code generation features:

- [State Management Example](../example/state_management_example.dart)
- [Navigation Example](../example/navigation_showcase_example.dart)
- [Code Generation Example](../example/code_generation_example.dart)

## Next Steps

- Explore [state management](state_management.md) for reactive programming patterns
- Learn about [navigation](navigation.md) for type-safe routing
- Check out [testing](testing.md) for generated test utilities
- Review [best practices](best_practices.md) for optimal usage patterns