# Navigation Guide

The Flutter Productivity Toolkit provides a powerful, type-safe navigation system that combines declarative route definitions with advanced features like deep linking, route guards, and multiple navigation stacks. This guide covers everything from basic navigation to complex routing scenarios.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Basic Usage](#basic-usage)
3. [Route Definition](#route-definition)
4. [Parameter Passing](#parameter-passing)
5. [Navigation Guards](#navigation-guards)
6. [Deep Linking](#deep-linking)
7. [Nested Navigation](#nested-navigation)
8. [Tab Navigation](#tab-navigation)
9. [Drawer Integration](#drawer-integration)
10. [Custom Transitions](#custom-transitions)
11. [Authentication Patterns](#authentication-patterns)
12. [Protected Routes](#protected-routes)
13. [Multiple Navigation Stacks](#multiple-navigation-stacks)
14. [Testing Navigation](#testing-navigation)
15. [Troubleshooting](#troubleshooting)

## Core Concepts

### Navigation Architecture

The toolkit's navigation system is built around several key components:

- **RouteBuilder**: Abstract builder for declarative navigation with type-safe routing
- **NavigationStack**: Manages route history and navigation state
- **RouteInformation**: Contains route path, parameters, and metadata
- **RouteGuard**: Controls access to routes with authentication and validation
- **DeepLinkConfiguration**: Handles external URL navigation
- **RouteTransition**: Defines custom transition animations

### Type-Safe Routing

All navigation in the toolkit is type-safe, preventing runtime errors:

```dart
// ❌ String-based navigation (error-prone)
Navigator.pushNamed(context, '/user/123');

// ✅ Type-safe navigation (compile-time checked)
await routeBuilder.navigate<UserParams, void>(
  '/user',
  params: UserParams(userId: '123'),
);
```

### Declarative Route Definition

Routes are defined declaratively with automatic parameter validation:

```dart
// Define route with typed parameters
routeBuilder.defineRoute<UserParams>('/user', (params) {
  return UserProfileScreen(userId: params.userId);
});
```

## Basic Usage

### Setting Up Navigation

Initialize the navigation system in your app:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late DefaultRouteBuilder _routeBuilder;
  late DefaultNavigationStack _navigationStack;

  @override
  void initState() {
    super.initState();
    _setupNavigation();
  }

  void _setupNavigation() {
    // Create route builder
    _routeBuilder = DefaultRouteBuilder();
    
    // Create navigation stack
    _navigationStack = _routeBuilder.createNavigationStack();
    _routeBuilder.setActiveStack(_navigationStack);
    
    // Define routes
    _defineRoutes();
  }
  void _defineRoutes() {
    // Home route (no parameters)
    _routeBuilder.defineRoute<void>('/home', (params) {
      return HomeScreen();
    });
    
    // User profile route with parameters
    _routeBuilder.defineRoute<UserParams>('/user', (params) {
      return UserProfileScreen(userId: params.userId);
    });
    
    // Settings route
    _routeBuilder.defineRoute<SettingsParams>('/settings', (params) {
      return SettingsScreen(section: params.section);
    });
  }

  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Demo',
      home: NavigationDemo(routeBuilder: _routeBuilder),
    );
  }
}
```

### Parameter Classes

Define parameter classes for type-safe navigation:

```dart
// User profile parameters
class UserParams {
  final String userId;
  
  const UserParams({required this.userId});
  
  @override
  String toString() => 'UserParams(userId: $userId)';
}

// Settings parameters
class SettingsParams {
  final String section;
  
  const SettingsParams({required this.section});
  
  @override
  String toString() => 'SettingsParams(section: $section)';
}

// Product details parameters
class ProductParams {
  final String productId;
  final String category;
  final String? variant;
  
  const ProductParams({
    required this.productId,
    required this.category,
    this.variant,
  });
  
  @override
  String toString() => 'ProductParams(productId: $productId, category: $category, variant: $variant)';
}
```

### Basic Navigation

Navigate between routes using the route builder:

```dart
class NavigationDemo extends StatefulWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const NavigationDemo({required this.routeBuilder});
  
  @override
  _NavigationDemoState createState() => _NavigationDemoState();
}

class _NavigationDemoState extends State<NavigationDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Demo')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _navigateToHome,
            child: Text('Go to Home'),
          ),
          ElevatedButton(
            onPressed: () => _navigateToUser('user123'),
            child: Text('Go to User Profile'),
          ),
          ElevatedButton(
            onPressed: () => _navigateToSettings('general'),
            child: Text('Go to Settings'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _navigateToHome() async {
    await widget.routeBuilder.navigate<void, void>('/home');
  }
  
  Future<void> _navigateToUser(String userId) async {
    await widget.routeBuilder.navigate<UserParams, void>(
      '/user',
      params: UserParams(userId: userId),
    );
  }
  
  Future<void> _navigateToSettings(String section) async {
    await widget.routeBuilder.navigate<SettingsParams, void>(
      '/settings',
      params: SettingsParams(section: section),
    );
  }
}
```

## Route Definition

### Simple Routes

Define routes without parameters:

```dart
// Home route
routeBuilder.defineRoute<void>('/home', (params) {
  return HomeScreen();
});

// About route
routeBuilder.defineRoute<void>('/about', (params) {
  return AboutScreen();
});

// Contact route
routeBuilder.defineRoute<void>('/contact', (params) {
  return ContactScreen();
});
```

### Parameterized Routes

Define routes that accept typed parameters:

```dart
// User profile route
routeBuilder.defineRoute<UserParams>('/user', (params) {
  return UserProfileScreen(
    userId: params.userId,
  );
});

// Product details route
routeBuilder.defineRoute<ProductParams>('/product', (params) {
  return ProductDetailsScreen(
    productId: params.productId,
    category: params.category,
    variant: params.variant,
  );
});

// Blog post route
routeBuilder.defineRoute<BlogPostParams>('/blog/post', (params) {
  return BlogPostScreen(
    postId: params.postId,
    slug: params.slug,
  );
});
```

### Routes with Return Values

Define routes that can return values:

```dart
// Modal route that returns a result
routeBuilder.defineRoute<ModalParams>('/modal', (params) {
  return ModalScreen(
    title: params.title,
    content: params.content,
    onResult: (result) {
      // Handle result
      Navigator.of(context).pop(result);
    },
  );
});

// Form route that returns form data
routeBuilder.defineRoute<FormParams>('/form', (params) {
  return FormScreen(
    initialData: params.initialData,
    onSubmit: (formData) {
      Navigator.of(context).pop(formData);
    },
  );
});

// Usage with return values
Future<String?> showModal() async {
  final result = await routeBuilder.navigate<ModalParams, String>(
    '/modal',
    params: ModalParams(
      title: 'Confirmation',
      content: 'Are you sure?',
    ),
  );
  
  return result; // String? returned from modal
}
```

## Parameter Passing

### Simple Parameters

Pass simple data types as parameters:

```dart
class SimpleParams {
  final String title;
  final int count;
  final bool isEnabled;
  
  const SimpleParams({
    required this.title,
    required this.count,
    required this.isEnabled,
  });
}

// Navigate with simple parameters
await routeBuilder.navigate<SimpleParams, void>(
  '/simple',
  params: SimpleParams(
    title: 'Hello World',
    count: 42,
    isEnabled: true,
  ),
);
```

### Complex Parameters

Pass complex objects and collections:

```dart
class ComplexParams {
  final User user;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  
  const ComplexParams({
    required this.user,
    required this.tags,
    required this.metadata,
    required this.timestamp,
  });
}

// Navigate with complex parameters
await routeBuilder.navigate<ComplexParams, void>(
  '/complex',
  params: ComplexParams(
    user: User(id: '123', name: 'John Doe'),
    tags: ['flutter', 'navigation', 'mobile'],
    metadata: {
      'source': 'app',
      'version': '1.0.0',
    },
    timestamp: DateTime.now(),
  ),
);
```

### Optional Parameters

Handle optional parameters with nullable types:

```dart
class OptionalParams {
  final String requiredParam;
  final String? optionalParam;
  final int? optionalCount;
  
  const OptionalParams({
    required this.requiredParam,
    this.optionalParam,
    this.optionalCount,
  });
}

// Navigate with optional parameters
await routeBuilder.navigate<OptionalParams, void>(
  '/optional',
  params: OptionalParams(
    requiredParam: 'Required Value',
    optionalParam: null, // Optional
    optionalCount: 10,   // Optional but provided
  ),
);
```

### Parameter Validation

Validate parameters in your parameter classes:

```dart
class ValidatedParams {
  final String email;
  final int age;
  final String phoneNumber;
  
  ValidatedParams({
    required String email,
    required int age,
    required String phoneNumber,
  }) : email = _validateEmail(email),
       age = _validateAge(age),
       phoneNumber = _validatePhoneNumber(phoneNumber);
  
  static String _validateEmail(String email) {
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }
    return email;
  }
  
  static int _validateAge(int age) {
    if (age < 0 || age > 150) {
      throw ArgumentError('Age must be between 0 and 150');
    }
    return age;
  }
  
  static String _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phoneNumber)) {
      throw ArgumentError('Invalid phone number format');
    }
    return phoneNumber;
  }
}
```

## Navigation Guards

### Basic Route Guards

Implement route guards to control access to routes:

```dart
class AuthenticationGuard extends RouteGuard {
  final bool Function() isAuthenticated;
  final String redirectRoute;
  
  AuthenticationGuard({
    required this.isAuthenticated,
    required this.redirectRoute,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    if (isAuthenticated()) {
      return true; // Allow navigation
    }
    return redirectRoute; // Redirect to login
  }
}

// Usage with route definition
routeBuilder.defineRouteWithGuards<UserParams>(
  '/user',
  (params) => UserProfileScreen(userId: params.userId),
  guards: [
    AuthenticationGuard(
      isAuthenticated: () => AuthService.instance.isLoggedIn,
      redirectRoute: '/login',
    ),
  ],
);
```

### Permission-Based Guards

Create guards that check specific permissions:

```dart
class PermissionGuard extends RouteGuard {
  final String requiredPermission;
  final PermissionService permissionService;
  
  PermissionGuard({
    required this.requiredPermission,
    required this.permissionService,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final hasPermission = await permissionService.hasPermission(requiredPermission);
    
    if (hasPermission) {
      return true;
    }
    
    // Show permission denied dialog or redirect
    return '/permission-denied';
  }
}

// Usage
routeBuilder.defineRouteWithGuards<AdminParams>(
  '/admin',
  (params) => AdminScreen(),
  guards: [
    AuthenticationGuard(
      isAuthenticated: () => AuthService.instance.isLoggedIn,
      redirectRoute: '/login',
    ),
    PermissionGuard(
      requiredPermission: 'admin_access',
      permissionService: PermissionService.instance,
    ),
  ],
);
```

### Custom Guards

Create custom guards for specific business logic:

```dart
class SubscriptionGuard extends RouteGuard {
  final SubscriptionService subscriptionService;
  
  SubscriptionGuard({required this.subscriptionService});
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final subscription = await subscriptionService.getCurrentSubscription();
    
    if (subscription == null) {
      return '/subscription-required';
    }
    
    if (subscription.isExpired) {
      return '/subscription-expired';
    }
    
    if (!subscription.hasFeature('premium_navigation')) {
      return '/upgrade-required';
    }
    
    return true;
  }
}

class MaintenanceGuard extends RouteGuard {
  final MaintenanceService maintenanceService;
  
  MaintenanceGuard({required this.maintenanceService});
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final isUnderMaintenance = await maintenanceService.isUnderMaintenance();
    
    if (isUnderMaintenance && route.path != '/maintenance') {
      return '/maintenance';
    }
    
    return true;
  }
}
```

### Guard Composition

Combine multiple guards for complex access control:

```dart
// Define a premium feature route with multiple guards
routeBuilder.defineRouteWithGuards<PremiumFeatureParams>(
  '/premium-feature',
  (params) => PremiumFeatureScreen(featureId: params.featureId),
  guards: [
    // Must be authenticated
    AuthenticationGuard(
      isAuthenticated: () => AuthService.instance.isLoggedIn,
      redirectRoute: '/login',
    ),
    // Must have valid subscription
    SubscriptionGuard(
      subscriptionService: SubscriptionService.instance,
    ),
    // Must have specific permission
    PermissionGuard(
      requiredPermission: 'premium_features',
      permissionService: PermissionService.instance,
    ),
    // Check maintenance status
    MaintenanceGuard(
      maintenanceService: MaintenanceService.instance,
    ),
  ],
);
```

## Deep Linking

### Basic Deep Link Configuration

Set up deep linking for your application:

```dart
final routeBuilder = DefaultRouteBuilder(
  deepLinkConfig: DeepLinkConfiguration(
    scheme: 'myapp',
    host: 'example.com',
    pathPatterns: {
      '/user/:id': '/user',
      '/product/:id/details': '/product',
      '/blog/:slug': '/blog/post',
    },
    handleUniversalLinks: true,
  ),
);
```

### Deep Link Handlers

Register custom deep link handlers:

```dart
void _setupDeepLinkHandlers() {
  // User profile deep link
  routeBuilder.registerDeepLinkHandler('/user/:id', (params) async {
    final userId = params['id'];
    if (userId != null) {
      await routeBuilder.navigate<UserParams, void>(
        '/user',
        params: UserParams(userId: userId),
      );
      return true;
    }
    return false;
  });
  
  // Product details deep link with query parameters
  routeBuilder.registerDeepLinkHandler('/product/:id/details', (params) async {
    final productId = params['id'];
    final category = params['category'] ?? 'general';
    final variant = params['variant'];
    
    if (productId != null) {
      await routeBuilder.navigate<ProductParams, void>(
        '/product',
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
  
  // Blog post deep link
  routeBuilder.registerDeepLinkHandler('/blog/:slug', (params) async {
    final slug = params['slug'];
    if (slug != null) {
      await routeBuilder.navigate<BlogPostParams, void>(
        '/blog/post',
        params: BlogPostParams(slug: slug),
      );
      return true;
    }
    return false;
  });
}
```

### Universal Links

Handle universal links (https/http URLs):

```dart
final routeBuilder = DefaultRouteBuilder(
  deepLinkConfig: DeepLinkConfiguration(
    scheme: 'https',
    host: 'myapp.com',
    pathPatterns: {
      '/share/user/:id': '/user',
      '/share/product/:id': '/product',
    },
    handleUniversalLinks: true,
  ),
);

// Handle universal links
routeBuilder.registerDeepLinkHandler('/share/user/:id', (params) async {
  final userId = params['id'];
  if (userId != null) {
    // Show sharing interface or navigate to user
    await routeBuilder.navigate<UserParams, void>(
      '/user',
      params: UserParams(userId: userId),
    );
    return true;
  }
  return false;
});
```

### Deep Link Testing

Test deep links programmatically:

```dart
class DeepLinkTester {
  final DefaultRouteBuilder routeBuilder;
  
  DeepLinkTester(this.routeBuilder);
  
  Future<bool> testDeepLink(String url) async {
    try {
      final success = await routeBuilder.handleDeepLink(url);
      print('Deep link $url: ${success ? 'SUCCESS' : 'FAILED'}');
      return success;
    } catch (e) {
      print('Deep link $url: ERROR - $e');
      return false;
    }
  }
  
  Future<void> runDeepLinkTests() async {
    final testUrls = [
      'myapp://example.com/user/123',
      'myapp://example.com/product/456/details?category=electronics',
      'https://myapp.com/share/user/789',
      'myapp://example.com/invalid/route',
    ];
    
    for (final url in testUrls) {
      await testDeepLink(url);
    }
  }
}
```

## Nested Navigation

### Tab-Based Nested Navigation

Implement nested navigation within tabs:

```dart
class TabNavigationScreen extends StatefulWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const TabNavigationScreen({required this.routeBuilder});
  
  @override
  _TabNavigationScreenState createState() => _TabNavigationScreenState();
}

class _TabNavigationScreenState extends State<TabNavigationScreen> {
  int _currentTab = 0;
  late List<DefaultNavigationStack> _tabStacks;
  
  @override
  void initState() {
    super.initState();
    
    // Create separate navigation stacks for each tab
    _tabStacks = List.generate(
      3,
      (index) => widget.routeBuilder.createNavigationStack(),
    );
    
    // Set initial stack
    widget.routeBuilder.setActiveStack(_tabStacks[0]);
  }
  
  @override
  void dispose() {
    // Clean up navigation stacks
    for (final stack in _tabStacks) {
      widget.routeBuilder.removeNavigationStack(stack);
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildTabContent(0, 'Home'),
          _buildTabContent(1, 'Search'),
          _buildTabContent(2, 'Profile'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: _onTabTapped,
        items: [
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
  }
  
  void _onTabTapped(int index) {
    setState(() {
      _currentTab = index;
    });
    
    // Switch to the corresponding navigation stack
    widget.routeBuilder.setActiveStack(_tabStacks[index]);
  }
  
  Widget _buildTabContent(int tabIndex, String title) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: _tabStacks[tabIndex].stackStream,
      initialData: _tabStacks[tabIndex].history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        
        return Column(
          children: [
            AppBar(
              title: Text('$title Tab'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 16),
                    Text('Stack depth: ${history.length}'),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _pushRoute(tabIndex),
                      child: Text('Push Route'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tabStacks[tabIndex].canPop
                          ? () => _tabStacks[tabIndex].pop()
                          : null,
                      child: Text('Pop Route'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _pushRoute(int tabIndex) {
    final route = NavigationRoute(
      path: '/tab$tabIndex/page${_tabStacks[tabIndex].history.length + 1}',
      parameters: {
        'timestamp': DateTime.now().toString(),
        'tabIndex': tabIndex,
      },
    );
    
    _tabStacks[tabIndex].push(route);
  }
}
```
### Drawer-Based Nested Navigation

Implement nested navigation within a drawer:

```dart
class DrawerNavigationScreen extends StatefulWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const DrawerNavigationScreen({required this.routeBuilder});
  
  @override
  _DrawerNavigationScreenState createState() => _DrawerNavigationScreenState();
}

class _DrawerNavigationScreenState extends State<DrawerNavigationScreen> {
  late DefaultNavigationStack _drawerStack;
  String _currentSection = 'home';
  
  @override
  void initState() {
    super.initState();
    _drawerStack = widget.routeBuilder.createNavigationStack();
    widget.routeBuilder.setActiveStack(_drawerStack);
  }
  
  @override
  void dispose() {
    widget.routeBuilder.removeNavigationStack(_drawerStack);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getSectionTitle(_currentSection)),
      ),
      drawer: _buildDrawer(),
      body: _buildSectionContent(_currentSection),
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Navigation Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            section: 'home',
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            section: 'profile',
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            section: 'settings',
          ),
          _buildDrawerItem(
            icon: Icons.help,
            title: 'Help',
            section: 'help',
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String section,
  }) {
    final isSelected = _currentSection == section;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      selected: isSelected,
      onTap: () => _navigateToSection(section),
    );
  }
  
  void _navigateToSection(String section) {
    setState(() {
      _currentSection = section;
    });
    
    // Clear the drawer stack and push new section
    _drawerStack.clear();
    _drawerStack.push(NavigationRoute(
      path: '/$section',
      parameters: {'section': section},
    ));
    
    Navigator.of(context).pop(); // Close drawer
  }
  
  String _getSectionTitle(String section) {
    switch (section) {
      case 'home':
        return 'Home';
      case 'profile':
        return 'Profile';
      case 'settings':
        return 'Settings';
      case 'help':
        return 'Help';
      default:
        return 'Unknown';
    }
  }
  
  Widget _buildSectionContent(String section) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: _drawerStack.stackStream,
      initialData: _drawerStack.history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getSectionIcon(section),
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                _getSectionTitle(section),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 16),
              Text('Navigation depth: ${history.length}'),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _pushSubSection(section),
                child: Text('Go Deeper'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _drawerStack.canPop
                    ? () => _drawerStack.pop()
                    : null,
                child: Text('Go Back'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'home':
        return Icons.home;
      case 'profile':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      case 'help':
        return Icons.help;
      default:
        return Icons.help_outline;
    }
  }
  
  void _pushSubSection(String section) {
    final currentDepth = _drawerStack.history.length;
    _drawerStack.push(NavigationRoute(
      path: '/$section/sub$currentDepth',
      parameters: {
        'section': section,
        'depth': currentDepth,
        'timestamp': DateTime.now().toString(),
      },
    ));
  }
}
```

## Tab Navigation

### Basic Tab Navigation

Implement tab navigation with persistent state:

```dart
class TabNavigationExample extends StatefulWidget {
  @override
  _TabNavigationExampleState createState() => _TabNavigationExampleState();
}

class _TabNavigationExampleState extends State<TabNavigationExample>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late DefaultRouteBuilder _routeBuilder;
  late List<DefaultNavigationStack> _tabStacks;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupNavigation();
  }
  
  void _setupNavigation() {
    _routeBuilder = DefaultRouteBuilder();
    
    // Create navigation stacks for each tab
    _tabStacks = List.generate(3, (index) {
      final stack = _routeBuilder.createNavigationStack();
      
      // Initialize each tab with its home route
      stack.push(NavigationRoute(
        path: '/tab$index/home',
        parameters: {'tabIndex': index},
      ));
      
      return stack;
    });
    
    // Set initial active stack
    _routeBuilder.setActiveStack(_tabStacks[0]);
    
    // Listen to tab changes
    _tabController.addListener(_onTabChanged);
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _routeBuilder.setActiveStack(_tabStacks[_tabController.index]);
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    for (final stack in _tabStacks) {
      _routeBuilder.removeNavigationStack(stack);
    }
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tab Navigation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabView(0, 'Home'),
          _buildTabView(1, 'Search'),
          _buildTabView(2, 'Profile'),
        ],
      ),
    );
  }
  
  Widget _buildTabView(int tabIndex, String tabName) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: _tabStacks[tabIndex].stackStream,
      initialData: _tabStacks[tabIndex].history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final currentRoute = history.isNotEmpty ? history.last : null;
        
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$tabName Tab',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 8),
                      Text('Current route: ${currentRoute?.path ?? 'None'}'),
                      Text('Stack depth: ${history.length}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: _buildTabContent(tabIndex, tabName),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _pushRoute(tabIndex),
                      child: Text('Push Route'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _tabStacks[tabIndex].canPop
                          ? () => _tabStacks[tabIndex].pop()
                          : null,
                      child: Text('Pop Route'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTabContent(int tabIndex, String tabName) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: _tabStacks[tabIndex].stackStream,
      initialData: _tabStacks[tabIndex].history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        
        if (history.isEmpty) {
          return Center(child: Text('No routes in stack'));
        }
        
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final route = history[index];
            final isCurrentRoute = index == history.length - 1;
            
            return Card(
              color: isCurrentRoute ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                  backgroundColor: isCurrentRoute 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                title: Text(route.path),
                subtitle: Text('Parameters: ${route.parameters}'),
                trailing: isCurrentRoute 
                    ? Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
  
  void _pushRoute(int tabIndex) {
    final currentDepth = _tabStacks[tabIndex].history.length;
    final route = NavigationRoute(
      path: '/tab$tabIndex/page$currentDepth',
      parameters: {
        'tabIndex': tabIndex,
        'depth': currentDepth,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    _tabStacks[tabIndex].push(route);
  }
}
```
### Advanced Tab Navigation

Implement tab navigation with lazy loading and state preservation:

```dart
class AdvancedTabNavigation extends StatefulWidget {
  @override
  _AdvancedTabNavigationState createState() => _AdvancedTabNavigationState();
}

class _AdvancedTabNavigationState extends State<AdvancedTabNavigation>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late DefaultRouteBuilder _routeBuilder;
  late List<DefaultNavigationStack> _tabStacks;
  final Map<int, Widget> _tabWidgets = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupNavigation();
  }
  
  void _setupNavigation() {
    _routeBuilder = DefaultRouteBuilder();
    _tabStacks = List.generate(4, (index) {
      return _routeBuilder.createNavigationStack();
    });
    
    // Set initial active stack
    _routeBuilder.setActiveStack(_tabStacks[0]);
    _tabController.addListener(_onTabChanged);
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      _routeBuilder.setActiveStack(_tabStacks[newIndex]);
      
      // Preserve state for current tab
      _preserveTabState(_tabController.previousIndex);
      
      // Restore state for new tab
      _restoreTabState(newIndex);
    }
  }
  
  void _preserveTabState(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _tabStacks.length) {
      final stack = _tabStacks[tabIndex];
      stack.preserveState('scrollPosition', _getScrollPosition(tabIndex));
      stack.preserveState('lastAccessed', DateTime.now());
    }
  }
  
  void _restoreTabState(int tabIndex) {
    final stack = _tabStacks[tabIndex];
    final scrollPosition = stack.restoreState<double>('scrollPosition') ?? 0.0;
    final lastAccessed = stack.restoreState<DateTime>('lastAccessed');
    
    // Apply restored state to tab content
    _applyScrollPosition(tabIndex, scrollPosition);
  }
  
  double _getScrollPosition(int tabIndex) {
    // Implementation to get current scroll position
    return 0.0; // Placeholder
  }
  
  void _applyScrollPosition(int tabIndex, double position) {
    // Implementation to apply scroll position
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    for (final stack in _tabStacks) {
      _routeBuilder.removeNavigationStack(stack);
    }
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Tab Navigation'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLazyTab(0, () => HomeTabContent(_tabStacks[0])),
          _buildLazyTab(1, () => SearchTabContent(_tabStacks[1])),
          _buildLazyTab(2, () => FavoritesTabContent(_tabStacks[2])),
          _buildLazyTab(3, () => ProfileTabContent(_tabStacks[3])),
        ],
      ),
    );
  }
  
  Widget _buildLazyTab(int index, Widget Function() builder) {
    if (!_tabWidgets.containsKey(index)) {
      _tabWidgets[index] = builder();
    }
    return _tabWidgets[index]!;
  }
}

// Tab content widgets
class HomeTabContent extends StatelessWidget {
  final DefaultNavigationStack navigationStack;
  
  const HomeTabContent(this.navigationStack);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: navigationStack.stackStream,
      initialData: navigationStack.history,
      builder: (context, snapshot) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, size: 64),
              SizedBox(height: 16),
              Text('Home Tab Content'),
              SizedBox(height: 16),
              Text('Stack depth: ${snapshot.data?.length ?? 0}'),
            ],
          ),
        );
      },
    );
  }
}

