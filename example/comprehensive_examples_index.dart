import 'package:flutter/material.dart';

import 'code_generation_example.dart';
import 'navigation_showcase_example.dart';
import 'performance_monitoring_example.dart';
import 'state_management_example.dart';

/// Comprehensive examples index for the Flutter Dev Toolkit.
///
/// This application provides access to all example applications that demonstrate
/// the various features and capabilities of the Flutter Dev Toolkit:
///
/// 1. **State Management Example** - Demonstrates reactive state management,
///    persistence, dependency injection, and debugging features
///
/// 2. **Navigation Showcase** - Shows type-safe routing, deep linking,
///    multiple navigation stacks, route guards, and complex navigation scenarios
///
/// 3. **Performance Monitoring** - Illustrates real-time performance tracking,
///    memory leak detection, frame analysis, and custom metrics
///
/// 4. **Code Generation Example** - Showcases data model generation,
///    serialization, validation, API clients, and route generation
///
/// 5. **Pub Optimizer Example** - Demonstrates package analysis,
///    publication optimization, and pub.dev readiness checking
void main() {
  runApp(const ComprehensiveExamplesApp());
}

class ComprehensiveExamplesApp extends StatelessWidget {
  const ComprehensiveExamplesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Dev Toolkit - Examples',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const ExamplesIndexScreen(),
      );
}

class ExamplesIndexScreen extends StatelessWidget {
  const ExamplesIndexScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Dev Toolkit Examples'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildExampleCard(
                context,
                title: 'State Management Example',
                description:
                    'Comprehensive state management with reactive updates, '
                    'persistence, dependency injection, and debugging features.',
                features: [
                  'Reactive state updates with automatic widget rebuilds',
                  'State persistence and restoration',
                  'Dependency injection with lifecycle management',
                  'State debugging and transition history',
                  'Multiple state managers working together',
                ],
                icon: Icons.memory,
                color: Colors.green,
                onTap: () => _navigateToExample(
                  context,
                  const StateManagementExample(),
                ),
              ),
              const SizedBox(height: 16),
              _buildExampleCard(
                context,
                title: 'Navigation Showcase',
                description:
                    'Advanced navigation features with type-safe routing, '
                    'deep linking, and complex navigation scenarios.',
                features: [
                  'Type-safe route definitions with parameter validation',
                  'Deep link handling with automatic parameter extraction',
                  'Multiple navigation stacks for complex UI scenarios',
                  'Route guards and authentication',
                  'Navigation history preservation and state management',
                ],
                icon: Icons.navigation,
                color: Colors.blue,
                onTap: () => _navigateToExample(
                  context,
                  const NavigationShowcaseExample(),
                ),
              ),
              const SizedBox(height: 16),
              _buildExampleCard(
                context,
                title: 'Performance Monitoring',
                description: 'Real-time performance analysis with monitoring, '
                    'leak detection, and optimization recommendations.',
                features: [
                  'Real-time widget rebuild tracking with visual indicators',
                  'Memory leak detection with actionable recommendations',
                  'Frame drop analysis and bottleneck identification',
                  'Custom performance metric collection and reporting',
                  'Performance benchmark utilities and comparisons',
                ],
                icon: Icons.speed,
                color: Colors.orange,
                onTap: () => _navigateToExample(
                  context,
                  const PerformanceMonitoringExample(),
                ),
              ),
              const SizedBox(height: 16),
              _buildExampleCard(
                context,
                title: 'Code Generation Example',
                description:
                    'Automated code generation for data models, routes, '
                    'API clients, and validation with various use cases.',
                features: [
                  'Data model generation with serialization',
                  'Route generation from annotations',
                  'State management code generation',
                  'API client generation patterns',
                  'Validation and form generation',
                ],
                icon: Icons.code,
                color: Colors.purple,
                onTap: () => _navigateToExample(
                  context,
                  const CodeGenerationExample(),
                ),
              ),
              const SizedBox(height: 16),
              _buildExampleCard(
                context,
                title: 'Pub Optimizer Example',
                description:
                    'Package optimization tools for pub.dev publishing '
                    'with analysis, validation, and readiness checking.',
                features: [
                  'Package metadata analysis and optimization',
                  'API documentation completeness checking',
                  'Example validation for all public APIs',
                  'Dependency conflict detection and optimization',
                  'Publication readiness assessment',
                ],
                icon: Icons.publish,
                color: Colors.teal,
                onTap: () => _runPubOptimizerExample(context),
              ),
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.flutter_dash,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Flutter Developer Productivity Toolkit',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Comprehensive examples demonstrating all toolkit features',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select an example below to explore specific features and capabilities '
                'of the Flutter Dev Toolkit. Each example is fully interactive and '
                'demonstrates real-world usage patterns.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> features,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Key Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    ),),
              ],
            ),
          ),
        ),
      );

  Widget _buildFooter(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'About the Flutter Dev Toolkit',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'The Flutter Developer Productivity Toolkit is a comprehensive package '
                'that addresses the most critical pain points faced by Flutter developers. '
                'It provides unified solutions for state management, navigation, testing '
                'utilities, and development workflow optimization.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildInfoChip('State Management', Icons.memory),
                  _buildInfoChip('Navigation', Icons.navigation),
                  _buildInfoChip('Performance', Icons.speed),
                  _buildInfoChip('Code Generation', Icons.code),
                  _buildInfoChip('Testing', Icons.bug_report),
                  _buildInfoChip('Pub Optimization', Icons.publish),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoChip(String label, IconData icon) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        backgroundColor: Colors.grey[100],
      );

  void _navigateToExample(BuildContext context, Widget example) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => example,
      ),
    );
  }

  Future<void> _runPubOptimizerExample(BuildContext context) async {
    // Show a dialog explaining that this is a command-line example
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pub Optimizer Example'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The Pub Optimizer example is a command-line tool that analyzes '
                'and optimizes Flutter packages for publication to pub.dev.',
              ),
              SizedBox(height: 16),
              Text(
                'To run the example:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Open a terminal in the project root'),
              Text('2. Run: dart run example/pub_optimizer_example.dart'),
              SizedBox(height: 16),
              Text(
                'The example will analyze the current package and provide:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Package quality score and analysis'),
              Text('• Documentation coverage assessment'),
              Text('• Example validation results'),
              Text('• Publication readiness report'),
              Text('• Optimization recommendations'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
