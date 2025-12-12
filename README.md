# Flutter Developer Productivity Toolkit

A comprehensive Flutter package that addresses the most critical pain points faced by Flutter developers in 2024. This toolkit provides unified solutions for state management, navigation, testing utilities, and development workflow optimization.

## Features

### 🚀 State Management
- Simplified reactive state management that works across different architectures
- Automatic dependency injection with lifecycle management
- Built-in persistence with configurable storage backends
- Development-time debugging with state transition history

### 🧭 Navigation & Routing
- Declarative navigation with automatic deep linking support
- Type-safe route definitions with compile-time parameter validation
- Multiple navigation stack support for complex UIs
- Automatic route generation from annotations

### 🧪 Testing Utilities
- Pre-configured test environments with minimal setup
- Automatic mock generation for state managers and services
- Realistic test data factories with customizable parameters
- Integration test utilities with app lifecycle management

### ⚡ Performance Monitoring
- Real-time widget rebuild tracking with visual indicators
- Memory leak detection with actionable recommendations
- Frame drop analysis with bottleneck identification
- Custom performance metric collection and reporting

### 🔧 Code Generation
- Automated boilerplate reduction using build_runner
- State manager generation from class annotations
- Type-safe API client generation from OpenAPI specifications
- Data model generation with serialization methods

### 📦 Development Tools
- Package optimization tools for pub.dev publishing
- Real-time Flutter-specific linting
- Automatic asset reference class generation
- Dependency conflict detection and optimization

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_dev_toolkit: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.7
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the Toolkit

```dart
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart';

void main() {
  // Initialize with development configuration
  final config = ToolkitConfiguration.development();
  
  runApp(MyApp());
}
```

### 2. State Management

```dart
@GenerateState(persist: true)
class CounterState {
  final int count;
  
  const CounterState({this.count = 0});
  
  @StateAction()
  CounterState increment() => CounterState(count: count + 1);
}

// Generated state manager will be available as CounterStateManager
```

### 3. Navigation

```dart
@GenerateRoute('/user/:id/profile')
class UserProfileRoute {
  final String userId;
  
  const UserProfileRoute({required this.userId});
}

// Navigate type-safely
await navigator.navigate<UserProfileRoute, void>(
  '/user/123/profile',
  params: UserProfileRoute(userId: '123'),
);
```

### 4. Testing

```dart
void main() {
  group('Counter Tests', () {
    late TestEnvironment testEnv;
    
    setUp(() async {
      testEnv = await TestHelper().setupTestEnvironment();
    });
    
    testWidgets('should increment counter', (tester) async {
      final counter = testEnv.dataFactory.create<CounterState>();
      
      await testEnv.helper.pumpAndSettle(
        tester,
        CounterWidget(initialState: counter),
      );
      
      // Test implementation...
    });
  });
}
```

## Configuration

The toolkit supports three pre-configured setups:

### Development Configuration
```dart
final config = ToolkitConfiguration.development();
// Enables debugging, verbose logging, and real-time monitoring
```

### Production Configuration
```dart
final config = ToolkitConfiguration.production();
// Optimized for performance with minimal overhead
```

### Testing Configuration
```dart
final config = ToolkitConfiguration.testing();
// Configured for reliable test execution
```

### Custom Configuration
```dart
final config = ToolkitConfiguration(
  stateManagement: StateManagementConfig(
    enableDebugging: true,
    enablePersistence: true,
  ),
  navigation: NavigationConfig(
    enableDeepLinking: true,
  ),
  performance: PerformanceConfig(
    enableMonitoring: true,
    thresholds: PerformanceThresholds(
      maxFrameDropsPerSecond: 3,
      minFps: 58.0,
    ),
  ),
);
```

## Code Generation

Run code generation to create boilerplate code:

```bash
flutter packages pub run build_runner build
```

For continuous generation during development:

```bash
flutter packages pub run build_runner watch
```

## Performance Monitoring

Enable real-time performance monitoring in development:

```dart
final monitor = PerformanceMonitor();
monitor.startMonitoring();

// Listen to performance metrics
monitor.metricsStream.listen((metrics) {
  if (!metrics.isPerformanceGood) {
    print('Performance issues detected: ${metrics.warnings}');
  }
});
```

## Documentation

- [API Documentation](https://pub.dev/documentation/flutter_dev_toolkit/latest/)
- [State Management Guide](docs/state_management.md)
- [Navigation Guide](docs/navigation.md)
- [Testing Guide](docs/testing.md)
- [Performance Guide](docs/performance.md)
- [Code Generation Guide](docs/code_generation.md)

## Examples

Check out the [example](example/) directory for complete sample applications demonstrating all toolkit features.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- [GitHub Issues](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/issues)
- [Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)
- [Documentation](https://pub.dev/documentation/flutter_dev_toolkit/latest/)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and updates.