class SearchTabContent extends StatefulWidget {
  final DefaultNavigationStack navigationStack;
  
  const SearchTabContent(this.navigationStack);
  
  @override
  _SearchTabContentState createState() => _SearchTabContentState();
}

class _SearchTabContentState extends State<SearchTabContent> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _performSearch,
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_searchResults[index]),
                  onTap: () => _selectSearchResult(_searchResults[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _performSearch(String query) {
    setState(() {
      _searchResults = List.generate(
        10,
        (index) => 'Search result $index for "$query"',
      );
    });
  }
  
  void _selectSearchResult(String result) {
    widget.navigationStack.push(NavigationRoute(
      path: '/search/result',
      parameters: {'result': result},
    ));
  }
}

class FavoritesTabContent extends StatelessWidget {
  final DefaultNavigationStack navigationStack;
  
  const FavoritesTabContent(this.navigationStack);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: navigationStack.stackStream,
      initialData: navigationStack.history,
      builder: (context, snapshot) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Favorites Tab Content'),
              SizedBox(height: 16),
              Text('Stack depth: ${snapshot.data?.length ?? 0}'),
            ],
          ),
        );
      },
    );
  }
}

class ProfileTabContent extends StatelessWidget {
  final DefaultNavigationStack navigationStack;
  
  const ProfileTabContent(this.navigationStack);
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: navigationStack.stackStream,
      initialData: navigationStack.history,
      builder: (context, snapshot) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                child: Icon(Icons.person, size: 32),
              ),
              SizedBox(height: 16),
              Text('Profile Tab Content'),
              SizedBox(height: 16),
              Text('Stack depth: ${snapshot.data?.length ?? 0}'),
            ],
          ),
        );
      },
    );
  }
}
```

## Drawer Integration

### Basic Drawer Navigation

Integrate navigation with Flutter's drawer:

```dart
class DrawerIntegrationExample extends StatefulWidget {
  @override
  _DrawerIntegrationExampleState createState() => _DrawerIntegrationExampleState();
}

