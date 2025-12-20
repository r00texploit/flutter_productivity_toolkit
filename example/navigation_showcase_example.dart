import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dev_toolkit/flutter_dev_toolkit.dart' as toolkit;

/// Example demonstrating comprehensive navigation features.
///
/// This example showcases:
/// - Type-safe route definitions with parameter validation
/// - Deep link handling with automatic parameter extraction
/// - Multiple navigation stacks for complex UI scenarios
/// - Route guards and authentication
/// - Navigation history preservation and state management
/// - Custom route transitions
void main() {
  runApp(const NavigationShowcaseExample());
}

class NavigationShowcaseExample extends StatelessWidget {
  const NavigationShowcaseExample({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Navigation Showcase',
        home: NavigationDemo(),
      );
}

class NavigationDemo extends StatefulWidget {
  const NavigationDemo({super.key});

  @override
  State<NavigationDemo> createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  late toolkit.DefaultRouteBuilder _routeBuilder;
  late toolkit.DefaultNavigationStack _mainStack;
  late toolkit.DefaultNavigationStack _modalStack;
  late AuthenticationService _authService;
  late NavigationTestHelper _testHelper;

  @override
  void initState() {
    super.initState();
    _setupNavigation();
  }

  void _setupNavigation() {
    // Create authentication service
    _authService = AuthenticationService();

    // Create route builder with deep link configuration
    _routeBuilder = toolkit.DefaultRouteBuilder(
      deepLinkConfig: const toolkit.DeepLinkConfiguration(
        scheme: 'navdemo',
        host: 'example.com',
        pathPatterns: {
          '/user/:id': '/user',
          '/product/:id/details': '/product/details',
          '/settings/:section': '/settings',
        },
        handleUniversalLinks: true,
      ),
    );

    // Create navigation stacks
    _mainStack = _routeBuilder.createNavigationStack();
    _modalStack = _routeBuilder.createNavigationStack();

    // Create test helper
    _testHelper = NavigationTestHelper(_routeBuilder);

    // Define routes with various configurations
    _defineRoutes();

    // Set up deep link handlers
    _setupDeepLinkHandlers();

    // Set main stack as active
    _routeBuilder.setActiveStack(_mainStack);
  }

  void _defineRoutes() {
    // Home route (no parameters)
    _routeBuilder.defineRoute<void>('/home', (params) => const HomeScreen());

    // User profile route with ID parameter
    _routeBuilder.defineRouteWithGuards<UserParams>(
      '/user',
      (params) => UserProfileScreen(userId: params.userId),
      requiresAuthentication: true,
      guards: [
        toolkit.AuthenticationGuard(
          () => _authService.isAuthenticated,
          '/login',
        ),
      ],
    );

    // Product details route with complex parameters
    _routeBuilder.defineRoute<ProductParams>('/product/details', (params) => ProductDetailsScreen(
        productId: params.productId,
        category: params.category,
        variant: params.variant,
      ),);

    // Settings route with section parameter
    _routeBuilder.defineRoute<SettingsParams>('/settings', (params) => SettingsScreen(section: params.section));

    // Login route (no authentication required)
    _routeBuilder.defineRoute<void>('/login', (params) => LoginScreen(
        onLogin: () {
          _authService.login();
          _routeBuilder.navigate<void, void>('/home');
        },
      ),);

    // Modal route for overlays
    _routeBuilder.defineRoute<ModalParams>('/modal', (params) => ModalScreen(
        title: params.title,
        content: params.content,
        onClose: () => _modalStack.pop<void>(),
      ),);

    // Nested navigation example
    _routeBuilder.defineRoute<TabParams>('/tabs', (params) => TabNavigationScreen(
        initialTab: params.initialTab,
        routeBuilder: _routeBuilder,
      ),);
  }

