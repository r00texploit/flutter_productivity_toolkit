import 'dart:io';
import 'package:flutter_dev_toolkit/src/development_tools/pub_optimizer.dart';
import 'package:flutter_dev_toolkit/src/development_tools/pub_optimizer_impl.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('PubOptimizer Implementation', () {
    late PubOptimizer optimizer;
    late Directory tempDir;
    late String packagePath;

    setUp(() async {
      optimizer = const PubOptimizerImpl();
      tempDir = await Directory.systemTemp.createTemp('pub_optimizer_test');
      packagePath = tempDir.path;
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Package Analysis', () {
      test('should analyze complete package correctly', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final analysis = await optimizer.analyzePackage(packagePath);

        // Assert
        expect(analysis.qualityScore, greaterThan(70));
        expect(analysis.pubspecAnalysis.hasRequiredFields, isTrue);
        expect(analysis.readmeAnalysis.exists, isTrue);
        expect(analysis.changelogAnalysis.exists, isTrue);
        expect(analysis.licenseAnalysis.exists, isTrue);
        expect(analysis.meetsBasicRequirements, isTrue);
      });

      test('should identify missing files and metadata', () async {
        // Arrange - create minimal package with only pubspec
        await _createMinimalPubspec(packagePath);

        // Act
        final analysis = await optimizer.analyzePackage(packagePath);

        // Assert
        expect(analysis.qualityScore, lessThan(50));
        expect(analysis.readmeAnalysis.exists, isFalse);
        expect(analysis.changelogAnalysis.exists, isFalse);
        expect(analysis.licenseAnalysis.exists, isFalse);
        expect(analysis.meetsBasicRequirements, isFalse);
        expect(analysis.issues.length, greaterThan(0));
        expect(analysis.suggestions.length, greaterThan(0));
      });

      test('should score description quality correctly', () async {
        // Arrange
        await _createPubspecWithDescription(packagePath, 'Short desc');

        // Act
        final analysis = await optimizer.analyzePackage(packagePath);

        // Assert
        expect(analysis.pubspecAnalysis.descriptionScore, lessThan(80));
      });

      test('should detect valid URLs in pubspec', () async {
        // Arrange
        await _createPubspecWithUrls(packagePath);

        // Act
        final analysis = await optimizer.analyzePackage(packagePath);

        // Assert
        expect(analysis.pubspecAnalysis.hasValidHomepage, isTrue);
        expect(analysis.pubspecAnalysis.hasValidRepository, isTrue);
        expect(analysis.pubspecAnalysis.hasValidIssueTracker, isTrue);
      });
    });

    group('Documentation Analysis', () {
      test('should analyze documentation coverage', () async {
        // Arrange
        await _createPackageWithDocumentation(packagePath);

        // Act
        final analysis = await optimizer.analyzeDocumentation(packagePath);

        // Assert
        expect(analysis.coveragePercentage, greaterThan(0));
        expect(analysis.meetsStandards, isTrue);
      });

      test('should identify undocumented APIs', () async {
        // Arrange
        await _createPackageWithUndocumentedApis(packagePath);

        // Act
        final analysis = await optimizer.analyzeDocumentation(packagePath);

        // Assert
        expect(analysis.undocumentedApis, greaterThan(0));
        expect(analysis.issues.length, greaterThan(0));
        expect(analysis.suggestions.length, greaterThan(0));
      });

      test('should handle package without lib directory', () async {
        // Arrange - create package without lib directory
        await _createMinimalPubspec(packagePath);

        // Act
        final analysis = await optimizer.analyzeDocumentation(packagePath);

        // Assert
        expect(analysis.coveragePercentage, equals(0.0));
        expect(analysis.undocumentedApis, equals(0));
      });
    });

    group('Example Validation', () {
      test('should validate working examples', () async {
        // Arrange
        await _createPackageWithWorkingExamples(packagePath);

        // Act
        final validation = await optimizer.validateExamples(packagePath);

        // Assert
        expect(validation.workingExamples, greaterThan(0));
        expect(validation.brokenExamples, equals(0));
        expect(validation.meetsStandards, isTrue);
      });

      test('should identify broken examples', () async {
        // Arrange
        await _createPackageWithBrokenExamples(packagePath);

        // Act
        final validation = await optimizer.validateExamples(packagePath);

        // Assert
        expect(validation.brokenExamples, greaterThan(0));
        expect(validation.failedExamples.length, greaterThan(0));
        expect(validation.meetsStandards, isFalse);
      });

      test('should suggest creating examples when missing', () async {
        // Arrange - create package without examples
        await _createMinimalPubspec(packagePath);

        // Act
        final validation = await optimizer.validateExamples(packagePath);

        // Assert
        expect(validation.suggestions.length, greaterThan(0));
        expect(validation.suggestions.first.suggestion,
            contains('Create an example directory'),);
      });
    });

    group('Dependency Analysis', () {
      test('should analyze dependencies correctly', () async {
        // Arrange
        await _createPubspecWithDependencies(packagePath);

        // Act
        final analysis = await optimizer.analyzeDependencies(packagePath);

        // Assert
        expect(analysis.directDependencies, greaterThan(0));
        expect(analysis.totalDependencies,
            greaterThan(analysis.directDependencies),);
      });

      test('should identify dependency optimization opportunities', () async {
        // Arrange
        await _createPubspecWithProblematicDependencies(packagePath);

        // Act
        final analysis = await optimizer.analyzeDependencies(packagePath);

        // Assert
        expect(analysis.optimizations.length, greaterThan(0));
      });

      test('should handle package without dependencies', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final analysis = await optimizer.analyzeDependencies(packagePath);

        // Assert
        expect(analysis.directDependencies, equals(0));
        expect(analysis.conflicts, isEmpty);
      });
    });

    group('Pre-flight Checks', () {
      test('should pass pre-flight checks for complete package', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final report = await optimizer.performPreflightChecks(packagePath);

        // Assert
        expect(report.readyForPublication, isTrue);
        expect(report.readinessScore, greaterThan(70));
        expect(report.criticalIssues, isEmpty);
        expect(report.estimatedPubScore, greaterThan(0));
      });

      test('should fail pre-flight checks for incomplete package', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final report = await optimizer.performPreflightChecks(packagePath);

        // Assert
        expect(report.readyForPublication, isFalse);
        expect(report.criticalIssues.length, greaterThan(0));
        expect(report.warnings.length, greaterThan(0));
      });
    });

    group('Optimization Report Generation', () {
      test('should generate comprehensive optimization report', () async {
        // Arrange
        await _createPackageNeedingOptimization(packagePath);

        // Act
        final report = await optimizer.generateOptimizationReport(packagePath);

        // Assert
        expect(report.summary, isNotEmpty);
        expect(report.recommendations.length, greaterThan(0));
        expect(report.estimatedImpact.scoreImprovement, greaterThan(0));

        // Verify all analysis components are included
        expect(report.packageAnalysis, isNotNull);
        expect(report.documentationAnalysis, isNotNull);
        expect(report.exampleValidation, isNotNull);
        expect(report.dependencyAnalysis, isNotNull);
      });

      test('should prioritize recommendations correctly', () async {
        // Arrange
        await _createPackageNeedingOptimization(packagePath);

        // Act
        final report = await optimizer.generateOptimizationReport(packagePath);

        // Assert
        expect(report.recommendations, isNotEmpty);

        // Verify recommendations are sorted by priority
        for (var i = 0; i < report.recommendations.length - 1; i++) {
          final current = _priorityValue(report.recommendations[i].priority);
          final next = _priorityValue(report.recommendations[i + 1].priority);
          expect(current, greaterThanOrEqualTo(next));
        }
      });
    });

    group('Package Optimization', () {
      test('should perform dry run optimization', () async {
        // Arrange
        await _createPackageNeedingOptimization(packagePath);

        // Act
        final result =
            await optimizer.optimizePackage(packagePath);

        // Assert
        expect(result.success, isTrue);
        expect(result.changes.length, greaterThan(0));
        expect(result.errors, isEmpty);
        expect(result.metrics.processingTime, greaterThan(Duration.zero));

        // Verify no actual changes were made (dry run)
        for (final change in result.changes) {
          expect(change.change, contains('[DRY RUN]'));
        }
      });

      test('should perform actual optimization', () async {
        // Arrange
        await _createPackageNeedingOptimization(packagePath);

        // Act
        final result =
            await optimizer.optimizePackage(packagePath, dryRun: false);

        // Assert
        expect(result.success, isTrue);
        expect(result.changes.length, greaterThan(0));
        expect(result.errors, isEmpty);
        expect(result.metrics.filesProcessed, greaterThan(0));

        // Verify actual files were created/modified
        expect(File(path.join(packagePath, 'README.md')).existsSync(), isTrue);
        expect(
            File(path.join(packagePath, 'CHANGELOG.md')).existsSync(), isTrue,);
      });

      test('should handle optimization errors gracefully', () async {
        // Arrange - create invalid package path
        const invalidPath = '/invalid/path/that/does/not/exist';

        // Act
        final result = await optimizer.optimizePackage(invalidPath);

        // Assert
        expect(result.success, isFalse);
        expect(result.errors.length, greaterThan(0));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle non-existent package directory', () async {
        // Arrange
        const nonExistentPath = '/path/that/does/not/exist';

        // Act & Assert - should not throw
        final analysis = await optimizer.analyzePackage(nonExistentPath);
        expect(analysis.qualityScore, equals(0));
      });

      test('should handle malformed pubspec.yaml', () async {
        // Arrange
        await _createMalformedPubspec(packagePath);

        // Act & Assert - should not throw
        final analysis = await optimizer.analyzePackage(packagePath);
        expect(analysis.pubspecAnalysis.hasRequiredFields, isFalse);
      });

      test('should handle empty directories', () async {
        // Arrange - create empty package directory
        // (tempDir is already empty)

        // Act & Assert - should not throw
        final analysis = await optimizer.analyzePackage(packagePath);
        expect(analysis.qualityScore, lessThan(50));
      });
    });
  });
}

