/// Flutter Developer Productivity Toolkit
///
/// A comprehensive package that addresses the most critical pain points
/// faced by Flutter developers. Provides unified solutions for state
/// management, navigation, testing utilities, and development workflow
/// optimization.
library;

// Annotations for code generation
export 'src/annotations/generate_model.dart';
export 'src/annotations/generate_route.dart';
export 'src/annotations/generate_state.dart';
// Code generation
export 'src/code_generation/code_generator.dart' hide WarningType;
// Configuration
export 'src/configuration/toolkit_configuration.dart';
// Development tools
export 'src/development_tools/project_maintenance.dart';
export 'src/development_tools/pub_optimizer.dart';
export 'src/development_tools/pub_optimizer_impl.dart';
export 'src/development_tools/publication_utilities.dart';
export 'src/development_tools/workflow_tools.dart';
// Error handling
export 'src/errors/async_stack_trace_enhancer.dart';
export 'src/errors/enhanced_error_handler.dart';
export 'src/errors/error_reporter.dart';
export 'src/errors/integrated_debugging_system.dart';
export 'src/errors/platform_issue_detector.dart'
    hide ConfigurationIssue, IssueSeverity;
export 'src/errors/toolkit_error.dart';
export 'src/errors/widget_debugger.dart' hide PerformanceIssue;
// Navigation
export 'src/navigation/route_builder.dart';
// Performance monitoring
export 'src/performance/flutter_performance_monitor.dart';
export 'src/performance/performance_monitor.dart';
export 'src/performance/performance_reporter.dart';
export 'src/performance/performance_toolkit.dart';
export 'src/performance/widget_rebuild_tracker.dart';
// State management
export 'src/state_management/state_manager.dart';
// Testing utilities
export 'src/testing/test_helper.dart';