  void _setupDeepLinkHandlers() {
    // User profile deep link
    _routeBuilder.registerDeepLinkHandler('/user/:id', (params) async {
      final userId = params['id'];
      if (userId != null) {
        await _routeBuilder.navigate<UserParams, void>(
          '/user',
          params: UserParams(userId: userId),
        );
        return true;
      }
      return false;
    });

    // Product details deep link
    _routeBuilder.registerDeepLinkHandler('/product/:id/details',
        (params) async {
      final productId = params['id'];
      final category = params['category'] ?? 'general';
      final variant = params['variant'];

      if (productId != null) {
        await _routeBuilder.navigate<ProductParams, void>(
          '/product/details',
          params: ProductParams(
            productId: productId,
            category: category,
            variant: variant,
          ),
        );
        return true;
      }
      return false;
    });

    // Settings deep link
    _routeBuilder.registerDeepLinkHandler('/settings/:section', (params) async {
      final section = params['section'] ?? 'general';
      await _routeBuilder.navigate<SettingsParams, void>(
        '/settings',
        params: SettingsParams(section: section),
      );
      return true;
    });
  }

  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Navigation Showcase'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _showNavigationInfo,
              tooltip: 'Navigation Info',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCurrentRouteInfo(),
              const SizedBox(height: 24),
              _buildBasicNavigation(),
              const SizedBox(height: 24),
              _buildParameterizedNavigation(),
              const SizedBox(height: 24),
              _buildDeepLinkTesting(),
              const SizedBox(height: 24),
              _buildNavigationStacks(),
              const SizedBox(height: 24),
              _buildAuthenticationDemo(),
            ],
          ),
        ),
      );

  Widget _buildCurrentRouteInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Navigation State',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StreamBuilder<toolkit.RouteInformation>(
                stream: _routeBuilder.routeStream,
                initialData: _routeBuilder.currentRoute,
                builder: (context, snapshot) {
                  final route = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Route: ${route?.path ?? 'None'}'),
                      if (route?.parameters.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        const Text('Parameters:'),
                        ...route!.parameters.entries.map(
                          (MapEntry<String, dynamic> entry) =>
                              Text('  ${entry.key}: ${entry.value}'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('Authenticated: ${_authService.isAuthenticated}'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<toolkit.NavigationRoute>>(
                stream: _mainStack.stackStream,
                initialData: _mainStack.history,
                builder: (context, snapshot) {
                  final history = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Navigation History (${history.length} routes):'),
                      ...history.map((route) => Text('  • ${route.path}')),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildBasicNavigation() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic Navigation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _navigateToHome,
                    child: const Text('Home'),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToSettings,
                    child: const Text('Settings'),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToTabs,
                    child: const Text('Tab Navigation'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _mainStack.canPop ? () => _mainStack.pop<void>() : null,
                    child: const Text('Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildParameterizedNavigation() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parameterized Navigation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => _navigateToUser('user123'),
                    child: const Text('User Profile (123)'),
                  ),
                  ElevatedButton(
                    onPressed: () => _navigateToUser('user456'),
                    child: const Text('User Profile (456)'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _navigateToProduct('prod789', 'electronics'),
                    child: const Text('Product (Electronics)'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _navigateToProduct('prod101', 'books', 'hardcover'),
                    child: const Text('Product (Books)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDeepLinkTesting() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deep Link Testing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Test these deep links:'),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeepLinkButton(
                    'navdemo://example.com/user/123',
                    'User Profile Deep Link',
                  ),
                  _buildDeepLinkButton(
                    'navdemo://example.com/product/456/details?category=tech&variant=pro',
                    'Product Details Deep Link',
                  ),
                  _buildDeepLinkButton(
                    'navdemo://example.com/settings/privacy',
                    'Settings Deep Link',
                  ),
                  _buildDeepLinkButton(
                    'navdemo://example.com/invalid/route',
                    'Invalid Deep Link (should fail)',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDeepLinkButton(String url, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _testDeepLink(url),
                child: Text(label),
              ),
            ),
          ],
        ),
      );

  Widget _buildNavigationStacks() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Multiple Navigation Stacks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Main Stack:'),
                        StreamBuilder<List<toolkit.NavigationRoute>>(
                          stream: _mainStack.stackStream,
                          initialData: _mainStack.history,
                          builder: (context, snapshot) {
                            final routes = snapshot.data ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: routes
                                  .map((route) => Text('  • ${route.path}'))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Modal Stack:'),
                        StreamBuilder<List<toolkit.NavigationRoute>>(
                          stream: _modalStack.stackStream,
                          initialData: _modalStack.history,
                          builder: (context, snapshot) {
                            final routes = snapshot.data ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: routes
                                  .map((route) => Text('  • ${route.path}'))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _switchToMainStack,
                    child: const Text('Use Main Stack'),
                  ),
                  ElevatedButton(
                    onPressed: _switchToModalStack,
                    child: const Text('Use Modal Stack'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _showModal('Test Modal', 'This is a test modal'),
                    child: const Text('Show Modal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildAuthenticationDemo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authentication & Route Guards',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                  'Current Status: ${_authService.isAuthenticated ? 'Logged In' : 'Logged Out'}',),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!_authService.isAuthenticated) ...[
                    ElevatedButton(
                      onPressed: _navigateToLogin,
                      child: const Text('Go to Login'),
                    ),
                    ElevatedButton(
                      onPressed: () => _authService.login(),
                      child: const Text('Quick Login'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => _navigateToUser('current'),
                      child: const Text('My Profile (Protected)'),
                    ),
                    ElevatedButton(
                      onPressed: () => _authService.logout(),
                      child: const Text('Logout'),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: _testProtectedRoute,
                    child: const Text('Test Protected Route'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // Navigation methods
  Future<void> _navigateToHome() async {
    await _routeBuilder.navigate<void, void>('/home');
  }

  Future<void> _navigateToUser(String userId) async {
    await _routeBuilder.navigate<UserParams, void>(
      '/user',
      params: UserParams(userId: userId),
    );
  }

  Future<void> _navigateToProduct(String productId, String category,
      [String? variant,]) async {
    await _routeBuilder.navigate<ProductParams, void>(
      '/product/details',
      params: ProductParams(
        productId: productId,
        category: category,
        variant: variant,
      ),
    );
  }

  Future<void> _navigateToSettings([String section = 'general']) async {
    await _routeBuilder.navigate<SettingsParams, void>(
      '/settings',
      params: SettingsParams(section: section),
    );
  }

  Future<void> _navigateToLogin() async {
    await _routeBuilder.navigate<void, void>('/login');
  }

  Future<void> _navigateToTabs([int initialTab = 0]) async {
    await _routeBuilder.navigate<TabParams, void>(
      '/tabs',
      params: TabParams(initialTab: initialTab),
    );
  }

  // Deep link testing
  Future<void> _testDeepLink(String url) async {
    final success = await _testHelper.simulateDeepLink(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Deep link handled successfully' : 'Deep link failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // Stack management
  void _switchToMainStack() {
    _routeBuilder.setActiveStack(_mainStack);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched to main navigation stack')),
    );
  }

  void _switchToModalStack() {
    _routeBuilder.setActiveStack(_modalStack);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched to modal navigation stack')),
    );
  }

  Future<void> _showModal(String title, String content) async {
    final previousStack = _routeBuilder.navigationStacks
        .firstWhere((stack) => stack != _modalStack);
    _routeBuilder.setActiveStack(_modalStack);

    await _routeBuilder.navigate<ModalParams, void>(
      '/modal',
      params: ModalParams(title: title, content: content),
    );

    // Switch back to previous stack after modal
    _routeBuilder.setActiveStack(previousStack);
  }

  // Authentication testing
  Future<void> _testProtectedRoute() async {
    try {
      await _navigateToUser('protected_test');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation blocked: $e')),
        );
      }
    }
  }

  void _showNavigationInfo() {
    final history = _testHelper.simulatedDeepLinkHistory;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Navigation Stacks:'),
              Text('  Main: ${_mainStack.history.length} routes'),
              Text('  Modal: ${_modalStack.history.length} routes'),
              const SizedBox(height: 16),
              const Text('Deep Link History:'),
              if (history.isEmpty)
                const Text('  No deep links tested yet')
              else
                ...history.map((url) => Text('  • $url')),
              const SizedBox(height: 16),
              Text(
                  'Authentication: ${_authService.isAuthenticated ? 'Active' : 'Inactive'}',),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _testHelper.clearDeepLinkHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear History'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Parameter classes for type-safe navigation
class UserParams {
  const UserParams({required this.userId});
  final String userId;
}

class ProductParams {
  const ProductParams({
    required this.productId,
    required this.category,
    this.variant,
  });
  final String productId;
  final String category;
  final String? variant;
}

class SettingsParams {
  const SettingsParams({required this.section});
  final String section;
}

class ModalParams {
  const ModalParams({
    required this.title,
    required this.content,
  });
  final String title;
  final String content;
}

class TabParams {
  const TabParams({required this.initialTab});
  final int initialTab;
}

// Screen implementations
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, size: 64),
              SizedBox(height: 16),
              Text('Home Screen', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
      );
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 64),
              const SizedBox(height: 16),
              Text('User Profile: $userId',
                  style: const TextStyle(fontSize: 24),),
            ],
          ),
        ),
      );
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.category,
    this.variant,
  });
  final String productId;
  final String category;
  final String? variant;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 64),
              const SizedBox(height: 16),
              Text('Product: $productId', style: const TextStyle(fontSize: 24)),
              Text('Category: $category'),
              if (variant != null) Text('Variant: $variant'),
            ],
          ),
        ),
      );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.section});
  final String section;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings, size: 64),
              const SizedBox(height: 16),
              Text('Settings: $section', style: const TextStyle(fontSize: 24)),
            ],
          ),
        ),
      );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64),
              const SizedBox(height: 16),
              const Text('Login Screen', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onLogin,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}

