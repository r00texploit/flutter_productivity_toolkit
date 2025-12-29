# Development Tools Guide

The Flutter Productivity Toolkit includes comprehensive development tools to optimize your workflow, improve package quality, and streamline the development process.

## Overview

The development tools provide:

- **Pub.dev Optimization**: Analyze and improve package discoverability
- **Project Maintenance**: Automated code organization and cleanup
- **Workflow Automation**: Streamlined build and deployment processes
- **Quality Assurance**: Comprehensive linting and validation

## Pub.dev Optimization

### Package Analysis

Analyze your package for pub.dev compliance:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() async {
  final optimizer = PubOptimizer();
  
  // Analyze current package
  final analysis = await optimizer.analyzePackage('.');
  
  print('Current Score: ${analysis.currentScore}/160');
  print('Potential Score: ${analysis.potentialScore}/160');
  
  // Show recommendations
  for (final recommendation in analysis.recommendations) {
    print('${recommendation.category}: ${recommendation.description}');
  }
}
```

### Score Improvement

Get specific recommendations for improving your pub.dev score:

```dart
final optimizer = PubOptimizer();
final analysis = await optimizer.analyzePackage('.');

// Get detailed recommendations
final recommendations = analysis.recommendations;

for (final rec in recommendations) {
  print('Category: ${rec.category}');
  print('Impact: ${rec.impact}');
  print('Description: ${rec.description}');
  print('How to fix: ${rec.suggestion}');
  print('---');
}
```

### Automated Fixes

Apply automated fixes where possible:

```dart
final optimizer = PubOptimizer();

// Apply all automated fixes
final results = await optimizer.applyAutomatedFixes('.');

print('Applied ${results.appliedFixes.length} fixes');
print('Manual fixes needed: ${results.manualFixes.length}');

// Show what was fixed
for (final fix in results.appliedFixes) {
  print('✅ Fixed: ${fix.description}');
}

// Show what needs manual attention
for (final fix in results.manualFixes) {
  print('⚠️  Manual fix needed: ${fix.description}');
  print('   Suggestion: ${fix.suggestion}');
}
```

## Project Maintenance

### Import Organization

Automatically organize and optimize imports:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() async {
  final maintenance = ProjectMaintenance();
  
  // Organize imports in all Dart files
  final result = await maintenance.organizeImports('lib/');
  
  print('Organized imports in ${result.filesProcessed} files');
  print('Removed ${result.unusedImports} unused imports');
  print('Fixed ${result.sortingIssues} sorting issues');
}
```

### Code Cleanup

Remove unused code and optimize structure:

```dart
final maintenance = ProjectMaintenance();

// Clean up unused code
final cleanup = await maintenance.cleanupUnusedCode('lib/');

print('Removed ${cleanup.unusedClasses} unused classes');
print('Removed ${cleanup.unusedMethods} unused methods');
print('Removed ${cleanup.unusedVariables} unused variables');

// Optimize file structure
final optimization = await maintenance.optimizeFileStructure('lib/');

print('Moved ${optimization.movedFiles} files to better locations');
print('Created ${optimization.createdDirectories} new directories');
```

### Dependency Analysis

Analyze and optimize dependencies:

```dart
final maintenance = ProjectMaintenance();

// Analyze dependencies
final analysis = await maintenance.analyzeDependencies();

print('Total dependencies: ${analysis.totalDependencies}');
print('Outdated dependencies: ${analysis.outdatedDependencies.length}');
print('Unused dependencies: ${analysis.unusedDependencies.length}');

// Get update recommendations
for (final dep in analysis.outdatedDependencies) {
  print('${dep.name}: ${dep.currentVersion} → ${dep.latestVersion}');
  if (dep.hasBreakingChanges) {
    print('  ⚠️  Breaking changes detected');
  }
}
```

## Workflow Tools

### Real-time Linting

Enable real-time Flutter-specific linting:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() async {
  final workflow = WorkflowTools();
  
  // Start real-time linting
  await workflow.startRealTimeLinting(
    directory: 'lib/',
    onIssueFound: (issue) {
      print('Linting issue: ${issue.message}');
      print('File: ${issue.file}:${issue.line}');
      if (issue.suggestion != null) {
        print('Suggestion: ${issue.suggestion}');
      }
    },
  );
  
  print('Real-time linting started. Watching for changes...');
}
```

### Asset Generation

Automatically generate asset reference classes:

```dart
final workflow = WorkflowTools();