class _DrawerIntegrationExampleState extends State<DrawerIntegrationExample> {
  late DefaultRouteBuilder _routeBuilder;
  late DefaultNavigationStack _navigationStack;
  String _currentPage = 'home';
  
  @override
  void initState() {
    super.initState();
    _setupNavigation();
  }
  
  void _setupNavigation() {
    _routeBuilder = DefaultRouteBuilder();
    _navigationStack = _routeBuilder.createNavigationStack();
    _routeBuilder.setActiveStack(_navigationStack);
    
    // Define drawer routes
    _defineDrawerRoutes();
    
    // Navigate to initial page
    _navigateToPage('home');
  }
  
  void _defineDrawerRoutes() {
    _routeBuilder.defineRoute<DrawerPageParams>('/drawer/home', (params) {
      return DrawerPageContent(
        title: 'Home',
        icon: Icons.home,
        content: 'Welcome to the home page!',
      );
    });
    
    _routeBuilder.defineRoute<DrawerPageParams>('/drawer/profile', (params) {
      return DrawerPageContent(
        title: 'Profile',
        icon: Icons.person,
        content: 'Your profile information.',
      );
    });
    
    _routeBuilder.defineRoute<DrawerPageParams>('/drawer/settings', (params) {
      return DrawerPageContent(
        title: 'Settings',
        icon: Icons.settings,
        content: 'Application settings.',
      );
    });
    
    _routeBuilder.defineRoute<DrawerPageParams>('/drawer/help', (params) {
      return DrawerPageContent(
        title: 'Help',
        icon: Icons.help,
        content: 'Help and support information.',
      );
    });
  }
  
  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_currentPage)),
      ),
      drawer: _buildDrawer(),
      body: StreamBuilder<RouteInformation>(
        stream: _routeBuilder.routeStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          return _buildPageContent(_currentPage);
        },
      ),
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Navigation Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Home',
            page: 'home',
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            page: 'profile',
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            page: 'settings',
          ),
          Divider(),
          _buildDrawerItem(
            icon: Icons.help,
            title: 'Help & Support',
            page: 'help',
          ),
          _buildDrawerItem(
            icon: Icons.info,
            title: 'About',
            page: 'about',
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String page,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentPage == page;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      onTap: onTap ?? () => _navigateToPage(page),
    );
  }
  
  void _navigateToPage(String page) {
    setState(() {
      _currentPage = page;
    });
    
    _routeBuilder.navigate<DrawerPageParams, void>(
      '/drawer/$page',
      params: DrawerPageParams(page: page),
    );
    
    Navigator.of(context).pop(); // Close drawer
  }
  
  String _getPageTitle(String page) {
    switch (page) {
      case 'home':
        return 'Home';
      case 'profile':
        return 'Profile';
      case 'settings':
        return 'Settings';
      case 'help':
        return 'Help & Support';
      default:
        return 'Navigation Demo';
    }
  }
  
  Widget _buildPageContent(String page) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: _navigationStack.stackStream,
      initialData: _navigationStack.history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getPageIcon(page)),
                          SizedBox(width: 8),
                          Text(
                            _getPageTitle(page),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(_getPageDescription(page)),
                      SizedBox(height: 16),
                      Text(
                        'Navigation Stack: ${history.length} routes',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: _buildPageSpecificContent(page),
              ),
            ],
          ),
        );
      },
    );
  }
  
  IconData _getPageIcon(String page) {
    switch (page) {
      case 'home':
        return Icons.home;
      case 'profile':
        return Icons.person;
      case 'settings':
        return Icons.settings;
      case 'help':
        return Icons.help;
      default:
        return Icons.help_outline;
    }
  }
  
  String _getPageDescription(String page) {
    switch (page) {
      case 'home':
        return 'Welcome to the home page. This is your starting point.';
      case 'profile':
        return 'Manage your profile information and preferences.';
      case 'settings':
        return 'Configure application settings and preferences.';
      case 'help':
        return 'Get help and support for using the application.';
      default:
        return 'Page description not available.';
    }
  }
  
  Widget _buildPageSpecificContent(String page) {
    switch (page) {
      case 'home':
        return _buildHomeContent();
      case 'profile':
        return _buildProfileContent();
      case 'settings':
        return _buildSettingsContent();
      case 'help':
        return _buildHelpContent();
      default:
        return Center(child: Text('Content not available'));
    }
  }
  
  Widget _buildHomeContent() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            subtitle: Text('View your dashboard'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('dashboard'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('View recent notifications'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('notifications'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileContent() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
            subtitle: Text('Update your profile information'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('edit-profile'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy Settings'),
            subtitle: Text('Manage your privacy preferences'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('privacy'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingsContent() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.palette),
            title: Text('Theme'),
            subtitle: Text('Choose your preferred theme'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('theme'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.language),
            title: Text('Language'),
            subtitle: Text('Select your language'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('language'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHelpContent() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('FAQ'),
            subtitle: Text('Frequently asked questions'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('faq'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.contact_support),
            title: Text('Contact Support'),
            subtitle: Text('Get in touch with our support team'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _pushSubPage('contact'),
          ),
        ),
      ],
    );
  }
  
  void _pushSubPage(String subPage) {
    _navigationStack.push(NavigationRoute(
      path: '/drawer/$_currentPage/$subPage',
      parameters: {
        'parentPage': _currentPage,
        'subPage': subPage,
        'timestamp': DateTime.now().toString(),
      },
    ));
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About'),
        content: Text('Navigation Demo App\nVersion 1.0.0'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
    
    Navigator.of(context).pop(); // Close drawer
  }
}

// Parameter classes
class DrawerPageParams {
  final String page;
  
  const DrawerPageParams({required this.page});
}

// Page content widget
class DrawerPageContent extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  
  const DrawerPageContent({
    required this.title,
    required this.icon,
    required this.content,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          Text(
            content,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
```
## Custom Transitions

### Basic Custom Transitions

Define custom transition animations for routes:

```dart
class CustomTransitionExample extends StatefulWidget {
  @override
  _CustomTransitionExampleState createState() => _CustomTransitionExampleState();
}

class _CustomTransitionExampleState extends State<CustomTransitionExample> {
  late DefaultRouteBuilder _routeBuilder;
  
  @override
  void initState() {
    super.initState();
    _setupNavigation();
  }
  
  void _setupNavigation() {
    _routeBuilder = DefaultRouteBuilder();
    
    // Define routes with custom transitions
    _defineRoutesWithTransitions();
  }
  
  void _defineRoutesWithTransitions() {
    // Slide transition route
    _routeBuilder.defineRoute<TransitionParams>('/slide', (params) {
      return TransitionDemoScreen(
        title: 'Slide Transition',
        color: Colors.blue,
        transitionType: 'slide',
      );
    });
    
    // Fade transition route
    _routeBuilder.defineRoute<TransitionParams>('/fade', (params) {
      return TransitionDemoScreen(
        title: 'Fade Transition',
        color: Colors.green,
        transitionType: 'fade',
      );
    });
    
    // Scale transition route
    _routeBuilder.defineRoute<TransitionParams>('/scale', (params) {
      return TransitionDemoScreen(
        title: 'Scale Transition',
        color: Colors.orange,
        transitionType: 'scale',
      );
    });
    
    // Custom transition route
    _routeBuilder.defineRoute<TransitionParams>('/custom', (params) {
      return TransitionDemoScreen(
        title: 'Custom Transition',
        color: Colors.purple,
        transitionType: 'custom',
      );
    });
  }
  
  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Transitions'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose a transition type:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            _buildTransitionButton(
              'Slide Transition',
              'Slides in from the right',
              Icons.arrow_forward,
              Colors.blue,
              () => _navigateWithTransition('/slide', TransitionType.slide),
            ),
            SizedBox(height: 16),
            _buildTransitionButton(
              'Fade Transition',
              'Fades in smoothly',
              Icons.opacity,
              Colors.green,
              () => _navigateWithTransition('/fade', TransitionType.fade),
            ),
            SizedBox(height: 16),
            _buildTransitionButton(
              'Scale Transition',
              'Scales up from center',
              Icons.zoom_in,
              Colors.orange,
              () => _navigateWithTransition('/scale', TransitionType.scale),
            ),
            SizedBox(height: 16),
            _buildTransitionButton(
              'Custom Transition',
              'Custom rotation and scale',
              Icons.rotate_right,
              Colors.purple,
              () => _navigateWithTransition('/custom', TransitionType.custom),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransitionButton(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _navigateWithTransition(String route, TransitionType transitionType) async {
    await _routeBuilder.navigate<TransitionParams, void>(
      route,
      params: TransitionParams(
        transitionType: transitionType,
        duration: Duration(milliseconds: 500),
      ),
    );
  }
}

// Parameter class for transitions
class TransitionParams {
  final TransitionType transitionType;
  final Duration duration;
  
  const TransitionParams({
    required this.transitionType,
    this.duration = const Duration(milliseconds: 300),
  });
}

// Demo screen for transitions
class TransitionDemoScreen extends StatelessWidget {
  final String title;
  final Color color;
  final String transitionType;
  
  const TransitionDemoScreen({
    required this.title,
    required this.color,
    required this.transitionType,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getTransitionIcon(transitionType),
                  size: 64,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This screen was shown with a $transitionType transition.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getTransitionIcon(String transitionType) {
    switch (transitionType) {
      case 'slide':
        return Icons.arrow_forward;
      case 'fade':
        return Icons.opacity;
      case 'scale':
        return Icons.zoom_in;
      case 'custom':
        return Icons.rotate_right;
      default:
        return Icons.help_outline;
    }
  }
}
```

### Advanced Custom Transitions

Create complex custom transition animations:

```dart
class AdvancedTransitionBuilder {
  static Widget buildSlideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }
  
  static Widget buildFadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
  
  static Widget buildScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: child,
    );
  }
  
  static Widget buildRotationTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
  
  static Widget buildCustomTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(animation.value * 3.14159 / 2)
            ..scale(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
```

## Authentication Patterns

### Basic Authentication Integration

Integrate authentication with navigation:

```dart
class AuthenticationService {
  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _userRole;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get userRole => _userRole;
  
  Future<bool> login(String username, String password) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    
    if (username == 'admin' && password == 'admin') {
      _isAuthenticated = true;
      _currentUserId = 'admin_user';
      _userRole = 'admin';
      return true;
    } else if (username == 'user' && password == 'user') {
      _isAuthenticated = true;
      _currentUserId = 'regular_user';
      _userRole = 'user';
      return true;
    }
    
    return false;
  }
  
  void logout() {
    _isAuthenticated = false;
    _currentUserId = null;
    _userRole = null;
  }
  
  bool hasRole(String role) {
    return _userRole == role;
  }
  
  bool hasAnyRole(List<String> roles) {
    return _userRole != null && roles.contains(_userRole);
  }
}

class AuthenticatedNavigationExample extends StatefulWidget {
  @override
  _AuthenticatedNavigationExampleState createState() => _AuthenticatedNavigationExampleState();
}

class _AuthenticatedNavigationExampleState extends State<AuthenticatedNavigationExample> {
  late DefaultRouteBuilder _routeBuilder;
  late AuthenticationService _authService;
  
  @override
  void initState() {
    super.initState();
    _authService = AuthenticationService();
    _setupNavigation();
  }
  
  void _setupNavigation() {
    _routeBuilder = DefaultRouteBuilder();
    
    // Define public routes
    _routeBuilder.defineRoute<void>('/login', (params) {
      return LoginScreen(
        authService: _authService,
        onLoginSuccess: () => _navigateToHome(),
      );
    });
    
    _routeBuilder.defineRoute<void>('/register', (params) {
      return RegisterScreen(
        onRegisterSuccess: () => _navigateToLogin(),
      );
    });
    
    // Define protected routes
    _routeBuilder.defineRouteWithGuards<void>(
      '/home',
      (params) => HomeScreen(authService: _authService),
      requiresAuthentication: true,
      guards: [
        AuthenticationGuard(
          isAuthenticated: () => _authService.isAuthenticated,
          redirectRoute: '/login',
        ),
      ],
    );
    
    _routeBuilder.defineRouteWithGuards<UserParams>(
      '/profile',
      (params) => ProfileScreen(
        userId: params.userId,
        authService: _authService,
      ),
      requiresAuthentication: true,
      guards: [
        AuthenticationGuard(
          isAuthenticated: () => _authService.isAuthenticated,
          redirectRoute: '/login',
        ),
      ],
    );
    
    // Define admin-only routes
    _routeBuilder.defineRouteWithGuards<void>(
      '/admin',
      (params) => AdminScreen(authService: _authService),
      requiresAuthentication: true,
      guards: [
        AuthenticationGuard(
          isAuthenticated: () => _authService.isAuthenticated,
          redirectRoute: '/login',
        ),
        RoleGuard(
          requiredRoles: ['admin'],
          userRole: () => _authService.userRole,
          redirectRoute: '/unauthorized',
        ),
      ],
    );
    
    _routeBuilder.defineRoute<void>('/unauthorized', (params) {
      return UnauthorizedScreen();
    });
  }
  
  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authenticated Navigation',
      home: _authService.isAuthenticated 
          ? AuthenticatedHome(
              routeBuilder: _routeBuilder,
              authService: _authService,
            )
          : LoginScreen(
              authService: _authService,
              onLoginSuccess: () => _navigateToHome(),
            ),
    );
  }
  
  void _navigateToHome() {
    setState(() {}); // Trigger rebuild to show authenticated home
  }
  
  void _navigateToLogin() {
    _routeBuilder.navigate<void, void>('/login');
  }
}

// Role-based guard
class RoleGuard extends RouteGuard {
  final List<String> requiredRoles;
  final String? Function() userRole;
  final String redirectRoute;
  
  RoleGuard({
    required this.requiredRoles,
    required this.userRole,
    required this.redirectRoute,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final currentRole = userRole();
    
    if (currentRole != null && requiredRoles.contains(currentRole)) {
      return true;
    }
    
    return redirectRoute;
  }
}

// Authentication screens
class LoginScreen extends StatefulWidget {
  final AuthenticationService authService;
  final VoidCallback onLoginSuccess;
  
  const LoginScreen({
    required this.authService,
    required this.onLoginSuccess,
  });
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Login'),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Navigate to register screen
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final success = await widget.authService.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }
}

class AuthenticatedHome extends StatelessWidget {
  final DefaultRouteBuilder routeBuilder;
  final AuthenticationService authService;
  
  const AuthenticatedHome({
    required this.routeBuilder,
    required this.authService,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _navigateToProfile();
                  break;
                case 'admin':
                  _navigateToAdmin();
                  break;
                case 'logout':
                  _logout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              if (authService.hasRole('admin'))
                PopupMenuItem(
                  value: 'admin',
                  child: Text('Admin Panel'),
                ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${authService.currentUserId}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            Text('Role: ${authService.userRole}'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _navigateToProfile,
              child: Text('View Profile'),
            ),
            if (authService.hasRole('admin')) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToAdmin,
                child: Text('Admin Panel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _navigateToProfile() {
    routeBuilder.navigate<UserParams, void>(
      '/profile',
      params: UserParams(userId: authService.currentUserId!),
    );
  }
  
  void _navigateToAdmin() {
    routeBuilder.navigate<void, void>('/admin');
  }
  
  void _logout(BuildContext context) {
    authService.logout();
    // Navigate back to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          authService: authService,
          onLoginSuccess: () {},
        ),
      ),
      (route) => false,
    );
  }
}
```
## Protected Routes

### Route Protection Strategies

Implement comprehensive route protection:

```dart
class RouteProtectionService {
  final AuthenticationService _authService;
  final PermissionService _permissionService;
  final SubscriptionService _subscriptionService;
  
  RouteProtectionService({
    required AuthenticationService authService,
    required PermissionService permissionService,
    required SubscriptionService subscriptionService,
  }) : _authService = authService,
       _permissionService = permissionService,
       _subscriptionService = subscriptionService;
  
  List<RouteGuard> createProtectionGuards({
    bool requiresAuthentication = false,
    List<String> requiredRoles = const [],
    List<String> requiredPermissions = const [],
    bool requiresActiveSubscription = false,
    List<String> requiredSubscriptionFeatures = const [],
  }) {
    final guards = <RouteGuard>[];
    
    // Authentication guard
    if (requiresAuthentication) {
      guards.add(AuthenticationGuard(
        isAuthenticated: () => _authService.isAuthenticated,
        redirectRoute: '/login',
      ));
    }
    
    // Role-based guard
    if (requiredRoles.isNotEmpty) {
      guards.add(RoleGuard(
        requiredRoles: requiredRoles,
        userRole: () => _authService.userRole,
        redirectRoute: '/unauthorized',
      ));
    }
    
    // Permission-based guard
    if (requiredPermissions.isNotEmpty) {
      guards.add(PermissionGuard(
        requiredPermissions: requiredPermissions,
        permissionService: _permissionService,
        redirectRoute: '/insufficient-permissions',
      ));
    }
    
    // Subscription guard
    if (requiresActiveSubscription) {
      guards.add(SubscriptionGuard(
        subscriptionService: _subscriptionService,
        redirectRoute: '/subscription-required',
      ));
    }
    
    // Feature-based subscription guard
    if (requiredSubscriptionFeatures.isNotEmpty) {
      guards.add(FeatureGuard(
        requiredFeatures: requiredSubscriptionFeatures,
        subscriptionService: _subscriptionService,
        redirectRoute: '/feature-not-available',
      ));
    }
    
    return guards;
  }
}

// Enhanced permission guard
class PermissionGuard extends RouteGuard {
  final List<String> requiredPermissions;
  final PermissionService permissionService;
  final String redirectRoute;
  
  PermissionGuard({
    required this.requiredPermissions,
    required this.permissionService,
    required this.redirectRoute,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    for (final permission in requiredPermissions) {
      final hasPermission = await permissionService.hasPermission(permission);
      if (!hasPermission) {
        return redirectRoute;
      }
    }
    return true;
  }
}

// Feature-based guard
class FeatureGuard extends RouteGuard {
  final List<String> requiredFeatures;
  final SubscriptionService subscriptionService;
  final String redirectRoute;
  
  FeatureGuard({
    required this.requiredFeatures,
    required this.subscriptionService,
    required this.redirectRoute,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final subscription = await subscriptionService.getCurrentSubscription();
    
    if (subscription == null || !subscription.isActive) {
      return '/subscription-required';
    }
    
    for (final feature in requiredFeatures) {
      if (!subscription.hasFeature(feature)) {
        return redirectRoute;
      }
    }
    
    return true;
  }
}

// Time-based access guard
class TimeBasedGuard extends RouteGuard {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String redirectRoute;
  
  TimeBasedGuard({
    required this.startTime,
    required this.endTime,
    required this.redirectRoute,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    
    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      return true;
    }
    
    return redirectRoute;
  }
}

// Device-based guard
class DeviceGuard extends RouteGuard {
  final List<String> allowedDeviceTypes;
  final String redirectRoute;
  
  DeviceGuard({
    required this.allowedDeviceTypes,
    required this.redirectRoute,
  });
  
  @override
  Future<Object> canActivate(RouteInformation route) async {
    final deviceType = await _getDeviceType();
    
    if (allowedDeviceTypes.contains(deviceType)) {
      return true;
    }
    
    return redirectRoute;
  }
  
  Future<String> _getDeviceType() async {
    // Implementation to detect device type
    return 'mobile'; // Placeholder
  }
}
```

### Protected Route Examples

Define routes with comprehensive protection:

```dart
class ProtectedRoutesExample extends StatefulWidget {
  @override
  _ProtectedRoutesExampleState createState() => _ProtectedRoutesExampleState();
}

class _ProtectedRoutesExampleState extends State<ProtectedRoutesExample> {
  late DefaultRouteBuilder _routeBuilder;
  late RouteProtectionService _protectionService;
  late AuthenticationService _authService;
  late PermissionService _permissionService;
  late SubscriptionService _subscriptionService;
  
  @override
  void initState() {
    super.initState();
    _setupServices();
    _setupProtectedRoutes();
  }
  
  void _setupServices() {
    _authService = AuthenticationService();
    _permissionService = PermissionService();
    _subscriptionService = SubscriptionService();
    
    _protectionService = RouteProtectionService(
      authService: _authService,
      permissionService: _permissionService,
      subscriptionService: _subscriptionService,
    );
    
    _routeBuilder = DefaultRouteBuilder();
  }
  
  void _setupProtectedRoutes() {
    // Public routes
    _routeBuilder.defineRoute<void>('/login', (params) {
      return LoginScreen(
        authService: _authService,
        onLoginSuccess: () => _navigateToHome(),
      );
    });
    
    _routeBuilder.defineRoute<void>('/register', (params) {
      return RegisterScreen();
    });
    
    // Basic protected route (authentication only)
    _routeBuilder.defineRouteWithGuards<void>(
      '/dashboard',
      (params) => DashboardScreen(),
      guards: _protectionService.createProtectionGuards(
        requiresAuthentication: true,
      ),
    );
    
    // Role-protected route
    _routeBuilder.defineRouteWithGuards<void>(
      '/admin',
      (params) => AdminScreen(),
      guards: _protectionService.createProtectionGuards(
        requiresAuthentication: true,
        requiredRoles: ['admin', 'super_admin'],
      ),
    );
    
    // Permission-protected route
    _routeBuilder.defineRouteWithGuards<void>(
      '/user-management',
      (params) => UserManagementScreen(),
      guards: _protectionService.createProtectionGuards(
        requiresAuthentication: true,
        requiredPermissions: ['manage_users', 'view_user_data'],
      ),
    );
    
    // Subscription-protected route
    _routeBuilder.defineRouteWithGuards<void>(
      '/premium-features',
      (params) => PremiumFeaturesScreen(),
      guards: _protectionService.createProtectionGuards(
        requiresAuthentication: true,
        requiresActiveSubscription: true,
        requiredSubscriptionFeatures: ['premium_access'],
      ),
    );
    
    // Multi-level protected route
    _routeBuilder.defineRouteWithGuards<void>(
      '/enterprise-dashboard',
      (params) => EnterpriseDashboardScreen(),
      guards: _protectionService.createProtectionGuards(
        requiresAuthentication: true,
        requiredRoles: ['enterprise_admin'],
        requiredPermissions: ['view_enterprise_data', 'manage_enterprise'],
        requiresActiveSubscription: true,
        requiredSubscriptionFeatures: ['enterprise_features'],
      ),
    );
    
    // Time-restricted route
    _routeBuilder.defineRouteWithGuards<void>(
      '/maintenance-panel',
      (params) => MaintenancePanelScreen(),
      guards: [
        ..._protectionService.createProtectionGuards(
          requiresAuthentication: true,
          requiredRoles: ['maintenance'],
        ),
        TimeBasedGuard(
          startTime: TimeOfDay(hour: 2, minute: 0),
          endTime: TimeOfDay(hour: 6, minute: 0),
          redirectRoute: '/maintenance-not-available',
        ),
      ],
    );
    
    // Device-restricted route
    _routeBuilder.defineRouteWithGuards<void>(
      '/mobile-only-feature',
      (params) => MobileOnlyFeatureScreen(),
      guards: [
        ..._protectionService.createProtectionGuards(
          requiresAuthentication: true,
        ),
        DeviceGuard(
          allowedDeviceTypes: ['mobile', 'tablet'],
          redirectRoute: '/desktop-not-supported',
        ),
      ],
    );
    
    // Error routes
    _routeBuilder.defineRoute<void>('/unauthorized', (params) {
      return UnauthorizedScreen();
    });
    
    _routeBuilder.defineRoute<void>('/insufficient-permissions', (params) {
      return InsufficientPermissionsScreen();
    });
    
    _routeBuilder.defineRoute<void>('/subscription-required', (params) {
      return SubscriptionRequiredScreen();
    });
    
    _routeBuilder.defineRoute<void>('/feature-not-available', (params) {
      return FeatureNotAvailableScreen();
    });
  }
  
  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Protected Routes Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAuthenticationStatus(),
            SizedBox(height: 24),
            _buildRouteButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuthenticationStatus() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text('Authenticated: ${_authService.isAuthenticated}'),
            if (_authService.isAuthenticated) ...[
              Text('User ID: ${_authService.currentUserId}'),
              Text('Role: ${_authService.userRole}'),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                if (!_authService.isAuthenticated)
                  ElevatedButton(
                    onPressed: _quickLogin,
                    child: Text('Quick Login'),
                  )
                else
                  ElevatedButton(
                    onPressed: _logout,
                    child: Text('Logout'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteButtons() {
    return Expanded(
      child: ListView(
        children: [
          _buildRouteButton(
            'Dashboard',
            'Basic protected route',
            Icons.dashboard,
            () => _navigateToRoute('/dashboard'),
          ),
          _buildRouteButton(
            'Admin Panel',
            'Role-protected route',
            Icons.admin_panel_settings,
            () => _navigateToRoute('/admin'),
          ),
          _buildRouteButton(
            'User Management',
            'Permission-protected route',
            Icons.people,
            () => _navigateToRoute('/user-management'),
          ),
          _buildRouteButton(
            'Premium Features',
            'Subscription-protected route',
            Icons.star,
            () => _navigateToRoute('/premium-features'),
          ),
          _buildRouteButton(
            'Enterprise Dashboard',
            'Multi-level protected route',
            Icons.business,
            () => _navigateToRoute('/enterprise-dashboard'),
          ),
          _buildRouteButton(
            'Maintenance Panel',
            'Time-restricted route',
            Icons.build,
            () => _navigateToRoute('/maintenance-panel'),
          ),
          _buildRouteButton(
            'Mobile Feature',
            'Device-restricted route',
            Icons.phone_android,
            () => _navigateToRoute('/mobile-only-feature'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRouteButton(
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }
  
  void _quickLogin() {
    // Simulate quick login for demo
    _authService.login('admin', 'admin');
    setState(() {});
  }
  
  void _logout() {
    _authService.logout();
    setState(() {});
  }
  
  void _navigateToHome() {
    setState(() {});
  }
  
  Future<void> _navigateToRoute(String route) async {
    try {
      await _routeBuilder.navigate<void, void>(route);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Supporting services
class PermissionService {
  final Map<String, List<String>> _rolePermissions = {
    'admin': ['manage_users', 'view_user_data', 'manage_enterprise'],
    'user': ['view_own_data'],
    'enterprise_admin': ['view_enterprise_data', 'manage_enterprise'],
    'maintenance': ['system_maintenance'],
  };
  
  Future<bool> hasPermission(String permission) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 100));
    
    final userRole = AuthenticationService().userRole;
    if (userRole == null) return false;
    
    final permissions = _rolePermissions[userRole] ?? [];
    return permissions.contains(permission);
  }
}

class SubscriptionService {
  Future<Subscription?> getCurrentSubscription() async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 100));
    
    return Subscription(
      isActive: true,
      features: ['premium_access', 'enterprise_features'],
    );
  }
}

class Subscription {
  final bool isActive;
  final List<String> features;
  
  Subscription({
    required this.isActive,
    required this.features,
  });
  
  bool hasFeature(String feature) {
    return features.contains(feature);
  }
}
```

## Multiple Navigation Stacks

### Managing Multiple Stacks

Handle complex navigation scenarios with multiple stacks:

```dart
class MultiStackNavigationExample extends StatefulWidget {
  @override
  _MultiStackNavigationExampleState createState() => _MultiStackNavigationExampleState();
}

class _MultiStackNavigationExampleState extends State<MultiStackNavigationExample> {
  late DefaultRouteBuilder _routeBuilder;
  late DefaultNavigationStack _mainStack;
  late DefaultNavigationStack _modalStack;
  late DefaultNavigationStack _overlayStack;
  
  String _activeStackName = 'main';
  
  @override
  void initState() {
    super.initState();
    _setupMultipleStacks();
  }
  
  void _setupMultipleStacks() {
    _routeBuilder = DefaultRouteBuilder();
    
    // Create multiple navigation stacks
    _mainStack = _routeBuilder.createNavigationStack();
    _modalStack = _routeBuilder.createNavigationStack();
    _overlayStack = _routeBuilder.createNavigationStack();
    
    // Set initial active stack
    _routeBuilder.setActiveStack(_mainStack);
    
    // Define routes for different stacks
    _defineStackRoutes();
  }
  
  void _defineStackRoutes() {
    // Main stack routes
    _routeBuilder.defineRoute<StackParams>('/main/home', (params) {
      return StackContentScreen(
        title: 'Main Home',
        stackName: 'main',
        color: Colors.blue,
      );
    });
    
    _routeBuilder.defineRoute<StackParams>('/main/details', (params) {
      return StackContentScreen(
        title: 'Main Details',
        stackName: 'main',
        color: Colors.blue,
      );
    });
    
    // Modal stack routes
    _routeBuilder.defineRoute<StackParams>('/modal/dialog', (params) {
      return StackContentScreen(
        title: 'Modal Dialog',
        stackName: 'modal',
        color: Colors.green,
      );
    });
    
    _routeBuilder.defineRoute<StackParams>('/modal/form', (params) {
      return StackContentScreen(
        title: 'Modal Form',
        stackName: 'modal',
        color: Colors.green,
      );
    });
    
    // Overlay stack routes
    _routeBuilder.defineRoute<StackParams>('/overlay/notification', (params) {
      return StackContentScreen(
        title: 'Overlay Notification',
        stackName: 'overlay',
        color: Colors.orange,
      );
    });
    
    _routeBuilder.defineRoute<StackParams>('/overlay/popup', (params) {
      return StackContentScreen(
        title: 'Overlay Popup',
        stackName: 'overlay',
        color: Colors.orange,
      );
    });
  }
  
  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multiple Navigation Stacks'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _switchStack,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'main', child: Text('Main Stack')),
              PopupMenuItem(value: 'modal', child: Text('Modal Stack')),
              PopupMenuItem(value: 'overlay', child: Text('Overlay Stack')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStackSelector(),
          _buildStackInfo(),
          Expanded(child: _buildStackContent()),
          _buildStackControls(),
        ],
      ),
    );
  }
  
  Widget _buildStackSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Active Stack: '),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _activeStackName,
            onChanged: (value) {
              if (value != null) {
                _switchStack(value);
              }
            },
            items: [
              DropdownMenuItem(value: 'main', child: Text('Main')),
              DropdownMenuItem(value: 'modal', child: Text('Modal')),
              DropdownMenuItem(value: 'overlay', child: Text('Overlay')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStackInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStackCard('Main', _mainStack, Colors.blue),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStackCard('Modal', _modalStack, Colors.green),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStackCard('Overlay', _overlayStack, Colors.orange),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStackCard(String name, DefaultNavigationStack stack, Color color) {
    return StreamBuilder<List<NavigationRoute>>(
      stream: stack.stackStream,
      initialData: stack.history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final isActive = _getActiveStack() == stack;
        
        return Card(
          color: isActive ? color.withOpacity(0.1) : null,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? color : null,
                  ),
                ),
                Text(
                  '${history.length} routes',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStackContent() {
    return StreamBuilder<List<NavigationRoute>>(
      stream: _getActiveStack().stackStream,
      initialData: _getActiveStack().history,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No routes in $_activeStackName stack'),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final route = history[index];
            final isCurrentRoute = index == history.length - 1;
            
            return Card(
              color: isCurrentRoute 
                  ? _getStackColor(_activeStackName).withOpacity(0.1) 
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStackColor(_activeStackName),
                  foregroundColor: Colors.white,
                  child: Text('${index + 1}'),
                ),
                title: Text(route.path),
                subtitle: Text('Stack: $_activeStackName'),
                trailing: isCurrentRoute 
                    ? Icon(
                        Icons.arrow_forward,
                        color: _getStackColor(_activeStackName),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildStackControls() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pushToStack(_activeStackName),
                  child: Text('Push to $_activeStackName'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _getActiveStack().canPop 
                      ? () => _getActiveStack().pop()
                      : null,
                  child: Text('Pop from $_activeStackName'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _clearStack(_activeStackName),
                  child: Text('Clear $_activeStackName'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showStackComparison,
                  child: Text('Compare Stacks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _switchStack(String stackName) {
    setState(() {
      _activeStackName = stackName;
    });
    
    _routeBuilder.setActiveStack(_getStackByName(stackName));
  }
  
  DefaultNavigationStack _getActiveStack() {
    return _getStackByName(_activeStackName);
  }
  
  DefaultNavigationStack _getStackByName(String name) {
    switch (name) {
      case 'main':
        return _mainStack;
      case 'modal':
        return _modalStack;
      case 'overlay':
        return _overlayStack;
      default:
        return _mainStack;
    }
  }
  
  Color _getStackColor(String stackName) {
    switch (stackName) {
      case 'main':
        return Colors.blue;
      case 'modal':
        return Colors.green;
      case 'overlay':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  void _pushToStack(String stackName) {
    final stack = _getStackByName(stackName);
    final routeCount = stack.history.length;
    
    stack.push(NavigationRoute(
      path: '/$stackName/route$routeCount',
      parameters: {
        'stackName': stackName,
        'routeIndex': routeCount,
        'timestamp': DateTime.now().toString(),
      },
    ));
  }
  
  void _clearStack(String stackName) {
    _getStackByName(stackName).clear();
  }
  
  void _showStackComparison() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stack Comparison'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStackSummary('Main', _mainStack),
              SizedBox(height: 16),
              _buildStackSummary('Modal', _modalStack),
              SizedBox(height: 16),
              _buildStackSummary('Overlay', _overlayStack),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStackSummary(String name, DefaultNavigationStack stack) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$name Stack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('Routes: ${stack.history.length}'),
        Text('Can pop: ${stack.canPop}'),
        if (stack.history.isNotEmpty)
          Text('Current: ${stack.history.last.path}'),
      ],
    );
  }
}

// Parameter class for stack routes
class StackParams {
  final String stackName;
  
  const StackParams({required this.stackName});
}

// Content screen for stack demonstration
class StackContentScreen extends StatelessWidget {
  final String title;
  final String stackName;
  final Color color;
  
  const StackContentScreen({
    required this.title,
    required this.stackName,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getStackIcon(stackName),
                size: 64,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Stack: $stackName',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getStackIcon(String stackName) {
    switch (stackName) {
      case 'main':
        return Icons.home;
      case 'modal':
        return Icons.layers;
      case 'overlay':
        return Icons.picture_in_picture;
      default:
        return Icons.help_outline;
    }
  }
}
```
## Testing Navigation

### Unit Testing Navigation Logic

Test navigation components and logic:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() {
  group('RouteBuilder Tests', () {
    late DefaultRouteBuilder routeBuilder;
    late DefaultNavigationStack navigationStack;
    
    setUp(() {
      routeBuilder = DefaultRouteBuilder();
      navigationStack = routeBuilder.createNavigationStack();
      routeBuilder.setActiveStack(navigationStack);
    });
    
    tearDown(() {
      routeBuilder.dispose();
    });
    
    test('should define and navigate to simple route', () async {
      // Define route
      routeBuilder.defineRoute<void>('/test', (params) {
        return TestScreen();
      });
      
      // Navigate to route
      await routeBuilder.navigate<void, void>('/test');
      
      // Verify navigation
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/test'));
    });
    
    test('should navigate with parameters', () async {
      // Define parameterized route
      routeBuilder.defineRoute<TestParams>('/test', (params) {
        return TestScreen(data: params.data);
      });
      
      // Navigate with parameters
      final testParams = TestParams(data: 'test data');
      await routeBuilder.navigate<TestParams, void>('/test', params: testParams);
      
      // Verify navigation and parameters
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/test'));
      expect(navigationStack.history.first.parameters['data'], equals('test data'));
    });
    
    test('should handle route guards', () async {
      var guardCalled = false;
      final guard = DefaultRouteGuard((route) async {
        guardCalled = true;
        return false; // Block navigation
      });
      
      // Define guarded route
      routeBuilder.defineRouteWithGuards<void>(
        '/protected',
        (params) => TestScreen(),
        guards: [guard],
      );
      
      // Attempt navigation
      expect(
        () => routeBuilder.navigate<void, void>('/protected'),
        throwsA(isA<StateError>()),
      );
      
      // Verify guard was called
      expect(guardCalled, isTrue);
      expect(navigationStack.history.length, equals(0));
    });
    
    test('should handle deep links', () async {
      // Define route
      routeBuilder.defineRoute<TestParams>('/test', (params) {
        return TestScreen(data: params.data);
      });
      
      // Register deep link handler
      routeBuilder.registerDeepLinkHandler('/test/:data', (params) async {
        final data = params['data'];
        if (data != null) {
          await routeBuilder.navigate<TestParams, void>(
            '/test',
            params: TestParams(data: data),
          );
          return true;
        }
        return false;
      });
      
      // Handle deep link
      final success = await routeBuilder.handleDeepLink('myapp://example.com/test/hello');
      
      // Verify deep link handling
      expect(success, isTrue);
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.parameters['data'], equals('hello'));
    });
  });
  
  group('NavigationStack Tests', () {
    late DefaultNavigationStack navigationStack;
    
    setUp(() {
      navigationStack = DefaultNavigationStack();
    });
    
    tearDown(() {
      navigationStack.dispose();
    });
    
    test('should push and pop routes', () {
      final route1 = NavigationRoute(path: '/route1');
      final route2 = NavigationRoute(path: '/route2');
      
      // Push routes
      navigationStack.push(route1);
      navigationStack.push(route2);
      
      expect(navigationStack.history.length, equals(2));
      expect(navigationStack.canPop, isTrue);
      
      // Pop route
      navigationStack.pop();
      
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/route1'));
    });
    
    test('should handle push replacement', () {
      final route1 = NavigationRoute(path: '/route1');
      final route2 = NavigationRoute(path: '/route2');
      
      navigationStack.push(route1);
      navigationStack.pushReplacement(route2);
      
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/route2'));
    });
    
    test('should handle push and remove until', () {
      final route1 = NavigationRoute(path: '/route1');
      final route2 = NavigationRoute(path: '/route2');
      final route3 = NavigationRoute(path: '/route3');
      final route4 = NavigationRoute(path: '/route4');
      
      navigationStack.push(route1);
      navigationStack.push(route2);
      navigationStack.push(route3);
      
      // Push and remove until route1
      navigationStack.pushAndRemoveUntil(
        route4,
        (route) => route.path == '/route1',
      );
      
      expect(navigationStack.history.length, equals(2));
      expect(navigationStack.history.first.path, equals('/route1'));
      expect(navigationStack.history.last.path, equals('/route4'));
    });
    
    test('should emit stack changes', () async {
      final stackChanges = <List<NavigationRoute>>[];
      final subscription = navigationStack.stackStream.listen(stackChanges.add);
      
      final route1 = NavigationRoute(path: '/route1');
      final route2 = NavigationRoute(path: '/route2');
      
      navigationStack.push(route1);
      navigationStack.push(route2);
      navigationStack.pop();
      
      await Future.delayed(Duration.zero); // Allow stream to emit
      
      expect(stackChanges.length, equals(3));
      expect(stackChanges[0].length, equals(1)); // After first push
      expect(stackChanges[1].length, equals(2)); // After second push
      expect(stackChanges[2].length, equals(1)); // After pop
      
      subscription.cancel();
    });
  });
  
  group('Route Guards Tests', () {
    test('AuthenticationGuard should allow authenticated users', () async {
      final guard = AuthenticationGuard(
        isAuthenticated: () => true,
        redirectRoute: '/login',
      );
      
      final route = RouteInformation(path: '/protected');
      final result = await guard.canActivate(route);
      
      expect(result, equals(true));
    });
    
    test('AuthenticationGuard should redirect unauthenticated users', () async {
      final guard = AuthenticationGuard(
        isAuthenticated: () => false,
        redirectRoute: '/login',
      );
      
      final route = RouteInformation(path: '/protected');
      final result = await guard.canActivate(route);
      
      expect(result, equals('/login'));
    });
    
    test('RoleGuard should allow users with correct role', () async {
      final guard = RoleGuard(
        requiredRoles: ['admin', 'moderator'],
        userRole: () => 'admin',
        redirectRoute: '/unauthorized',
      );
      
      final route = RouteInformation(path: '/admin');
      final result = await guard.canActivate(route);
      
      expect(result, equals(true));
    });
    
    test('RoleGuard should redirect users without correct role', () async {
      final guard = RoleGuard(
        requiredRoles: ['admin'],
        userRole: () => 'user',
        redirectRoute: '/unauthorized',
      );
      
      final route = RouteInformation(path: '/admin');
      final result = await guard.canActivate(route);
      
      expect(result, equals('/unauthorized'));
    });
  });
}

// Test helper classes
class TestScreen extends StatelessWidget {
  final String? data;
  
  const TestScreen({this.data});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(data ?? 'Test Screen'),
      ),
    );
  }
}

class TestParams {
  final String data;
  
  const TestParams({required this.data});
}
```

### Widget Testing Navigation

Test navigation in widget tests:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() {
  group('Navigation Widget Tests', () {
    testWidgets('should navigate when button is pressed', (tester) async {
      final routeBuilder = DefaultRouteBuilder();
      final navigationStack = routeBuilder.createNavigationStack();
      routeBuilder.setActiveStack(navigationStack);
      
      // Define routes
      routeBuilder.defineRoute<void>('/home', (params) {
        return HomeScreen(routeBuilder: routeBuilder);
      });
      
      routeBuilder.defineRoute<void>('/details', (params) {
        return DetailsScreen();
      });
      
      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(routeBuilder: routeBuilder),
        ),
      );
      
      // Verify initial state
      expect(find.text('Home Screen'), findsOneWidget);
      expect(navigationStack.history.length, equals(0));
      
      // Tap navigation button
      await tester.tap(find.text('Go to Details'));
      await tester.pump();
      
      // Verify navigation occurred
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/details'));
      
      routeBuilder.dispose();
    });
    
    testWidgets('should handle back navigation', (tester) async {
      final routeBuilder = DefaultRouteBuilder();
      final navigationStack = routeBuilder.createNavigationStack();
      routeBuilder.setActiveStack(navigationStack);
      
      // Pre-populate navigation stack
      navigationStack.push(NavigationRoute(path: '/home'));
      navigationStack.push(NavigationRoute(path: '/details'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationTestWidget(
            routeBuilder: routeBuilder,
            navigationStack: navigationStack,
          ),
        ),
      );
      
      // Verify initial state
      expect(navigationStack.history.length, equals(2));
      expect(navigationStack.canPop, isTrue);
      
      // Tap back button
      await tester.tap(find.text('Back'));
      await tester.pump();
      
      // Verify back navigation
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/home'));
      
      routeBuilder.dispose();
    });
    
    testWidgets('should display navigation history', (tester) async {
      final routeBuilder = DefaultRouteBuilder();
      final navigationStack = routeBuilder.createNavigationStack();
      routeBuilder.setActiveStack(navigationStack);
      
      // Add routes to stack
      navigationStack.push(NavigationRoute(path: '/home'));
      navigationStack.push(NavigationRoute(path: '/profile'));
      navigationStack.push(NavigationRoute(path: '/settings'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationHistoryWidget(navigationStack: navigationStack),
        ),
      );
      
      // Verify history display
      expect(find.text('/home'), findsOneWidget);
      expect(find.text('/profile'), findsOneWidget);
      expect(find.text('/settings'), findsOneWidget);
      expect(find.text('3 routes'), findsOneWidget);
      
      routeBuilder.dispose();
    });
    
    testWidgets('should handle route parameters', (tester) async {
      final routeBuilder = DefaultRouteBuilder();
      final navigationStack = routeBuilder.createNavigationStack();
      routeBuilder.setActiveStack(navigationStack);
      
      // Define parameterized route
      routeBuilder.defineRoute<UserParams>('/user', (params) {
        return UserScreen(userId: params.userId);
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: ParameterTestWidget(routeBuilder: routeBuilder),
        ),
      );
      
      // Enter user ID and navigate
      await tester.enterText(find.byType(TextField), 'user123');
      await tester.tap(find.text('Go to User'));
      await tester.pump();
      
      // Verify navigation with parameters
      expect(navigationStack.history.length, equals(1));
      expect(navigationStack.history.first.path, equals('/user'));
      expect(navigationStack.history.first.parameters['userId'], equals('user123'));
      
      routeBuilder.dispose();
    });
  });
}

// Test widget classes
class HomeScreen extends StatelessWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const HomeScreen({required this.routeBuilder});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Screen'),
            ElevatedButton(
              onPressed: () => routeBuilder.navigate<void, void>('/details'),
              child: Text('Go to Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Details Screen'),
      ),
    );
  }
}

class NavigationTestWidget extends StatelessWidget {
  final DefaultRouteBuilder routeBuilder;
  final DefaultNavigationStack navigationStack;
  
  const NavigationTestWidget({
    required this.routeBuilder,
    required this.navigationStack,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<List<NavigationRoute>>(
              stream: navigationStack.stackStream,
              initialData: navigationStack.history,
              builder: (context, snapshot) {
                final history = snapshot.data ?? [];
                return Text('Stack depth: ${history.length}');
              },
            ),
            ElevatedButton(
              onPressed: navigationStack.canPop 
                  ? () => navigationStack.pop()
                  : null,
              child: Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationHistoryWidget extends StatelessWidget {
  final DefaultNavigationStack navigationStack;
  
  const NavigationHistoryWidget({required this.navigationStack});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<NavigationRoute>>(
        stream: navigationStack.stackStream,
        initialData: navigationStack.history,
        builder: (context, snapshot) {
          final history = snapshot.data ?? [];
          
          return Column(
            children: [
              Text('${history.length} routes'),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(history[index].path),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ParameterTestWidget extends StatefulWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const ParameterTestWidget({required this.routeBuilder});
  
  @override
  _ParameterTestWidgetState createState() => _ParameterTestWidgetState();
}

class _ParameterTestWidgetState extends State<ParameterTestWidget> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'User ID'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.routeBuilder.navigate<UserParams, void>(
                  '/user',
                  params: UserParams(userId: _controller.text),
                );
              },
              child: Text('Go to User'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserScreen extends StatelessWidget {
  final String userId;
  
  const UserScreen({required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('User: $userId'),
      ),
    );
  }
}

class UserParams {
  final String userId;
  
  const UserParams({required this.userId});
}
```

### Integration Testing Navigation

Test complete navigation flows:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_productivity_toolkit/flutter_productivity_toolkit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Navigation Integration Tests', () {
    testWidgets('complete navigation flow', (tester) async {
      final app = NavigationTestApp();
      
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      
      // Start at home screen
      expect(find.text('Home Screen'), findsOneWidget);
      
      // Navigate to user list
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.text('User List'), findsOneWidget);
      
      // Navigate to user details
      await tester.tap(find.text('User 1'));
      await tester.pumpAndSettle();
      expect(find.text('User Details: User 1'), findsOneWidget);
      
      // Navigate to user settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('User Settings'), findsOneWidget);
      
      // Navigate back through history
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('User Details: User 1'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('User List'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });
    
    testWidgets('deep link navigation', (tester) async {
      final app = NavigationTestApp();
      
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      
      // Simulate deep link
      await tester.tap(find.text('Test Deep Link'));
      await tester.pumpAndSettle();
      
      // Verify deep link navigation
      expect(find.text('User Details: deeplink_user'), findsOneWidget);
    });
    
    testWidgets('protected route navigation', (tester) async {
      final app = NavigationTestApp();
      
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      
      // Try to access protected route without authentication
      await tester.tap(find.text('Admin Panel'));
      await tester.pumpAndSettle();
      
      // Should be redirected to login
      expect(find.text('Login Screen'), findsOneWidget);
      
      // Login
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'password');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Now should be able to access admin panel
      await tester.tap(find.text('Admin Panel'));
      await tester.pumpAndSettle();
      expect(find.text('Admin Panel'), findsOneWidget);
    });
  });
}

class NavigationTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationTestHome(),
    );
  }
}

class NavigationTestHome extends StatefulWidget {
  @override
  _NavigationTestHomeState createState() => _NavigationTestHomeState();
}

class _NavigationTestHomeState extends State<NavigationTestHome> {
  late DefaultRouteBuilder _routeBuilder;
  late AuthenticationService _authService;
  
  @override
  void initState() {
    super.initState();
    _setupNavigation();
  }
  
  void _setupNavigation() {
    _authService = AuthenticationService();
    _routeBuilder = DefaultRouteBuilder();
    
    // Define test routes
    _routeBuilder.defineRoute<void>('/home', (params) {
      return TestHomeScreen(routeBuilder: _routeBuilder);
    });
    
    _routeBuilder.defineRoute<void>('/users', (params) {
      return TestUserListScreen(routeBuilder: _routeBuilder);
    });
    
    _routeBuilder.defineRoute<UserParams>('/user', (params) {
      return TestUserDetailsScreen(
        userId: params.userId,
        routeBuilder: _routeBuilder,
      );
    });
    
    _routeBuilder.defineRoute<void>('/user/settings', (params) {
      return TestUserSettingsScreen();
    });
    
    _routeBuilder.defineRouteWithGuards<void>(
      '/admin',
      (params) => TestAdminScreen(),
      guards: [
        AuthenticationGuard(
          isAuthenticated: () => _authService.isAuthenticated,
          redirectRoute: '/login',
        ),
      ],
    );
    
    _routeBuilder.defineRoute<void>('/login', (params) {
      return TestLoginScreen(
        authService: _authService,
        onLogin: () => _routeBuilder.navigate<void, void>('/admin'),
      );
    });
    
    // Setup deep link
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
  }
  
  @override
  void dispose() {
    _routeBuilder.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TestHomeScreen(routeBuilder: _routeBuilder);
  }
}

// Test screen implementations
class TestHomeScreen extends StatelessWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const TestHomeScreen({required this.routeBuilder});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => routeBuilder.navigate<void, void>('/users'),
              child: Text('Users'),
            ),
            ElevatedButton(
              onPressed: () => routeBuilder.navigate<void, void>('/admin'),
              child: Text('Admin Panel'),
            ),
            ElevatedButton(
              onPressed: () => routeBuilder.handleDeepLink('myapp://example.com/user/deeplink_user'),
              child: Text('Test Deep Link'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestUserListScreen extends StatelessWidget {
  final DefaultRouteBuilder routeBuilder;
  
  const TestUserListScreen({required this.routeBuilder});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User List')),
      body: ListView(
        children: [
          ListTile(
            title: Text('User 1'),
            onTap: () => routeBuilder.navigate<UserParams, void>(
              '/user',
              params: UserParams(userId: 'User 1'),
            ),
          ),
          ListTile(
            title: Text('User 2'),
            onTap: () => routeBuilder.navigate<UserParams, void>(
              '/user',
              params: UserParams(userId: 'User 2'),
            ),
          ),
        ],
      ),
    );
  }
}

class TestUserDetailsScreen extends StatelessWidget {
  final String userId;
  final DefaultRouteBuilder routeBuilder;
  
  const TestUserDetailsScreen({
    required this.userId,
    required this.routeBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Details: $userId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User Details: $userId'),
            ElevatedButton(
              onPressed: () => routeBuilder.navigate<void, void>('/user/settings'),
              child: Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestUserSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Settings')),
      body: Center(child: Text('User Settings')),
    );
  }
}

class TestAdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Center(child: Text('Admin Panel')),
    );
  }
}

class TestLoginScreen extends StatefulWidget {
  final AuthenticationService authService;
  final VoidCallback onLogin;
  
  const TestLoginScreen({
    required this.authService,
    required this.onLogin,
  });
  
  @override
  _TestLoginScreenState createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Screen')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () {
                widget.authService.login(
                  _usernameController.text,
                  _passwordController.text,
                );
                widget.onLogin();
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Troubleshooting

### Common Navigation Issues

#### Navigation Not Working

**Problem**: Routes are not navigating or throwing errors.

**Solutions**:
1. Ensure routes are defined before navigation
2. Check that parameter types match between definition and navigation
3. Verify that the correct navigation stack is active

```dart
// ❌ Navigating to undefined route
await routeBuilder.navigate<void, void>('/undefined');

// ✅ Define route first
routeBuilder.defineRoute<void>('/defined', (params) => MyScreen());
await routeBuilder.navigate<void, void>('/defined');
```

#### Parameter Type Mismatches

**Problem**: Runtime errors due to parameter type mismatches.

**Solutions**:
1. Ensure parameter classes match between route definition and navigation
2. Use proper type generics in navigation calls
3. Validate parameters in parameter class constructors

```dart
// ❌ Type mismatch
class UserParams {
  final String userId;
  const UserParams({required this.userId});
}

await routeBuilder.navigate<UserParams, void>(
  '/user',
  params: UserParams(userId: 123), // Should be String, not int
);

// ✅ Correct types
await routeBuilder.navigate<UserParams, void>(
  '/user',
  params: UserParams(userId: '123'),
);
```

#### Route Guards Not Working

**Problem**: Route guards are not preventing navigation.

**Solutions**:
1. Ensure guards are properly registered with routes
2. Check that guard logic returns correct values (true, false, or redirect string)
3. Verify async operations in guards are properly awaited

```dart
// ❌ Guard not returning proper value
class BadGuard extends RouteGuard {
  @override
  Future<Object> canActivate(RouteInformation route) async {
    // Missing return statement
    if (someCondition) {
      // Should return true or false
    }
  }
}

// ✅ Proper guard implementation
class GoodGuard extends RouteGuard {
  @override
  Future<Object> canActivate(RouteInformation route) async {
    if (someCondition) {
      return true; // Allow navigation
    }
    return '/redirect-route'; // Redirect
  }
}
```

#### Deep Link Handling Issues

**Problem**: Deep links are not being processed correctly.

**Solutions**:
1. Verify deep link configuration matches the actual URL patterns
2. Check that deep link handlers are registered before handling
3. Ensure URL patterns match between configuration and handlers

```dart
// ❌ Pattern doesn't match actual URL
routeBuilder.registerDeepLinkHandler('/user/:id', handler);
// But trying to handle: myapp://example.com/users/123

// ✅ Correct pattern
routeBuilder.registerDeepLinkHandler('/users/:id', handler);
```

#### Memory Leaks

**Problem**: Navigation components not being disposed properly.

**Solutions**:
1. Always call `dispose()` on route builders and navigation stacks
2. Cancel stream subscriptions in widget dispose methods
3. Remove navigation stacks when no longer needed

```dart
// ✅ Proper disposal
class _MyWidgetState extends State<MyWidget> {
  late DefaultRouteBuilder _routeBuilder;
  late StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    _routeBuilder.dispose();
    super.dispose();
  }
}
```

#### Multi-Stack Confusion

**Problem**: Navigation happening on wrong stack.

**Solutions**:
1. Always set the correct active stack before navigation
2. Keep track of which stack should be active for each context
3. Use specific navigation methods available as when stack context is known

```dart
// ✅ Proper stack management
void navigateInMainStack() {
  routeBuilder.setActiveStack(mainStack);
  routeBuilder.navigate<void, void>('/main-route');
}

void navigateInModalStack() {
  routeBuilder.setActiveStack(modalStack);
  routeBuilder.navigate<void, void>('/modal-route');
}
```

### Best Practices Summary

1. **Define Routes Early**: Define all routes during app initialization
2. **Use Type Safety**: Always use typed parameters for navigation
3. **Handle Errors Gracefully**: Implement proper error handling for navigation failures
4. **Test Navigation Flows**: Write comprehensive tests for navigation logic
5. **Dispose Resources**: Always dispose of navigation components properly
6. **Use Guards Wisely**: Implement route guards for security and validation
7. **Document Deep Links**: Maintain clear documentation of deep link patterns
8. **Monitor Performance**: Keep track of navigation performance in complex apps
9. **Validate Parameters**: Implement validation in parameter classes
10. **Plan Stack Architecture**: Design navigation stack architecture before implementation

## Next Steps

Now that you understand the navigation system, explore these related topics:

- [State Management Guide](state_management.md) - Learn about reactive state management that integrates seamlessly with navigation
- [Testing Guide](testing.md) - Comprehensive testing strategies for navigation flows, including unit testing route logic and integration testing navigation flows
- [Performance Guide](performance.md) - Performance optimization techniques for navigation and monitoring navigation performance
- [API Reference](api_reference.md) - Complete API documentation for all navigation classes and methods

For more examples and advanced patterns, check out the [example applications](../example/) in the repository.
