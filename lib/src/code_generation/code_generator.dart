import 'dart:async';

/// Abstract base class for code generators in the Flutter Dev Toolkit.
///
/// Provides automated code generation for common patterns to reduce
/// boilerplate and maintain consistency across the codebase.
abstract class CodeGenerator {
  /// Generates state manager implementations from annotated classes.
  ///
  /// Scans for classes annotated with @GenerateState and creates
  /// corresponding state manager implementations with reactive updates
  /// and optional persistence.
  Future<void> generateStateManagers(BuildStep buildStep);

  /// Generates type-safe route definitions from annotated methods.
  ///
  /// Scans for methods annotated with @GenerateRoute and creates
  /// corresponding route definitions with parameter validation
  /// and deep link support.
  Future<void> generateRoutes(BuildStep buildStep);

  /// Generates data model classes with serialization methods.
  ///
  /// Scans for classes annotated with @GenerateModel and creates
  /// corresponding data models with JSON serialization, equality,
  /// and copy methods.
  Future<void> generateDataModels(BuildStep buildStep);

  /// Generates API client methods from OpenAPI specifications.
  ///
  /// Reads OpenAPI/Swagger specifications and generates type-safe
  /// HTTP client methods with request/response models.
  Future<void> generateApiClients(BuildStep buildStep);

  /// Generates localization access methods from translation files.
  ///
  /// Scans translation files and generates type-safe access methods
  /// for internationalization keys.
  Future<void> generateLocalization(BuildStep buildStep);
}

/// Concrete implementation of the code generator.
class FlutterDevToolkitCodeGenerator implements CodeGenerator {
  const FlutterDevToolkitCodeGenerator();

  @override
  Future<void> generateStateManagers(BuildStep buildStep) async {
    // Implementation delegated to StateManagerGenerator
    // This would be called by the build_runner system
    print('Generating state managers for ${buildStep.inputId}');
  }

  @override
  Future<void> generateRoutes(BuildStep buildStep) async {
    // Implementation delegated to RouteGenerator
    // This would be called by the build_runner system
    print('Generating routes for ${buildStep.inputId}');
  }

  @override
  Future<void> generateDataModels(BuildStep buildStep) async {
    // Implementation delegated to DataModelGenerator
    // This would be called by the build_runner system
    print('Generating data models for ${buildStep.inputId}');
  }

  @override
  Future<void> generateApiClients(BuildStep buildStep) async {
    // Implementation delegated to ApiClientGenerator
    // This would be called by the build_runner system
    print('Generating API clients for ${buildStep.inputId}');
  }

  @override
  Future<void> generateLocalization(BuildStep buildStep) async {
    // Implementation delegated to LocalizationGenerator
    // This would be called by the build_runner system
    print('Generating localization for ${buildStep.inputId}');
  }
}

/// Represents a build step in the code generation process.
class BuildStep {
  /// Creates a new build step.
  const BuildStep({required this.inputId});

  /// The input asset being processed.
  final String inputId;
}

/// Configuration for code generation behavior.
class GenerationConfiguration {
  /// Creates a new generation configuration.
  const GenerationConfiguration({
    this.includeDebugInfo = false,
    this.generateDocumentation = true,
    this.outputDirectory = 'lib/generated',
    this.namingConvention = NamingConvention.snakeCase,
    this.formatOutput = true,
  });

  /// Whether to generate debug information in generated code.
  final bool includeDebugInfo;

  /// Whether to generate documentation comments.
  final bool generateDocumentation;

  /// Output directory for generated files.
  final String outputDirectory;

  /// File naming convention for generated files.
  final NamingConvention namingConvention;

  /// Whether to format generated code.
  final bool formatOutput;
}

/// Naming conventions for generated files and classes.
enum NamingConvention {
  /// snake_case naming (recommended for Dart).
  snakeCase,

  /// camelCase naming.
  camelCase,

  /// PascalCase naming.
  pascalCase,

  /// kebab-case naming.
  kebabCase,
}

/// Result of a code generation operation.
class GenerationResult {
  /// Creates a new generation result.
  const GenerationResult({
    required this.success,
    required this.generatedFiles,
    required this.errors,
    required this.warnings,
    this.metrics,
  });

  /// Whether the generation was successful.
  final bool success;

  /// List of files that were generated or modified.
  final List<String> generatedFiles;

  /// Any errors that occurred during generation.
  final List<GenerationError> errors;

  /// Any warnings generated during the process.
  final List<GenerationWarning> warnings;

  /// Performance metrics for the generation process.
  final GenerationMetrics? metrics;

  /// Whether there were any errors during generation.
  bool get hasErrors => errors.isNotEmpty;

  /// Whether there were any warnings during generation.
  bool get hasWarnings => warnings.isNotEmpty;