// Generate asset references
final result = await workflow.generateAssetReferences(
  assetsDirectory: 'assets/',
  outputFile: 'lib/generated/assets.dart',
);

print('Generated references for ${result.totalAssets} assets');
print('Created ${result.generatedClasses} classes');
```

This generates code like:

```dart
// lib/generated/assets.dart
class Assets {
  static const String imagesLogo = 'assets/images/logo.png';
  static const String iconsHome = 'assets/icons/home.svg';
  static const String fontsRoboto = 'assets/fonts/roboto.ttf';
}
```

### Build Configuration

Validate and optimize build configuration:

```dart
final workflow = WorkflowTools();

// Validate build configuration
final validation = await workflow.validateBuildConfiguration();

if (validation.isValid) {
  print('✅ Build configuration is valid');
} else {
  print('❌ Build configuration issues found:');
  for (final issue in validation.issues) {
    print('  - ${issue.description}');
    print('    Suggestion: ${issue.suggestion}');
  }
}

// Optimize build configuration
final optimization = await workflow.optimizeBuildConfiguration();
print('Applied ${optimization.optimizations.length} optimizations');
```

## Publication Utilities

### Pre-publication Checks

Run comprehensive checks before publishing:

```dart
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() async {
  final publisher = PublicationUtilities();
  
  // Run all pre-publication checks
  final checks = await publisher.runPrePublicationChecks();
  
  print('Pre-publication Check Results:');
  print('Overall Status: ${checks.overallStatus}');
  print('Score: ${checks.estimatedScore}/160');
  
  // Show detailed results
  for (final category in checks.categories) {
    print('\n${category.name}: ${category.score}/${category.maxScore}');
    
    for (final check in category.checks) {
      final status = check.passed ? '✅' : '❌';
      print('  $status ${check.description}');
      
      if (!check.passed && check.suggestion != null) {
        print('     💡 ${check.suggestion}');
      }
    }
  }
}
```

### Automated Publishing

Automate the publishing process with validation:

```dart
final publisher = PublicationUtilities();

// Prepare for publishing
final preparation = await publisher.prepareForPublishing(
  validateTests: true,
  updateVersion: true,
  generateChangelog: true,
);

if (preparation.isReady) {
  print('✅ Package is ready for publishing');
  
  // Optionally publish (dry run first)
  final dryRun = await publisher.publishPackage(dryRun: true);
  
  if (dryRun.wouldSucceed) {
    print('Dry run successful. Ready to publish!');
    
    // Actual publish
    // final result = await publisher.publishPackage(dryRun: false);
  }
} else {
  print('❌ Package not ready for publishing:');
  for (final issue in preparation.blockingIssues) {
    print('  - ${issue.description}');
  }
}
```

## Configuration

### Development Tools Configuration

Configure development tools behavior:

```dart
final config = DevelopmentToolsConfig(
  enablePubOptimization: true,
  enableRealTimeLinting: true,
  enableAssetGeneration: true,
  lintingRules: LintingRules(
    enforceFlutterBestPractices: true,
    requireDocumentation: true,
    enforceNaming: true,
  ),
  assetGeneration: AssetGenerationConfig(
    outputDirectory: 'lib/generated',
    generateConstants: true,
    generateExtensions: true,
  ),
);

// Apply configuration
await WorkflowTools.configure(config);
```

### Custom Linting Rules

Define custom linting rules for your project:

```dart
final customRules = LintingRules(
  customRules: [
    LintRule(
      name: 'require_barrel_exports',
      description: 'Require barrel exports for directories',
      check: (file) {
        // Custom rule implementation
        return file.path.contains('/src/') && 
               !file.hasBarrelExport();
      },
      suggestion: 'Add an index.dart file with exports',
    ),
  ],
);
```

## Integration with CI/CD

### GitHub Actions

Integrate development tools with GitHub Actions:

```yaml
# .github/workflows/quality.yml
name: Quality Checks

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run pub.dev analysis
        run: |
          dart run flutter_productivity_toolkit:pub_analyzer
          
      - name: Check code quality
        run: |
          dart run flutter_productivity_toolkit:quality_check
          
      - name: Validate build configuration
        run: |
          dart run flutter_productivity_toolkit:build_validator
