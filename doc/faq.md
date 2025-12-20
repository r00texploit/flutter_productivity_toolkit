# Frequently Asked Questions (FAQ)

## General Questions

### What is the Flutter Developer Productivity Toolkit?

The Flutter Developer Productivity Toolkit is a comprehensive package that addresses the most critical pain points faced by Flutter developers. It provides unified solutions for state management, navigation, testing utilities, performance monitoring, code generation, and development workflow optimization.

### Why should I use this toolkit instead of individual packages?

The toolkit offers several advantages over using separate packages:

- **Unified API**: All components work together seamlessly
- **Reduced Configuration**: Minimal setup required with sensible defaults
- **Type Safety**: Compile-time code generation prevents runtime errors
- **Integrated Testing**: Built-in testing utilities that work with all components
- **Performance Monitoring**: Real-time insights into your app's performance
- **Consistent Patterns**: All features follow the same architectural principles

### Is this toolkit suitable for production apps?

Yes, the toolkit is designed for production use with:
- Comprehensive testing coverage
- Performance optimizations for production builds
- Minimal runtime overhead
- Extensive error handling and recovery mechanisms
- Battle-tested patterns and best practices

## Installation and Setup

### What are the minimum requirements?

- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher
- build_runner ^2.4.7 (for code generation)

### Do I need to use all features of the toolkit?

No, the toolkit is designed for incremental adoption. You can use individual features independently:

```dart
// Use only state management
dependencies:
  flutter_dev_toolkit: ^0.1.0

// In your code, only import what you need
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart' 
    show StateManager, GenerateState;
```

### How do I migrate from existing solutions?

We provide comprehensive migration guides:
- [From Provider](migration/from_provider.md)
- [From Bloc](migration/from_bloc.md)
- [From Riverpod](migration/from_riverpod.md)
- [From GoRouter](migration/from_go_router.md)

## State Management

### How does the state management compare to Provider/Bloc/Riverpod?

| Feature | Provider | Bloc | Riverpod | Toolkit |
|---------|----------|------|----------|---------|
| Boilerplate | Medium | High | Low | Minimal |
| Type Safety | Runtime | Compile-time | Compile-time | Compile-time |
| Code Generation | No | No | Partial | Full |
| Persistence | Manual | Manual | Manual | Built-in |
| Testing | Manual mocks | Built-in | Built-in | Automatic |
| Performance | Good | Excellent | Excellent | Excellent |

### Can I use the toolkit with existing state management solutions?

While possible, it's not recommended as it can lead to confusion and complexity. The toolkit is designed to replace existing state management solutions entirely. However, you can migrate gradually by converting one feature at a time.

### How does state persistence work?

State persistence is automatic when enabled:

```dart
@GenerateState(persist: true, storageKey: 'my_state')
class MyState {
  // State automatically saved to local storage
  // and restored on app restart
}
```

The toolkit uses `shared_preferences` by default but supports custom storage backends.

### What happens if state persistence fails?

The toolkit handles persistence failures gracefully:
- Falls back to default state if loading fails
- Continues normal operation without persistence
- Logs errors for debugging
- Provides callbacks for custom error handling

## Navigation

### How does the navigation system work with existing Flutter navigation?

The toolkit's navigation system is built on top of Flutter's navigation but provides additional features:
- Type-safe route definitions
- Automatic parameter validation
- Enhanced deep linking
- Built-in route guards

It's compatible with existing Flutter navigation patterns but provides a more robust alternative.

### Can I use the toolkit navigation with web apps?

Yes, the navigation system fully supports Flutter web with:
- URL-based routing
- Browser back/forward button support
- Deep linking from external sources
- SEO-friendly URLs

### How do I handle complex nested navigation?

The toolkit supports multiple navigation stacks:

```dart
@GenerateRoute('/main', layout: MainLayoutRoute)
class MainRoute {
  final String tab;
  const MainRoute({this.tab = 'home'});
}

// Automatically handles nested navigation within layouts
```

## Code Generation

### Why do I need to run build_runner?

Code generation creates boilerplate code automatically:
- State managers from state classes
- Route builders from route definitions
- Data models with serialization
- API clients from specifications

This eliminates manual coding and prevents errors.

### How often should I run code generation?

During development, use watch mode:
```bash
flutter packages pub run build_runner watch
```

For production builds:
```bash
flutter packages pub run build_runner build --release
```

### What if code generation fails?

Common solutions:
1. Clean and rebuild: `flutter packages pub run build_runner clean`
2. Check annotation syntax
3. Verify import statements
4. Review error messages in console

See [Troubleshooting Guide](troubleshooting.md) for detailed solutions.

### Can I customize the generated code?

The toolkit provides configuration options for customization:

```dart
@GenerateState(
  persist: true,
  storageKey: 'custom_key',
  generateEquality: true,
  generateToString: true,
)
class MyState {
  // Customized generation
}
```

## Testing

### How does testing work with the toolkit?

The toolkit provides comprehensive testing utilities:

```dart
void main() {
  late TestEnvironment testEnv;
  
  setUp(() async {
    testEnv = await TestHelper().setupTestEnvironment();
  });
  
  testWidgets('my test', (tester) async {
    final mockState = testEnv.helper.createMockState<MyStateManager>();
    
    await testEnv.helper.pumpAndSettle(
      tester,
      MyWidget(),
      providers: [mockState],
    );
    
    // Test assertions...
  });
}
```

### Do I need to write mocks manually?

No, the toolkit automatically generates mocks for all state managers and provides utilities for creating test data.

### How do I test navigation?

Use the navigation testing utilities:

```dart
testWidgets('navigation test', (tester) async {
  await testEnv.navigation.simulateNavigation<UserRoute>(
    UserRoute(userId: '123'),
  );
  
  expect(testEnv.navigation.currentRoute, isA<UserRoute>());
});
```

### Can I use the toolkit with existing test frameworks?

Yes, the toolkit works with:
- flutter_test (built-in)
- mockito
- mocktail
- integration_test
- patrol (for end-to-end testing)

## Performance

### Does the toolkit impact app performance?

The toolkit is designed for minimal performance impact:
- Zero runtime overhead in production builds
- Optimized state updates with selective rebuilds
- Efficient memory management
- Built-in performance monitoring to identify bottlenecks

### How does performance monitoring work?

Performance monitoring runs only in debug mode:

```dart
final monitor = PerformanceMonitor();
monitor.startMonitoring();

monitor.metricsStream.listen((metrics) {
  if (!metrics.isPerformanceGood) {
    print('Performance issues: ${metrics.warnings}');
  }
});
```

### Can I disable performance monitoring?

Yes, configure it in your toolkit setup:

```dart
final config = ToolkitConfiguration(
  performance: PerformanceConfig(
    enableMonitoring: false, // Disable monitoring
  ),
);
```

### What performance metrics are tracked?

- Widget rebuild frequency
- Memory usage and leaks
- Frame drops and rendering performance
- Custom metrics you define
- Navigation performance
- State update performance

## Development Tools

### What development tools are included?

The toolkit includes:
- Package optimization for pub.dev publishing
- Real-time Flutter-specific linting
- Automatic asset reference generation
- Dependency conflict detection
- Project structure validation
- Import statement optimization

### How do I optimize my package for pub.dev?

Use the pub optimizer:

```dart
final optimizer = PubOptimizer();
final report = await optimizer.analyzePackage('path/to/package');

print('Optimization suggestions: ${report.suggestions}');
```

### Can I customize the development tools?

Yes, most tools are configurable:

```dart
final config = DevelopmentToolsConfig(
  enableLinting: true,
  lintingRules: CustomLintRules(),
  enableAssetGeneration: true,
  assetGenerationConfig: AssetConfig(),
);
```

## Error Handling and Debugging

### How does error handling work?

The toolkit provides enhanced error handling:
- Detailed error messages with suggested solutions
- Automatic error recovery where possible
- Error reporting and analytics
- Visual debugging tools

### What debugging tools are available?

- State timeline visualization
- Widget tree inspection
- Performance profiling
- Memory leak detection
- Navigation flow tracking

### How do I report bugs or issues?

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Search [existing issues](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/issues)
3. Create a new issue with:
   - Flutter version
   - Toolkit version
   - Minimal reproduction code
   - Error messages and stack traces

## Best Practices

### What are the recommended patterns?

1. **State Management**: Use immutable state with pure functions
2. **Navigation**: Define routes with type-safe parameters
3. **Testing**: Write both unit and integration tests
4. **Performance**: Monitor and optimize regularly
5. **Code Organization**: Follow the generated file structure

### How should I structure my project?

Recommended structure:
```
lib/
  models/          # State classes and data models
  routes/          # Route definitions
  screens/         # UI screens
  services/        # Business logic services
  widgets/         # Reusable widgets
  generated/       # Generated code (auto-created)
```

### What should I avoid?

- Mixing state management approaches
- Ignoring performance warnings
- Skipping code generation
- Not writing tests
- Manual state mutations
- String-based navigation

## Compatibility

### Which Flutter versions are supported?

- Flutter 3.0.0+ (stable channel recommended)
- Dart 2.17.0+
- All platforms: iOS, Android, Web, Desktop

### Does it work with Flutter Web?

Yes, full web support including:
- URL-based routing
- Browser navigation
- Local storage persistence
- Performance monitoring (limited)

### What about Flutter Desktop?

Full desktop support for:
- Windows
- macOS
- Linux

Some features like performance monitoring may have platform-specific limitations.

### Can I use it with existing packages?

The toolkit is designed to work alongside most Flutter packages. However, avoid mixing with other state management or navigation solutions to prevent conflicts.

## Licensing and Support

### What license is the toolkit under?

The toolkit is released under the MIT License, allowing free use in both open-source and commercial projects.

### Is commercial support available?

Currently, support is provided through:
- GitHub Issues for bugs
- GitHub Discussions for questions
- Community forums and Discord

### How can I contribute?

We welcome contributions! See our [Contributing Guide](../CONTRIBUTING.md) for details on:
- Code contributions
- Documentation improvements
- Bug reports
- Feature requests

### Where can I get help?

1. **Documentation**: Start with our comprehensive guides
2. **Examples**: Check the [examples directory](../example/)
3. **GitHub Issues**: For bugs and feature requests
4. **GitHub Discussions**: For questions and community support
5. **Stack Overflow**: Tag questions with `flutter-dev-toolkit`

## Future Roadmap

### What features are planned?

Upcoming features include:
- Enhanced code generation capabilities
- Additional platform integrations
- Advanced performance analytics
- More migration tools
- Extended testing utilities

### How can I request features?

1. Check existing [feature requests](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Create a new issue with the `enhancement` label
3. Participate in [discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)

### Will the API remain stable?

We follow semantic versioning:
- Major versions may include breaking changes
- Minor versions add features without breaking existing code
- Patch versions fix bugs without breaking changes

Migration guides are provided for any breaking changes.

---

## Still Have Questions?

If your question isn't answered here:

1. Search the [documentation](README.md)
2. Check [GitHub Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)
3. Review [existing issues](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/issues)
4. Ask a new question in [Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions/new)