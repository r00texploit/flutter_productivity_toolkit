# Flutter Developer Productivity Toolkit

[![pub package](https://img.shields.io/pub/v/flutter_productivity_toolkit.svg)](https://pub.dev/packages/flutter_productivity_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)

A comprehensive Flutter package that addresses the most critical pain points faced by Flutter developers in 2025. This toolkit provides unified solutions for state management, navigation, testing utilities, and development workflow optimization.

**🎯 Built for Developer Productivity** • **🔒 Type-Safe by Design** • **⚡ Zero Configuration** • **🧪 Testing First**

## Why Choose This Toolkit?

- **Unified Solution**: All components work seamlessly together
- **Minimal Boilerplate**: Automatic code generation reduces repetitive tasks
- **Type Safety**: Compile-time validation prevents runtime errors
- **Production Ready**: Battle-tested patterns with comprehensive error handling
- **Incremental Adoption**: Use individual features or the complete solution
- **Performance First**: Built-in monitoring and optimization tools

## Features

### 🚀 State Management
- **Reactive Updates**: Automatic UI rebuilds with minimal performance impact
- **Dependency Injection**: Automatic lifecycle management with zero configuration
- **Built-in Persistence**: State automatically saved and restored across app restarts
- **Time-Travel Debugging**: Visual state timeline with action replay capabilities
- **Type-Safe Operations**: Compile-time validation of state updates

### 🧭 Navigation & Routing
- **Declarative Routes**: Define routes with simple annotations
- **Type-Safe Navigation**: Compile-time parameter validation and auto-completion
- **Deep Linking**: Automatic URL parsing with parameter extraction
- **Multiple Stacks**: Support for complex nested navigation scenarios
- **Route Guards**: Built-in authentication and authorization handling

### 🧪 Testing Utilities
- **Zero Setup Testing**: Pre-configured environments with automatic mocking
- **Realistic Data**: Smart test data generation with customizable factories
- **Integration Ready**: Full app lifecycle management for end-to-end tests
- **Performance Testing**: Built-in utilities for performance regression detection
- **Property-Based Testing**: Generate comprehensive test cases automatically

### ⚡ Performance Monitoring
- **Real-Time Insights**: Live performance metrics during development
- **Memory Leak Detection**: Automatic detection with actionable recommendations
- **Widget Optimization**: Identify and fix unnecessary rebuilds
- **Custom Metrics**: Track application-specific performance indicators
- **Production Analytics**: Optional performance tracking for production apps

### 🔧 Code Generation
- **Automatic Boilerplate**: Generate state managers, routes, and data models
- **API Client Generation**: Create type-safe clients from OpenAPI specifications
- **Serialization**: Automatic JSON serialization with null safety
- **Localization**: Generate type-safe translation access methods
- **Asset References**: Automatic asset class generation with IDE support

### 📦 Development Tools
- **Pub.dev Optimization**: Analyze and optimize packages for maximum discoverability
- **Smart Linting**: Flutter-specific best practices with auto-fixes
- **Project Maintenance**: Automatic import optimization and structure validation
- **Dependency Analysis**: Detect conflicts and suggest optimizations
- **Publication Utilities**: Pre-flight checks and automated publishing workflows

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_productivity_toolkit: ^0.1.0

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
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

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

## 📚 Documentation

### Getting Started
- **[Quick Start Guide](doc/quick_start.md)** - Build your first app in minutes
- **[Installation Guide](doc/installation.md)** - Detailed setup instructions
- **[Configuration Guide](doc/configuration.md)** - Customize the toolkit for your needs

### Core Features
- **[State Management](doc/state_management.md)** - Reactive state with automatic persistence
- **[Navigation & Routing](doc/navigation.md)** - Type-safe navigation with deep linking
- **[Testing Utilities](doc/testing.md)** - Comprehensive testing framework
- **[Performance Monitoring](doc/performance.md)** - Real-time performance insights
- **[Code Generation](doc/code_generation.md)** - Automatic boilerplate reduction
- **[Development Tools](doc/development_tools.md)** - Workflow optimization utilities

### Migration Guides
- **[From Provider](doc/migration/from_provider.md)** - Step-by-step Provider migration
- **[From Bloc](doc/migration/from_bloc.md)** - Migrate from Bloc pattern
- **[From Riverpod](doc/migration/from_riverpod.md)** - Transition from Riverpod
- **[From GoRouter](doc/migration/from_go_router.md)** - Switch from GoRouter

### Reference & Support
- **[API Reference](doc/api_reference.md)** - Complete API documentation
- **[Troubleshooting](doc/troubleshooting.md)** - Common issues and solutions
- **[FAQ](doc/faq.md)** - Frequently asked questions
- **[Best Practices](doc/best_practices.md)** - Recommended patterns and guidelines

## 🎯 Examples

Explore our comprehensive examples to see the toolkit in action:

- **[Todo App](example/state_management_example.dart)** - Complete state management showcase
- **[Navigation Demo](example/navigation_showcase_example.dart)** - Advanced routing patterns
- **[Performance Monitor](example/performance_monitoring_example.dart)** - Real-time performance tracking
- **[Code Generation](example/code_generation_example.dart)** - Automatic code generation examples
- **[Pub Optimizer](example/pub_optimizer_example.dart)** - Package optimization tools

**[📁 View All Examples](example/README.md)** - Complete example applications with detailed explanations

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- [GitHub Issues](https://github.com/r00texploit/flutter_productivity_toolkit/issues)
- [Discussions](https://github.com/r00texploit/flutter_productivity_toolkit/discussions)
- [Documentation](https://pub.dev/documentation/flutter_productivity_toolkit/latest/)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and updates.