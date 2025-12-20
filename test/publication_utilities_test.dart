import 'dart:io';

import 'package:flutter_productivity_toolkit/src/development_tools/pub_optimizer_impl.dart';
import 'package:flutter_productivity_toolkit/src/development_tools/publication_utilities.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('PublicationUtilities', () {
    late PublicationUtilities utilities;
    late Directory tempDir;
    late String packagePath;

    setUp(() async {
      utilities = const PublicationUtilities();
      tempDir =
          await Directory.systemTemp.createTemp('publication_utilities_test');
      packagePath = tempDir.path;
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Complete Workflow', () {
      test('should run complete workflow for well-formed package', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final result = await utilities.runCompleteWorkflow(
          packagePath,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.packageAnalysis, isNotNull);
        expect(result.documentationAnalysis, isNotNull);
        expect(result.exampleValidation, isNotNull);
        expect(result.dependencyAnalysis, isNotNull);
        expect(result.preflightReport, isNotNull);
        expect(result.detailedReport, isNotNull);
        expect(result.workflowSteps.length, greaterThan(5));
        expect(result.totalDuration, greaterThan(Duration.zero));
        expect(result.errors, isEmpty);

        // Verify all steps completed successfully
        for (final step in result.workflowSteps) {
          expect(
              step.status,
              anyOf([
                WorkflowStepStatus.completed,
                WorkflowStepStatus.running, // Last step might still be running
              ]),);
        }
      });

      test('should handle incomplete package gracefully', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final result = await utilities.runCompleteWorkflow(
          packagePath,
        );

        // Assert
        expect(result.success, isFalse); // Should fail due to missing files
        expect(result.packageAnalysis, isNotNull);
        expect(result.preflightReport, isNotNull);
        expect(result.preflightReport!.readyForPublication, isFalse);
        expect(result.workflowSteps.length, greaterThan(0));
      });

      test('should apply automatic fixes when requested', () async {
        // Arrange
        await _createPackageNeedingOptimization(packagePath);

        // Act
        final result = await utilities.runCompleteWorkflow(
          packagePath,
          applyAutomaticFixes: true,
          generateDetailedReport: false,
        );

        // Assert
        expect(result.optimizationResult, isNotNull);
        expect(result.optimizationResult!.success, isTrue);
        expect(result.optimizationResult!.changes.length, greaterThan(0));

        // Verify files were actually created
        expect(File(path.join(packagePath, 'README.md')).existsSync(), isTrue);
        expect(
            File(path.join(packagePath, 'CHANGELOG.md')).existsSync(), isTrue,);
      });

      test('should handle workflow errors gracefully', () async {
        // Arrange - use non-existent path
        const invalidPath = '/invalid/path/that/does/not/exist';

        // Act
        final result = await utilities.runCompleteWorkflow(
          invalidPath,
          generateDetailedReport: false,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errors.length, greaterThan(0));
      });
    });

    group('Package Readiness Check', () {
      test('should return true for ready package', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final isReady =
            await utilities.isPackageReadyForPublication(packagePath);

        // Assert
        expect(isReady, isTrue);
      });

      test('should return false for incomplete package', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final isReady =
            await utilities.isPackageReadyForPublication(packagePath);

        // Assert
        expect(isReady, isFalse);
      });

      test('should handle errors gracefully', () async {
        // Arrange - use non-existent path
        const invalidPath = '/invalid/path';

        // Act
        final isReady =
            await utilities.isPackageReadyForPublication(invalidPath);

        // Assert
        expect(isReady, isFalse);
      });
    });

    group('Publication Checklist', () {
      test('should generate comprehensive checklist for complete package',
          () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final checklist =
            await utilities.generatePublicationChecklist(packagePath);

        // Assert
        expect(checklist.totalItems, greaterThan(10));
        expect(checklist.passedItems, greaterThan(5));
        expect(
            checklist.manualItems, greaterThan(0),); // Should have manual items
        expect(checklist.completionPercentage, greaterThan(70.0));

        // Verify checklist contains different categories
        final categories = checklist.items.map((item) => item.category).toSet();
        expect(categories, contains(ChecklistCategory.metadata));
        expect(categories, contains(ChecklistCategory.documentation));
        expect(categories, contains(ChecklistCategory.legal));
      });

      test('should identify failures in incomplete package', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final checklist =
            await utilities.generatePublicationChecklist(packagePath);

        // Assert
        expect(checklist.failedItems, greaterThan(0));
        expect(checklist.overallStatus, ChecklistStatus.failed);
        expect(checklist.completionPercentage, lessThan(50.0));
      });

      test('should include both automated and manual items', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final checklist =
            await utilities.generatePublicationChecklist(packagePath);

        // Assert
        final automatedItems =
            checklist.items.where((item) => item.isAutomated).length;
        final manualItems =
            checklist.items.where((item) => !item.isAutomated).length;

        expect(automatedItems, greaterThan(0));
        expect(manualItems, greaterThan(0));
        expect(automatedItems + manualItems, equals(checklist.totalItems));
      });
    });

    group('Pub Score Estimation', () {
      test('should estimate high score for quality package', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final estimate = await utilities.estimatePubScore(packagePath);

        // Assert
        expect(estimate.overallScore, greaterThan(70));
        expect(estimate.likesScore, greaterThan(0));
        expect(estimate.pubPointsScore, greaterThan(0));
        expect(estimate.popularityScore, greaterThan(0));
        expect(estimate.confidence, greaterThan(0.5));
        expect(estimate.recommendations, isNotNull);
      });

      test('should estimate lower score for incomplete package', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final estimate = await utilities.estimatePubScore(packagePath);

        // Assert
        expect(estimate.overallScore, lessThan(50));
        expect(estimate.recommendations.length, greaterThan(0));
        expect(estimate.confidence, lessThan(0.8));
      });

      test('should provide actionable recommendations', () async {
        // Arrange
        await _createPackageNeedingOptimization(packagePath);

        // Act
        final estimate = await utilities.estimatePubScore(packagePath);

        // Assert
        expect(estimate.recommendations, isNotEmpty);

        // Verify recommendations are actionable
        for (final recommendation in estimate.recommendations) {
          expect(recommendation, isNotEmpty);
          expect(
              recommendation.length, greaterThan(10),); // Should be descriptive
        }
      });
    });

    group('Publication Summary', () {
      test('should generate comprehensive summary for complete package',
          () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final summary = await utilities.generatePublicationSummary(packagePath);

        // Assert
        expect(summary, contains('Publication Summary Report'));
        expect(summary, contains('Package Path:'));
        expect(summary, contains('Overall Status:'));
        expect(summary, contains('Package Quality'));
        expect(summary, contains('Documentation'));
        expect(summary, contains('Examples'));
        expect(summary, contains('Publication Readiness'));
        expect(summary, contains('Workflow Steps'));
        expect(summary, contains('✅')); // Should have success indicators
      });

      test('should indicate issues in incomplete package summary', () async {
        // Arrange
        await _createMinimalPubspec(packagePath);

        // Act
        final summary = await utilities.generatePublicationSummary(packagePath);

        // Assert
        expect(summary, contains('❌ Not Ready'));
        expect(summary, contains('Critical Issues to Fix:'));
      });

      test('should include timing information', () async {
        // Arrange
        await _createCompletePackage(packagePath);

        // Act
        final summary = await utilities.generatePublicationSummary(packagePath);

        // Assert
        expect(summary, contains('Total Processing Time:'));
        expect(summary, contains('ms'));
      });
    });

    group('Error Handling', () {
      test('should handle non-existent package directory', () async {
        // Arrange
        const nonExistentPath = '/path/that/does/not/exist';

        // Act & Assert - should not throw
        final result = await utilities.runCompleteWorkflow(nonExistentPath);
        expect(result.success, isFalse);

        final isReady =
            await utilities.isPackageReadyForPublication(nonExistentPath);
        expect(isReady, isFalse);

        final checklist =
            await utilities.generatePublicationChecklist(nonExistentPath);
        expect(checklist.overallStatus, ChecklistStatus.failed);

        final estimate = await utilities.estimatePubScore(nonExistentPath);
        expect(estimate.overallScore, lessThan(50));

        final summary =
            await utilities.generatePublicationSummary(nonExistentPath);
        expect(summary, contains('❌ Not Ready'));
      });

      test('should handle malformed package files', () async {
        // Arrange
        await _createMalformedPubspec(packagePath);

        // Act & Assert - should not throw
        final result = await utilities.runCompleteWorkflow(packagePath);
        expect(result.success, isFalse);

        final checklist =
            await utilities.generatePublicationChecklist(packagePath);
        expect(checklist.failedItems, greaterThan(0));
      });
    });

    group('Integration with PubOptimizer', () {
      test('should work with custom PubOptimizer implementation', () async {
        // Arrange
        const customOptimizer = PubOptimizerImpl();
        const customUtilities =
            PublicationUtilities(optimizer: customOptimizer);
        await _createCompletePackage(packagePath);

        // Act
        final result = await customUtilities.runCompleteWorkflow(packagePath);

        // Assert
        expect(result.success, isTrue);
        expect(result.packageAnalysis, isNotNull);
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
  await _createWorkingExamples(packagePath);
}

Future<void> _createMinimalPubspec(String packagePath) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: A test package
version: 1.0.0
''');
}

Future<void> _createPubspecWithUrls(String packagePath) async {
  final pubspecFile = File(path.join(packagePath, 'pubspec.yaml'));
  await pubspecFile.writeAsString('''
name: test_package
description: A comprehensive test package for validating publication utilities functionality and ensuring proper pub.dev optimization
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

A comprehensive test package for validating publication utilities functionality.

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
/// the publication utilities implementation.
class TestPackage {
  /// Creates a new instance of TestPackage.
  const TestPackage();
  
  /// Performs a test operation.
  /// 
  /// Returns a string indicating the operation was successful.
  String doSomething() {
    return 'Operation completed successfully';
  }
  
  /// Validates input data.
  /// 
  /// Returns true if the input is valid, false otherwise.
  bool validateInput(String input) {
    return input.isNotEmpty;
  }
}
''');
}

Future<void> _createWorkingExamples(String packagePath) async {
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

Future<void> _createPackageNeedingOptimization(String packagePath) async {
  // Create a package with various issues that need optimization
  await _createPubspecWithDescription(packagePath, 'Short'); // Poor description
  // Don't create README, CHANGELOG, or LICENSE to trigger optimization suggestions
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