```

### Pre-commit Hooks

Set up pre-commit hooks for automatic quality checks:

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running pre-commit quality checks..."

# Run linting
dart run flutter_productivity_toolkit:lint_check
if [ $? -ne 0 ]; then
  echo "❌ Linting failed"
  exit 1
fi

# Check imports
dart run flutter_productivity_toolkit:import_check
if [ $? -ne 0 ]; then
  echo "❌ Import organization failed"
  exit 1
fi

# Validate pub.dev compliance
dart run flutter_productivity_toolkit:pub_check
if [ $? -ne 0 ]; then
  echo "❌ Pub.dev compliance check failed"
  exit 1
fi

echo "✅ All quality checks passed"
```

## Command Line Tools

The toolkit provides command-line tools for common tasks:

### Package Analysis

```bash
# Analyze current package
dart run flutter_productivity_toolkit:analyze

# Analyze specific directory
dart run flutter_productivity_toolkit:analyze --path ./packages/my_package

# Generate detailed report
dart run flutter_productivity_toolkit:analyze --report --output analysis_report.json
```

### Code Cleanup

```bash
# Clean up unused code
dart run flutter_productivity_toolkit:cleanup

# Organize imports
dart run flutter_productivity_toolkit:organize-imports

# Fix linting issues
dart run flutter_productivity_toolkit:fix-lint
```

### Asset Management

```bash
# Generate asset references
dart run flutter_productivity_toolkit:generate-assets

# Optimize images
dart run flutter_productivity_toolkit:optimize-images

# Validate asset usage
dart run flutter_productivity_toolkit:validate-assets
```

## Best Practices

### 1. Regular Maintenance

Run maintenance tasks regularly:

```dart
// Weekly maintenance script
void main() async {
  final maintenance = ProjectMaintenance();
  
  // Clean up unused code
  await maintenance.cleanupUnusedCode('lib/');
  
  // Organize imports
  await maintenance.organizeImports('lib/');
  
  // Update dependencies
  await maintenance.updateDependencies();
  
  // Generate fresh assets
  final workflow = WorkflowTools();
  await workflow.generateAssetReferences();
  
  print('✅ Weekly maintenance completed');
}
```

### 2. Continuous Quality

Integrate quality checks into your development workflow:

```dart
// Development quality check
void main() async {
  final workflow = WorkflowTools();
  
  // Start real-time monitoring
  await workflow.startRealTimeLinting();
  await workflow.startAssetWatching();
  
  print('Quality monitoring active');
}
```

### 3. Pre-publication Routine

Always run pre-publication checks:

```dart
// Pre-publication checklist
void main() async {
  final publisher = PublicationUtilities();
  
  // 1. Run all checks
  final checks = await publisher.runPrePublicationChecks();
  
  // 2. Fix any issues
  if (!checks.allPassed) {
    print('Fixing issues...');
    await publisher.applyAutomatedFixes();
  }
  
  // 3. Validate again
  final finalChecks = await publisher.runPrePublicationChecks();
  
  if (finalChecks.allPassed) {
    print('✅ Ready to publish!');
  } else {
    print('❌ Manual fixes still needed');
  }
}
```

## Troubleshooting

### Common Issues

#### Linting Conflicts

If linting rules conflict with your code style:

```dart
final config = LintingRules(
  ignoreRules: ['prefer_const_constructors'],
  customSeverity: {
    'unused_import': Severity.warning,
    'missing_docs': Severity.info,
  },
);
```

#### Asset Generation Issues

If asset generation fails:

```dart
final workflow = WorkflowTools();

// Debug asset generation
final debug = await workflow.debugAssetGeneration();
print('Asset scan results: ${debug.scannedFiles}');
print('Generation errors: ${debug.errors}');
```

#### Dependency Conflicts

Resolve dependency conflicts:

```dart
final maintenance = ProjectMaintenance();

// Analyze conflicts
final conflicts = await maintenance.analyzeDependencyConflicts();

for (final conflict in conflicts) {
  print('Conflict: ${conflict.description}');
  print('Suggested resolution: ${conflict.resolution}');
}
```

## Examples

See the [examples directory](../example/) for complete working examples:

- [Pub Optimizer Example](../example/pub_optimizer_example.dart)
- [Workflow Tools Example](../example/workflow_tools_example.dart)
- [Project Maintenance Example](../example/project_maintenance_example.dart)

## Next Steps

- Learn about [performance monitoring](performance.md) for optimization insights
- Explore [testing utilities](testing.md) for quality assurance
- Check out [best practices](best_practices.md) for development guidelines
- Review [configuration options](configuration.md) for customization