// Helper functions for creating test packages

Future<void> _createCompletePackage(String packagePath) async {
  await _createPubspecWithUrls(packagePath);
  await _createReadme(packagePath);
  await _createChangelog(packagePath);
  await _createLicense(packagePath);
  await _createLibDirectory(packagePath);
}

Future<void> _createMinimalPubspec(String packagePath) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: A test package
version: 1.0.0
''');
}

Future<void> _createPubspecWithDescription(
    String packagePath, String description,) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: $description
version: 1.0.0
''');
}

Future<void> _createPubspecWithUrls(String packagePath) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: A comprehensive test package for validating pub optimizer functionality
version: 1.0.0
homepage: https://github.com/example/test_package
repository: https://github.com/example/test_package
issue_tracker: https://github.com/example/test_package/issues

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''');
}

Future<void> _createPubspecWithDependencies(String packagePath) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: A test package with dependencies
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
  path: ^1.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
''');
}

Future<void> _createPubspecWithProblematicDependencies(
    String packagePath,) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: A test package with problematic dependencies
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  http: =1.0.0  # Overly restrictive
  path: any     # Overly permissive

dev_dependencies:
  flutter_test:
    sdk: flutter
''');
}

Future<void> _createMalformedPubspec(String packagePath) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: [invalid yaml structure
version: 1.0.0
  invalid_indentation: true
''');
}

