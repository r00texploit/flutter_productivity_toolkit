/// Flutter Developer Productivity Toolkit
///
/// A comprehensive package that addresses the most critical pain points
/// faced by Flutter developers. Provides unified solutions for state
/// management, navigation, testing utilities, and development workflow
/// optimization.
library flutter_dev_toolkit;

// Annotations for code generation
export 'src/annotations/generate_model.dart';
export 'src/annotations/generate_route.dart' hide RouteGuard;
export 'src/annotations/generate_state.dart';

// Code generation
export 'src/code_generation/code_generator.dart' hide WarningType;

// Configuration
export 'src/configuration/toolkit_configuration.dart';

// Development tools
export 'src/development_tools/pub_optimizer.dart';

// Error handling
export 'src/errors/error_reporter.dart';
export 'src/errors/toolkit_error.dart';

// Navigation
export 'src/navigation/route_builder.dart';

// Performance monitoring
export 'src/performance/performance_monitor.dart';

// State management
export 'src/state_management/state_manager.dart';

// Testing utilities
export 'src/testing/test_helper.dart';
