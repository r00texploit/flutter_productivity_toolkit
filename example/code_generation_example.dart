import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

/// Example demonstrating comprehensive code generation features.
///
/// This example showcases:
/// - Data model generation with serialization
/// - Route generation from annotations
/// - State management code generation
/// - API client generation patterns
/// - Validation and form generation
/// - Localization code generation patterns
void main() {
  runApp(const CodeGenerationExample());
}

class CodeGenerationExample extends StatelessWidget {
  const CodeGenerationExample({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Code Generation Example',
        home: CodeGenerationDemo(),
      );
}

class CodeGenerationDemo extends StatefulWidget {
  const CodeGenerationDemo({super.key});

  @override
  State<CodeGenerationDemo> createState() => _CodeGenerationDemoState();
}

class _CodeGenerationDemoState extends State<CodeGenerationDemo> {
  late List<GeneratedUser> _users;
  late GeneratedProduct _sampleProduct;
  late GeneratedApiClient _apiClient;
  late GeneratedUserPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _initializeGeneratedData();
  }

  void _initializeGeneratedData() {
    // Initialize sample data using generated models
    _users = [
      GeneratedUser.create(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
        isActive: true,
        tags: ['developer', 'flutter'],
        metadata: {'department': 'engineering', 'level': 'senior'},
      ),
      GeneratedUser.create(
        id: '2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        age: 28,
        isActive: true,
        tags: ['designer', 'ui'],
        metadata: {'department': 'design', 'level': 'mid'},
      ),
    ];

    _sampleProduct = GeneratedProduct.create(
      id: 'prod_123',
      name: 'Flutter Dev Toolkit',
      description: 'A comprehensive toolkit for Flutter developers',
      price: 99.99,
      category: ProductCategory.software,
      inStock: true,
      tags: ['flutter', 'development', 'productivity'],
      specifications: {
        'version': '1.0.0',
        'platform': 'cross-platform',
        'license': 'MIT',
      },
    );

    _apiClient = GeneratedApiClient();

    _preferences = GeneratedUserPreferences.create(
      theme: 'dark',
      language: 'en',
      notifications: true,
      autoSave: false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Code Generation Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.code),
              onPressed: _showGeneratedCode,
              tooltip: 'Show Generated Code',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDataModelSection(),
              const SizedBox(height: 24),
              _buildSerializationSection(),
              const SizedBox(height: 24),
              _buildValidationSection(),
              const SizedBox(height: 24),
              _buildApiClientSection(),
              const SizedBox(height: 24),
              _buildStateGenerationSection(),
              const SizedBox(height: 24),
              _buildRouteGenerationSection(),
            ],
          ),
        ),
      );

  Widget _buildDataModelSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated Data Models',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('User Model with Generated Methods:'),
              const SizedBox(height: 8),
              ...(_users.map((user) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(user.name),
                      subtitle: Text('${user.email} • Age: ${user.age}'),
                      trailing: Chip(
                        label: Text(user.isActive ? 'Active' : 'Inactive'),
                        backgroundColor:
                            user.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),)),
              const SizedBox(height: 16),
              const Text('Product Model:'),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(_sampleProduct.name),
                  subtitle: Text(_sampleProduct.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${_sampleProduct.price.toStringAsFixed(2)}'),
                      Text(_sampleProduct.category.name),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _demonstrateEquality,
                    child: const Text('Test Equality'),
                  ),
                  ElevatedButton(
                    onPressed: _demonstrateCopyWith,
                    child: const Text('Test CopyWith'),
                  ),
                  ElevatedButton(
                    onPressed: _demonstrateToString,
                    child: const Text('Test ToString'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSerializationSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated Serialization',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('JSON Serialization/Deserialization:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User JSON:'),
                    Text(
                      _users.first.toJson(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    const Text('Product JSON:'),
                    Text(
                      _sampleProduct.toJson(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _testSerialization,
                    child: const Text('Test Round-trip'),
                  ),
                  ElevatedButton(
                    onPressed: _testBatchSerialization,
                    child: const Text('Test Batch'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildValidationSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated Validation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Model Validation Rules:'),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildValidationTest(
                    'Valid User',
                    () => _users.first.validate(),
                  ),
                  _buildValidationTest(
                    'Invalid User (empty name)',
                    () => _users.first.copyWith(name: '').validate(),
                  ),
                  _buildValidationTest(
                    'Invalid User (bad email)',
                    () => _users.first
                        .copyWith(email: 'invalid-email')
                        .validate(),
                  ),
                  _buildValidationTest(
                    'Valid Product',
                    () => _sampleProduct.validate(),
                  ),
                  _buildValidationTest(
                    'Invalid Product (negative price)',
                    () => _sampleProduct.copyWith(price: -10).validate(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildValidationTest(String label, ValidationResult Function() test) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            ElevatedButton(
              onPressed: () => _showValidationResult(label, test()),
              child: const Text('Test'),
            ),
          ],
        ),
      );

  Widget _buildApiClientSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated API Client',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Type-safe API methods:'),
              const SizedBox(height: 8),
              Column(
                children: [
                  ListTile(
                    title: const Text('GET /users'),
                    subtitle: const Text('Fetch all users'),
                    trailing: ElevatedButton(
                      onPressed: () => _testApiCall('getUsers'),
                      child: const Text('Test'),
                    ),
                  ),
                  ListTile(
                    title: const Text('POST /users'),
                    subtitle: const Text('Create new user'),
                    trailing: ElevatedButton(
                      onPressed: () => _testApiCall('createUser'),
                      child: const Text('Test'),
                    ),
                  ),
                  ListTile(
                    title: const Text('GET /products/:id'),
                    subtitle: const Text('Fetch product by ID'),
                    trailing: ElevatedButton(
                      onPressed: () => _testApiCall('getProduct'),
                      child: const Text('Test'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStateGenerationSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated State Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Auto-generated state managers:'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Preferences State:'),
                      Text('Theme: ${_preferences.theme}'),
                      Text('Language: ${_preferences.language}'),
                      Text('Notifications: ${_preferences.notifications}'),
                      Text('Auto-save: ${_preferences.autoSave}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _toggleTheme,
                    child: const Text('Toggle Theme'),
                  ),
                  ElevatedButton(
                    onPressed: _toggleNotifications,
                    child: const Text('Toggle Notifications'),
                  ),
                  ElevatedButton(
                    onPressed: _changeLanguage,
                    child: const Text('Change Language'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildRouteGenerationSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated Routes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Type-safe route definitions:'),
              const SizedBox(height: 8),
              Column(
                children: [
                  _buildRouteExample(
                    'User Profile Route',
                    '/user/:id',
                    'Generated with UserParams validation',
                  ),
                  _buildRouteExample(
                    'Product Details Route',
                    '/product/:id/details',
                    'Generated with ProductParams validation',
                  ),
                  _buildRouteExample(
                    'Settings Route',
                    '/settings/:section',
                    'Generated with SettingsParams validation',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Generated route code includes:'),
              const SizedBox(height: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Type-safe parameter classes'),
                  Text('• Automatic parameter validation'),
                  Text('• Deep link handlers'),
                  Text('• Route guard integration'),
                  Text('• Navigation helper methods'),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildRouteExample(String title, String pattern, String description) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pattern, style: const TextStyle(fontFamily: 'monospace')),
              Text(description),
            ],
          ),
        ),
      );

  // Demo methods
  void _demonstrateEquality() {
    final user1 = _users.first;
    final user2 = _users.first.copyWith();
    final user3 = _users.first.copyWith(name: 'Different Name');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Equality Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('user1 == user2: ${user1 == user2}'),
            Text('user1 == user3: ${user1 == user3}'),
            Text('user1.hashCode: ${user1.hashCode}'),
            Text('user2.hashCode: ${user2.hashCode}'),
            Text('user3.hashCode: ${user3.hashCode}'),
          ],
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

  void _demonstrateCopyWith() {
    final original = _users.first;
    final modified = original.copyWith(
      name: 'Modified Name',
      age: original.age + 1,
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CopyWith Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Original:'),
            Text('  Name: ${original.name}'),
            Text('  Age: ${original.age}'),
            Text('  Email: ${original.email}'),
            const SizedBox(height: 8),
            const Text('Modified:'),
            Text('  Name: ${modified.name}'),
            Text('  Age: ${modified.age}'),
            Text('  Email: ${modified.email}'),
          ],
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

  void _demonstrateToString() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ToString Test'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('User toString():'),
              Text(
                _users.first.toString(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text('Product toString():'),
              Text(
                _sampleProduct.toString(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
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

  void _testSerialization() {
    final user = _users.first;
    final json = user.toJson();
    final restored = GeneratedUser.fromJson(json);
    final isEqual = user == restored;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Serialization Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Round-trip successful: $isEqual'),
            const SizedBox(height: 8),
            const Text('JSON:'),
            Text(
              json,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
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

  void _testBatchSerialization() {
    final usersJson = _users.map((user) => user.toJson()).toList();
    final restored =
        usersJson.map(GeneratedUser.fromJson).toList();
    final allEqual = _users.length == restored.length &&
        _users
            .asMap()
            .entries
            .every((entry) => entry.value == restored[entry.key]);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch Serialization Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch serialization successful: $allEqual'),
            Text('Original count: ${_users.length}'),
            Text('Restored count: ${restored.length}'),
          ],
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

  void _showValidationResult(String label, ValidationResult result) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Validation: $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valid: ${result.isValid}'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Errors:'),
              ...result.errors.map((error) => Text('• $error')),
            ],
          ],
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

  Future<void> _testApiCall(String method) async {
    String result;
    try {
      switch (method) {
        case 'getUsers':
          final users = await _apiClient.getUsers();
          result = 'Retrieved ${users.length} users';
          break;
        case 'createUser':
          final newUser = await _apiClient.createUser(_users.first);
          result = 'Created user: ${newUser.name}';
          break;
        case 'getProduct':
          final product = await _apiClient.getProduct(_sampleProduct.id);
          result = 'Retrieved product: ${product.name}';
          break;
        default:
          result = 'Unknown method';
      }
    } catch (e) {
      result = 'Error: $e';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Call Result: $result')),
      );
    }
  }

  void _toggleTheme() {
    setState(() {
      _preferences = _preferences.copyWith(
        theme: _preferences.theme == 'light' ? 'dark' : 'light',
      );
    });
  }

  void _toggleNotifications() {
    setState(() {
      _preferences = _preferences.copyWith(
        notifications: !_preferences.notifications,
      );
    });
  }

  void _changeLanguage() {
    final languages = ['en', 'es', 'fr', 'de'];
    final currentIndex = languages.indexOf(_preferences.language);
    final nextIndex = (currentIndex + 1) % languages.length;

    setState(() {
      _preferences = _preferences.copyWith(
        language: languages[nextIndex],
      );
    });
  }

  void _showGeneratedCode() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated Code Examples'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'This example demonstrates code that would be generated by:',),
              SizedBox(height: 8),
              Text('• @GenerateModel annotations'),
              Text('• @GenerateRoute annotations'),
              Text('• @GenerateState annotations'),
              Text('• API client generation'),
              Text('• Validation rule generation'),
              SizedBox(height: 16),
              Text('Generated features include:'),
              SizedBox(height: 8),
              Text('• Immutable data classes'),
              Text('• JSON serialization/deserialization'),
              Text('• Equality and hashCode methods'),
              Text('• CopyWith methods'),
              Text('• ToString methods'),
              Text('• Validation methods'),
              Text('• Type-safe API clients'),
              Text('• Route parameter classes'),
              Text('• State management boilerplate'),
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

// Generated model classes (these would be auto-generated in real usage)

@GenerateModel(
  generateSerialization: true,
  generateEquality: true,
  generateCopyWith: true,
  generateToString: true,
)
class GeneratedUser {
  const GeneratedUser._({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.isActive,
    required this.tags,
    required this.metadata,
  });

  factory GeneratedUser.create({
    required String id,
    required String name,
    required String email,
    required int age,
    required bool isActive,
    required List<String> tags,
    required Map<String, dynamic> metadata,
  }) =>
      GeneratedUser._(
        id: id,
        name: name,
        email: email,
        age: age,
        isActive: isActive,
        tags: tags,
        metadata: metadata,
      );

  final String id;

  @JsonField(name: 'full_name')
  final String name;

  @Validate(rules: [ValidationRule.required, ValidationRule.email])
  final String email;

  @Validate(rules: [ValidationRule.min])
  final int age;

  final bool isActive;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  // Generated methods (would be auto-generated)
  GeneratedUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) =>
      GeneratedUser._(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        age: age ?? this.age,
        isActive: isActive ?? this.isActive,
        tags: tags ?? this.tags,
        metadata: metadata ?? this.metadata,
      );

  String toJson() => jsonEncode({
        'id': id,
        'full_name': name,
        'email': email,
        'age': age,
        'is_active': isActive,
        'tags': tags,
        'metadata': metadata,
      });

  static GeneratedUser fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return GeneratedUser._(
      id: map['id'] as String,
      name: map['full_name'] as String,
      email: map['email'] as String,
      age: map['age'] as int,
      isActive: map['is_active'] as bool,
      tags: List<String>.from(map['tags'] as List),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map),
    );
  }

  ValidationResult validate() {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Name is required');
    }

    if (!email.contains('@')) {
      errors.add('Invalid email format');
    }

    if (age < 0) {
      errors.add('Age must be positive');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          age == other.age &&
          isActive == other.isActive &&
          _listEquals(tags, other.tags) &&
          _mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      age.hashCode ^
      isActive.hashCode ^
      tags.hashCode ^
      metadata.hashCode;

  @override
  String toString() => 'GeneratedUser('
      'id: $id, '
      'name: $name, '
      'email: $email, '
      'age: $age, '
      'isActive: $isActive, '
      'tags: $tags, '
      'metadata: $metadata'
      ')';

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

enum ProductCategory { software, hardware, books, clothing }

@GenerateModel()
class GeneratedProduct {
  const GeneratedProduct._({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.inStock,
    required this.tags,
    required this.specifications,
  });

  factory GeneratedProduct.create({
    required String id,
    required String name,
    required String description,
    required double price,
    required ProductCategory category,
    required bool inStock,
    required List<String> tags,
    required Map<String, dynamic> specifications,
  }) =>
      GeneratedProduct._(
        id: id,
        name: name,
        description: description,
        price: price,
        category: category,
        inStock: inStock,
        tags: tags,
        specifications: specifications,
      );

  final String id;
  final String name;
  final String description;

  @Validate(rules: [ValidationRule.min])
  final double price;

  final ProductCategory category;
  final bool inStock;
  final List<String> tags;
  final Map<String, dynamic> specifications;

  GeneratedProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    ProductCategory? category,
    bool? inStock,
    List<String>? tags,
    Map<String, dynamic>? specifications,
  }) =>
      GeneratedProduct._(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        category: category ?? this.category,
        inStock: inStock ?? this.inStock,
        tags: tags ?? this.tags,
        specifications: specifications ?? this.specifications,
      );

  String toJson() => jsonEncode({
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category.name,
        'in_stock': inStock,
        'tags': tags,
        'specifications': specifications,
      });

  ValidationResult validate() {
    final errors = <String>[];

    if (price < 0) {
      errors.add('Price must be positive');
    }

    if (name.isEmpty) {
      errors.add('Name is required');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  @override
  String toString() => 'GeneratedProduct(id: $id, name: $name, price: $price)';
}

@GenerateState(persist: true, enableDebugging: true)
class GeneratedUserPreferences {
  const GeneratedUserPreferences._({
    required this.theme,
    required this.language,
    required this.notifications,
    required this.autoSave,
  });

  factory GeneratedUserPreferences.create({
    required String theme,
    required String language,
    required bool notifications,
    required bool autoSave,
  }) =>
      GeneratedUserPreferences._(
        theme: theme,
        language: language,
        notifications: notifications,
        autoSave: autoSave,
      );

  @ReactiveProperty(logChanges: true)
  final String theme;

  final String language;

  @ReactiveProperty()
  final bool notifications;

  final bool autoSave;

  GeneratedUserPreferences copyWith({
    String? theme,
    String? language,
    bool? notifications,
    bool? autoSave,
  }) =>
      GeneratedUserPreferences._(
        theme: theme ?? this.theme,
        language: language ?? this.language,
        notifications: notifications ?? this.notifications,
        autoSave: autoSave ?? this.autoSave,
      );
}

// Generated API client (would be auto-generated from OpenAPI spec)
class GeneratedApiClient {
  Future<List<GeneratedUser>> getUsers() async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return [
      GeneratedUser.create(
        id: 'api_1',
        name: 'API User 1',
        email: 'api1@example.com',
        age: 25,
        isActive: true,
        tags: ['api', 'test'],
        metadata: {'source': 'api'},
      ),
      GeneratedUser.create(
        id: 'api_2',
        name: 'API User 2',
        email: 'api2@example.com',
        age: 30,
        isActive: false,
        tags: ['api', 'test'],
        metadata: {'source': 'api'},
      ),
    ];
  }

  Future<GeneratedUser> createUser(GeneratedUser user) async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return user.copyWith(id: 'new_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<GeneratedProduct> getProduct(String id) async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return GeneratedProduct.create(
      id: id,
      name: 'API Product',
      description: 'Product from API',
      price: 49.99,
      category: ProductCategory.software,
      inStock: true,
      tags: ['api', 'product'],
      specifications: {'version': '2.0'},
    );
  }
}

// Validation result class
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  final bool isValid;
  final List<String> errors;
}