Future<void> _createReadme(String packagePath) async {
  final readmeFile = File(path.join(packagePath, 'README.md'));
  await readmeFile.writeAsString('''
# Test Package

A comprehensive test package for validating pub optimizer functionality.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  test_package: ^1.0.0
```

## Usage

```dart
import 'package:test_package/test_package.dart';

void main() {
  final example = TestPackage();
  example.doSomething();
}
```

## Features

- Feature 1: Comprehensive testing
- Feature 2: Documentation validation
- Feature 3: Example verification

## API Documentation

See the [API documentation](https://pub.dev/documentation/test_package/latest/) for detailed usage information.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
''');
}

Future<void> _createChangelog(String packagePath) async {
  final changelogFile = File(path.join(packagePath, 'CHANGELOG.md'));
  await changelogFile.writeAsString('''
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Future enhancements

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Core functionality
- Comprehensive documentation
- Example applications

### BREAKING CHANGES
- Initial API design
''');
}

Future<void> _createLicense(String packagePath) async {
  final licenseFile = File(path.join(packagePath, 'LICENSE'));
  await licenseFile.writeAsString('''
MIT License

Copyright (c) 2024 Test Package

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''');
}

Future<void> _createLibDirectory(String packagePath) async {
  final libDir = Directory(path.join(packagePath, 'lib'));
  await libDir.create(recursive: true);

  final mainFile = File(path.join(libDir.path, 'test_package.dart'));
  await mainFile.writeAsString('''
/// Test package library
library test_package;

/// Main class for the test package.
/// 
/// This class provides core functionality for testing
/// the pub optimizer implementation.
class TestPackage {
  /// Creates a new instance of TestPackage.
  const TestPackage();
  
  /// Performs a test operation.
  /// 
  /// Returns a string indicating the operation was successful.
  String doSomething() {
    return 'Operation completed successfully';
  }
}
''');
}

