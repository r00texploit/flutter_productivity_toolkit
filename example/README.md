# Flutter Dev Toolkit Examples

This directory contains comprehensive examples demonstrating all the features and capabilities of the Flutter Developer Productivity Toolkit. Each example is a complete, runnable application that showcases specific aspects of the toolkit.

## Quick Start

To run the comprehensive examples index:

```bash
flutter run example/comprehensive_examples_index.dart
```

This will launch an interactive menu where you can explore all available examples.

## Individual Examples

### 1. State Management Example

**File:** `state_management_example.dart`

**Run:** `flutter run example/state_management_example.dart`

**Features Demonstrated:**
- Reactive state updates with automatic widget rebuilds
- State persistence and restoration using local storage
- Dependency injection with automatic lifecycle management
- State debugging and transition history tracking
- Multiple state managers working together
- State provider statistics and management

**Key Components:**
- `ReactiveStateManager<T>` - Core state management with reactive updates
- `DefaultStateProvider` - Dependency injection container
- `StateDebugger` - Development-time debugging utilities
- `StateConfiguration` - Flexible configuration options

### 2. Navigation Showcase Example

**File:** `navigation_showcase_example.dart`

**Run:** `flutter run example/navigation_showcase_example.dart`

**Features Demonstrated:**
- Type-safe route definitions with parameter validation
- Deep link handling with automatic parameter extraction
- Multiple navigation stacks for complex UI scenarios
- Route guards and authentication integration
- Navigation history preservation and state management
- Custom route transitions and animations

**Key Components:**
- `DefaultRouteBuilder` - Core navigation system
- `DefaultNavigationStack` - Navigation history management
- `RouteGuard` - Authentication and access control
- `DeepLinkConfiguration` - URL scheme handling
- `NavigationTestHelper` - Testing utilities

### 3. Performance Monitoring Example

**File:** `performance_monitoring_example.dart`

**Run:** `flutter run example/performance_monitoring_example.dart`

**Features Demonstrated:**
- Real-time widget rebuild tracking with visual indicators
- Memory leak detection with actionable recommendations
- Frame drop analysis and bottleneck identification
- Custom performance metric collection and reporting
- Performance benchmark utilities and comparisons
- Performance trend analysis and alerting

**Key Components:**
- `PerformanceToolkit` - Main performance monitoring interface
- `PerformanceMonitor` - Real-time metrics collection
- `RebuildIndicator` - Visual rebuild tracking widget
- `PerformanceReporter` - Report generation and analysis

### 4. Code Generation Example

**File:** `code_generation_example.dart`

**Run:** `flutter run example/code_generation_example.dart`

**Features Demonstrated:**
- Data model generation with serialization methods
- Route generation from annotations
- State management code generation
- API client generation patterns
- Validation and form generation
- Localization code generation patterns

**Key Annotations:**
- `@GenerateModel` - Automatic data class generation
- `@GenerateRoute` - Type-safe route generation
- `@GenerateState` - State management boilerplate
- `@JsonField` - Custom serialization behavior
- `@Validate` - Validation rule generation

### 5. Pub Optimizer Example

**File:** `pub_optimizer_example.dart`

**Run:** `dart run example/pub_optimizer_example.dart`

**Features Demonstrated:**
- Package metadata analysis and optimization suggestions
- API documentation completeness checking
- Example validation for all public APIs
- Dependency conflict detection and optimization
- Publication readiness assessment and scoring
- Automated package optimization workflows

**Key Components:**
- `PubOptimizerImpl` - Core optimization engine
- `PublicationUtilities` - Publication workflow management
- `PackageAnalysis` - Comprehensive package assessment
- `PublicationChecklist` - Pre-flight validation

## Example Architecture

All examples follow a consistent architecture pattern:

```
example/
├── comprehensive_examples_index.dart  # Main examples launcher
├── state_management_example.dart      # State management demo
├── navigation_showcase_example.dart   # Navigation features demo
├── performance_monitoring_example.dart # Performance tools demo
├── code_generation_example.dart       # Code generation demo
├── pub_optimizer_example.dart         # Pub optimization demo
└── README.md                          # This documentation
```

## Running Examples

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (included with Flutter)
- IDE with Flutter support (VS Code, Android Studio, or IntelliJ)

### Individual Example Execution

Each example can be run independently:

```bash
# State Management
flutter run example/state_management_example.dart

# Navigation Showcase
flutter run example/navigation_showcase_example.dart

# Performance Monitoring
flutter run example/performance_monitoring_example.dart

# Code Generation
flutter run example/code_generation_example.dart

# Pub Optimizer (command-line only)
dart run example/pub_optimizer_example.dart
```

### Development Mode

For development and testing, you can run examples in debug mode:

```bash
flutter run --debug example/[example_name].dart
```

## Example Features

### Interactive Demonstrations

Each example includes:
- **Live Demonstrations** - Interactive widgets showing real functionality
- **Code Samples** - Generated code examples and patterns
- **Debug Information** - Real-time debugging and monitoring data
- **Performance Metrics** - Live performance data and analysis
- **Testing Utilities** - Built-in testing and validation tools

### Educational Content

Examples provide:
- **Step-by-step Tutorials** - Guided walkthroughs of features
- **Best Practices** - Recommended usage patterns
- **Common Patterns** - Real-world implementation examples
- **Troubleshooting** - Error handling and debugging techniques
- **Performance Tips** - Optimization recommendations

## Integration Examples

### Combining Features

The examples also demonstrate how to combine multiple toolkit features:

1. **State + Navigation** - State-aware routing and navigation
2. **Performance + State** - Performance monitoring of state changes
3. **Code Generation + Validation** - Generated models with validation
4. **Navigation + Testing** - Navigation testing utilities
5. **All Features** - Comprehensive integration patterns

### Real-world Scenarios

Examples include realistic use cases:
- **E-commerce App** - Product catalog with cart management
- **Social Media** - User profiles and content management
- **Dashboard** - Analytics and data visualization
- **Settings** - Configuration and preferences management
- **Authentication** - Login flows and protected routes

## Testing the Examples

### Unit Testing

Run unit tests for example components:

```bash
flutter test test/
```

### Integration Testing

Run integration tests:

```bash
flutter test integration_test/
```

### Performance Testing

Run performance benchmarks:

```bash
flutter test --profile test/performance/
```

## Customization

### Modifying Examples

Examples are designed to be easily customizable:

1. **Configuration** - Modify settings and parameters
2. **Styling** - Update themes and visual appearance
3. **Data** - Replace sample data with your own
4. **Features** - Add or remove functionality
5. **Integration** - Connect to real backends and services

### Creating New Examples

To create a new example:

1. Create a new `.dart` file in the `example/` directory
2. Follow the existing example structure and patterns
3. Add comprehensive documentation and comments
4. Include interactive demonstrations and explanations
5. Update this README with the new example information

## Troubleshooting

### Common Issues

1. **Dependencies** - Ensure all required packages are installed
2. **Flutter Version** - Use the latest stable Flutter version
3. **Platform Support** - Some features may be platform-specific
4. **Performance** - Examples may be resource-intensive in debug mode

### Getting Help

- Check the main package documentation
- Review example source code and comments
- Run examples in debug mode for detailed error information
- Use the built-in debugging and monitoring tools

## Contributing

To contribute new examples or improvements:

1. Fork the repository
2. Create a new example following existing patterns
3. Add comprehensive documentation
4. Test thoroughly on multiple platforms
5. Submit a pull request with detailed description

## License

These examples are part of the Flutter Developer Productivity Toolkit and are subject to the same license terms as the main package.