  @override
  String toString() => 'GenerationResult('
      'success: $success, '
      'files: ${generatedFiles.length}, '
      'errors: ${errors.length}, '
      'warnings: ${warnings.length}'
      ')';
}

/// Error that occurred during code generation.
class GenerationError {
  /// Creates a new generation error.
  const GenerationError({
    required this.type,
    required this.message,
    this.sourceFile,
    this.lineNumber,
    this.columnNumber,
    this.stackTrace,
  });

  /// Type of error that occurred.
  final ErrorType type;

  /// Human-readable error message.
  final String message;

  /// Source file where the error occurred.
  final String? sourceFile;

  /// Line number where the error occurred.
  final int? lineNumber;

  /// Column number where the error occurred.
  final int? columnNumber;

  /// Stack trace if available.
  final StackTrace? stackTrace;

  @override
  String toString() => 'GenerationError('
      'type: $type, '
      'message: $message'
      '${sourceFile != null ? ', file: $sourceFile' : ''}'
      '${lineNumber != null ? ':$lineNumber' : ''}'
      ')';
}

/// Warning generated during code generation.
class GenerationWarning {
  /// Creates a new generation warning.
  const GenerationWarning({
    required this.type,
    required this.message,
    this.sourceFile,
    this.lineNumber,
  });

  /// Type of warning.
  final WarningType type;

  /// Human-readable warning message.
  final String message;

  /// Source file where the warning occurred.
  final String? sourceFile;

  /// Line number where the warning occurred.
  final int? lineNumber;

  @override
  String toString() => 'GenerationWarning('
      'type: $type, '
      'message: $message'
      '${sourceFile != null ? ', file: $sourceFile' : ''}'
      ')';
}

/// Performance metrics for code generation.
class GenerationMetrics {
  /// Creates new generation metrics.
  const GenerationMetrics({
    required this.totalTime,
    required this.phaseTimings,
    required this.filesProcessed,
    required this.annotationsProcessed,
    required this.linesGenerated,
  });

  /// Total time taken for generation.
  final Duration totalTime;

  /// Time taken for each generation phase.
  final Map<String, Duration> phaseTimings;

  /// Number of files processed.
  final int filesProcessed;

  /// Number of annotations processed.
  final int annotationsProcessed;

  /// Amount of code generated (in lines).
  final int linesGenerated;

  @override
  String toString() => 'GenerationMetrics('
      'totalTime: ${totalTime.inMilliseconds}ms, '
      'files: $filesProcessed, '
      'annotations: $annotationsProcessed, '
      'lines: $linesGenerated'
      ')';
}

/// Types of errors that can occur during generation.
enum ErrorType {
  /// Syntax error in source code.
  syntaxError,

  /// Invalid annotation usage.
  invalidAnnotation,

  /// Missing required dependency.
  missingDependency,

  /// File system error (read/write).
  fileSystemError,

  /// Template processing error.
  templateError,

  /// Type resolution error.
  typeResolutionError,

  /// Configuration error.
  configurationError,

  /// Unknown or unexpected error.
  unknown,
}

/// Types of warnings that can be generated.
enum WarningType {
  /// Deprecated API usage detected.
  deprecatedApi,

  /// Potential performance issue.
  performanceIssue,

  /// Code style issue.
  styleIssue,

  /// Missing documentation.
  missingDocumentation,

  /// Unused generated code.
  unusedCode,

  /// Potential naming conflict.
  namingConflict,
}

/// Context information for code generation.
class GenerationContext {
  /// Creates a new generation context.
  const GenerationContext({
    required this.buildStep,
    required this.configuration,
    required this.resolver,
    required this.cache,
  });

  /// The build step being processed.
  final BuildStep buildStep;

  /// Configuration for this generation run.
  final GenerationConfiguration configuration;

  /// Resolver for type information.
  final Resolver resolver;

  /// Cache for expensive operations.
  final Map<String, dynamic> cache;
}

/// Mock resolver for type information.
class Resolver {
  /// Creates a new resolver.
  const Resolver();
}

/// Template for generating code with placeholders.
class CodeTemplate {
  /// Creates a new code template.
  const CodeTemplate({
    required this.template,
    this.defaults = const {},
    this.formatOutput = true,
  });

  /// The template content with placeholders.
  final String template;

  /// Default values for template placeholders.
  final Map<String, String> defaults;

  /// Whether to format the output after substitution.
  final bool formatOutput;

  /// Renders the template with the provided values.
  String render(Map<String, String> values) {
    var result = template;
    final allValues = {...defaults, ...values};

    for (final entry in allValues.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }

    return formatOutput ? _formatDartCode(result) : result;
  }

  String _formatDartCode(String code) => code;
}