Future<void> _createPackageWithDocumentation(String packagePath) async {
  await _createMinimalPubspec(packagePath);
  await _createLibDirectory(packagePath);
}

Future<void> _createPackageWithUndocumentedApis(String packagePath) async {
  await _createMinimalPubspec(packagePath);

  final libDir = Directory(path.join(packagePath, 'lib'));
  await libDir.create(recursive: true);

  final mainFile = File(path.join(libDir.path, 'undocumented.dart'));
  await mainFile.writeAsString('''
library undocumented;

class UndocumentedClass {
  String undocumentedMethod() {
    return 'No documentation';
  }
  
  void anotherUndocumentedMethod() {
    // No documentation comment
  }
}

String undocumentedFunction() {
  return 'No docs';
}
''');
}

Future<void> _createPackageWithWorkingExamples(String packagePath) async {
  await _createMinimalPubspec(packagePath);

  final exampleDir = Directory(path.join(packagePath, 'example'));
  await exampleDir.create(recursive: true);

  final exampleFile = File(path.join(exampleDir.path, 'main.dart'));
  await exampleFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Package Example',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: const Center(child: Text('Working Example')),
    );
  }
}
''');

  // Also create test directory with test files
  final testDir = Directory(path.join(packagePath, 'test'));
  await testDir.create(recursive: true);

  final testFile = File(path.join(testDir.path, 'example_test.dart'));
  await testFile.writeAsString('''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('example test', () {
    expect(1 + 1, equals(2));
  });
}
''');
}

Future<void> _createPackageWithBrokenExamples(String packagePath) async {
  await _createMinimalPubspec(packagePath);

  final exampleDir = Directory(path.join(packagePath, 'example'));
  await exampleDir.create(recursive: true);

  final brokenFile = File(path.join(exampleDir.path, 'broken.dart'));
  await brokenFile.writeAsString('''
// This is a broken example - missing main() and runApp()
import 'package:flutter/material.dart';

class BrokenExample {
  void doNothing() {
    print('This is not a proper Flutter app');
  }
}
''');

  final invalidFile = File(path.join(exampleDir.path, 'invalid.dart'));
  await invalidFile.writeAsString('''
// Invalid Dart syntax
import 'package:flutter/material.dart'

void main( {
  // Missing closing parenthesis and runApp call
  print('Invalid syntax');
''');
}

Future<void> _createPackageNeedingOptimization(String packagePath) async {
  // Create a package with various issues that need optimization
  await _createPubspecWithDescription(packagePath, 'Short'); // Poor description
  // Don't create README, CHANGELOG, or LICENSE to trigger optimization suggestions
}

int _priorityValue(SuggestionPriority priority) {
  switch (priority) {
    case SuggestionPriority.critical:
      return 4;
    case SuggestionPriority.high:
      return 3;
    case SuggestionPriority.medium:
      return 2;
    case SuggestionPriority.low:
      return 1;
  }
}