class ModalScreen extends StatelessWidget {
  const ModalScreen({
    super.key,
    required this.title,
    required this.content,
    required this.onClose,
  });
  final String title;
  final String content;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info, size: 64),
                const SizedBox(height: 16),
                Text(content, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onClose,
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
}

class TabNavigationScreen extends StatefulWidget {
  const TabNavigationScreen({
    super.key,
    required this.initialTab,
    required this.routeBuilder,
  });
  final int initialTab;
  final toolkit.DefaultRouteBuilder routeBuilder;

  @override
  State<TabNavigationScreen> createState() => _TabNavigationScreenState();
}

class _TabNavigationScreenState extends State<TabNavigationScreen> {
  late int _currentTab;
  late List<toolkit.DefaultNavigationStack> _tabStacks;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;

    // Create separate navigation stacks for each tab
    _tabStacks = List.generate(
      3,
      (index) => widget.routeBuilder.createNavigationStack(),
    );
  }

  @override
  void dispose() {
    for (final stack in _tabStacks) {
      widget.routeBuilder.removeNavigationStack(stack);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Tab Navigation'),
        ),
        body: IndexedStack(
          index: _currentTab,
          children: [
            _buildTabContent(0, 'Home Tab', Icons.home),
            _buildTabContent(1, 'Search Tab', Icons.search),
            _buildTabContent(2, 'Profile Tab', Icons.person),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) {
            setState(() {
              _currentTab = index;
            });
            // Switch to the corresponding navigation stack
            widget.routeBuilder.setActiveStack(_tabStacks[index]);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );

  Widget _buildTabContent(int tabIndex, String title, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            StreamBuilder<List<toolkit.NavigationRoute>>(
              stream: _tabStacks[tabIndex].stackStream,
              initialData: _tabStacks[tabIndex].history,
              builder: (context, snapshot) {
                final history = snapshot.data ?? [];
                return Column(
                  children: [
                    Text('Stack depth: ${history.length}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _tabStacks[tabIndex].push(
                          toolkit.NavigationRoute(
                            path: '/tab$tabIndex/page${history.length + 1}',
                            parameters: {
                              'timestamp': DateTime.now().toString(),
                            },
                          ),
                        );
                      },
                      child: const Text('Push Route'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tabStacks[tabIndex].canPop
                          ? () => _tabStacks[tabIndex].pop<void>()
                          : null,
                      child: const Text('Pop Route'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

// Authentication service for demo
class AuthenticationService {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  void login() {
    _isAuthenticated = true;
  }

  void logout() {
    _isAuthenticated = false;
  }
}

// Helper class for testing navigation functionality
class NavigationTestHelper {

  NavigationTestHelper(this._routeBuilder);
  final toolkit.DefaultRouteBuilder _routeBuilder;
  final List<String> _deepLinkHistory = [];

  /// Simulates a deep link navigation for testing
  Future<bool> simulateDeepLink(String url) async {
    _deepLinkHistory.add(url);
    return _routeBuilder.handleDeepLink(url);
  }

  /// Gets the history of simulated deep links
  List<String> get simulatedDeepLinkHistory =>
      List.unmodifiable(_deepLinkHistory);

  /// Clears the deep link history
  void clearDeepLinkHistory() {
    _deepLinkHistory.clear();
  }
}
