# Migrating from GoRouter

This guide helps you migrate from GoRouter to the Flutter Developer Productivity Toolkit's navigation system.

## Overview

The toolkit's navigation system provides similar functionality to GoRouter but with additional features like automatic route generation, enhanced type safety, and integrated deep linking with parameter validation.

## Key Differences

| Feature | GoRouter | Flutter Dev Toolkit |
|---------|----------|-------------------|
| Route Definition | Manual configuration | Annotation-based generation |
| Type Safety | Runtime parameter parsing | Compile-time type checking |
| Deep Linking | Manual URL parsing | Automatic parameter extraction |
| Navigation | String-based paths | Type-safe navigation methods |
| Nested Routes | Manual configuration | Automatic stack management |
| Route Guards | Manual implementation | Built-in guard system |

## Migration Steps

### Step 1: Replace Dependencies

**Before (GoRouter):**
```yaml
dependencies:
  go_router: ^10.0.0
```

**After (Toolkit):**
```yaml
dependencies:
  flutter_dev_toolkit: ^0.1.0
dev_dependencies:
  build_runner: ^2.4.7
```

### Step 2: Convert Route Definitions

**Before (GoRouter):**
```dart
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/user/:id',
      builder: (BuildContext context, GoRouterState state) {
        final userId = state.pathParameters['id']!;
        return UserScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/user/:id/profile',
      builder: (BuildContext context, GoRouterState state) {
        final userId = state.pathParameters['id']!;
        final tab = state.uri.queryParameters['tab'];
        return UserProfileScreen(userId: userId, initialTab: tab);
      },
    ),
  ],
);
```

**After (Toolkit):**
```dart
// Define route classes with annotations
@GenerateRoute('/')
class HomeRoute {
  const HomeRoute();
}

@GenerateRoute('/user/:id')
class UserRoute {
  final String userId;
  
  const UserRoute({required this.userId});
}

@GenerateRoute('/user/:id/profile')
class UserProfileRoute {
  final String userId;
  final String? initialTab;
  
  const UserProfileRoute({
    required this.userId,
    this.initialTab,
  });
}

// Route builders are generated automatically
// Run: flutter packages pub run build_runner build
```

### Step 3: Update App Configuration

**Before (GoRouter):**
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
```

**After (Toolkit):**
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      // Navigation is handled by the toolkit's RouteBuilder
      onGenerateRoute: (settings) {
        return RouteBuilder.instance.generateRoute(settings);
      },
    );
  }
}

// Initialize in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = ToolkitConfiguration.development();
  await config.initialize();
  
  // Register route builders
  RouteBuilder.instance.registerRoutes([
    HomeRouteBuilder(),
    UserRouteBuilder(),
    UserProfileRouteBuilder(),
  ]);
  
  runApp(MyApp());
}
```

### Step 4: Update Navigation Calls

**Before (GoRouter):**
```dart
// String-based navigation
context.go('/user/123');
context.push('/user/123/profile?tab=settings');

// With parameters
context.goNamed(
  'user-profile',
  pathParameters: {'id': '123'},
  queryParameters: {'tab': 'settings'},
);
```

**After (Toolkit):**
```dart
// Type-safe navigation
await context.navigate<UserRoute, void>(
  '/user/123',
  params: UserRoute(userId: '123'),
);

await context.navigate<UserProfileRoute, void>(
  '/user/123/profile',
  params: UserProfileRoute(
    userId: '123',
    initialTab: 'settings',
  ),
);

// Or using the route builder directly
final result = await RouteBuilder.instance.navigate<UserProfileRoute, String>(
  UserProfileRoute(userId: '123', initialTab: 'settings'),
);
```

### Step 5: Handle Route Parameters

**Before (GoRouter):**
```dart
class UserScreen extends StatelessWidget {
  final String userId;
  
  const UserScreen({required this.userId});
  
  @override
  Widget build(BuildContext context) {
    // Manual parameter extraction
    final state = GoRouterState.of(context);
    final tab = state.uri.queryParameters['tab'];
    
    return Scaffold(
      body: Text('User: $userId, Tab: $tab'),
    );
  }
}
```

**After (Toolkit):**
```dart
class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Parameters are automatically injected
    final route = RouteBuilder.instance.getCurrentRoute<UserRoute>();
    
    return Scaffold(
      body: Text('User: ${route.userId}'),
    );
  }
}

// Or use the generated route widget
class UserProfileScreen extends StatelessWidget {
  final UserProfileRoute route;
  
  const UserProfileScreen({required this.route});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('User: ${route.userId}'),
          if (route.initialTab != null)
            Text('Tab: ${route.initialTab}'),
        ],
      ),
    );
  }
}
```

## Advanced Migration Scenarios

### Nested Routes and Shell Routes

**Before (GoRouter):**
```dart
final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => DashboardScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(),
        ),
      ],
    ),
  ],
);
```

**After (Toolkit):**
```dart
@GenerateRoute('/dashboard', layout: MainLayoutRoute)
class DashboardRoute {
  const DashboardRoute();
}

@GenerateRoute('/settings', layout: MainLayoutRoute)
class SettingsRoute {
  const SettingsRoute();
}

// Layout route
@GenerateLayout()
class MainLayoutRoute {
  final Widget child;
  
  const MainLayoutRoute({required this.child});
}

// The toolkit automatically handles nested navigation
class MainLayout extends StatelessWidget {
  final Widget child;
  
  const MainLayout({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawer(),
      body: child,
    );
  }
}
```

### Route Guards and Redirects

**Before (GoRouter):**
```dart
final router = GoRouter(
  redirect: (context, state) {
    final isAuthenticated = AuthService.instance.isAuthenticated;
    final isAuthRoute = state.location.startsWith('/auth');
    
    if (!isAuthenticated && !isAuthRoute) {
      return '/auth/login';
    }
    
    if (isAuthenticated && isAuthRoute) {
      return '/dashboard';
    }
    
    return null;
  },
  routes: [
    // routes...
  ],
);
```

**After (Toolkit):**
```dart
@GenerateRoute('/dashboard', requiresAuth: true)
class DashboardRoute {
  const DashboardRoute();
}

@GenerateRoute('/auth/login')
class LoginRoute {
  const LoginRoute();
}

// Configure route guards
class AuthGuard extends RouteGuard {
  @override
  Future<bool> canActivate(RouteContext context) async {
    final isAuthenticated = await AuthService.instance.isAuthenticated();
    
    if (!isAuthenticated) {
      await context.navigate<LoginRoute, void>(
        '/auth/login',
        params: LoginRoute(),
      );
      return false;
    }
    
    return true;
  }
}

// Register guards in main.dart
RouteBuilder.instance.registerGuards([
  AuthGuard(),
]);
```

### Custom Transitions

**Before (GoRouter):**
```dart
GoRoute(
  path: '/user/:id',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: UserScreen(userId: state.pathParameters['id']!),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: Offset(1.0, 0.0), end: Offset.zero),
          ),
          child: child,
        );
      },
    );
  },
),
```

**After (Toolkit):**
```dart
@GenerateRoute('/user/:id', transition: SlideTransition)
class UserRoute {
  final String userId;
  
  const UserRoute({required this.userId});
}

// Custom transition configuration
class SlideTransition extends RouteTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: Offset(1.0, 0.0), end: Offset.zero),
      ),
      child: child,
    );
  }
}
```

## Deep Linking Migration

### Before (GoRouter)
```dart
// Manual URL parsing
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/share/:type/:id',
      builder: (context, state) {
        final type = state.pathParameters['type']!;
        final id = state.pathParameters['id']!;
        final token = state.uri.queryParameters['token'];
        
        return ShareScreen(
          type: type,
          id: id,
          token: token,
        );
      },
    ),
  ],
);
```

### After (Toolkit)
```dart
@GenerateRoute('/share/:type/:id')
class ShareRoute {
  final String type;
  final String id;
  final String? token;
  
  const ShareRoute({
    required this.type,
    required this.id,
    this.token,
  });
  
  // Validation is automatic
  bool get isValid => ['post', 'image', 'video'].contains(type);
}

// Deep link handling is automatic
// The toolkit validates parameters and handles errors
```

## Error Handling Migration

### Before (GoRouter)
```dart
final router = GoRouter(
  errorBuilder: (context, state) {
    return ErrorScreen(error: state.error);
  },
  routes: [
    // routes...
  ],
);
```

### After (Toolkit)
```dart
// Configure error handling
RouteBuilder.instance.configureErrorHandling(
  onRouteNotFound: (path) => NotFoundScreen(path: path),
  onParameterError: (error) => ParameterErrorScreen(error: error),
  onNavigationError: (error) => NavigationErrorScreen(error: error),
);

@GenerateRoute('/error/not-found')
class NotFoundRoute {
  final String path;
  
  const NotFoundRoute({required this.path});
}
```

## Testing Migration

### Before (GoRouter Testing)
```dart
testWidgets('navigation test', (tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(),
      ),
    ],
  );
  
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  
  // Test navigation
  router.go('/user/123');
  await tester.pumpAndSettle();
});
```

### After (Toolkit Testing)
```dart
testWidgets('navigation test', (tester) async {
  final testEnv = await TestHelper().setupTestEnvironment();
  
  await testEnv.helper.pumpAndSettle(
    tester,
    MyApp(),
  );
  
  // Type-safe navigation testing
  await testEnv.navigation.simulateNavigation<UserRoute>(
    UserRoute(userId: '123'),
  );
  
  await tester.pumpAndSettle();
  
  // Verify navigation
  expect(testEnv.navigation.currentRoute, isA<UserRoute>());
});
```

## Performance Considerations

### GoRouter Performance Issues
- String-based route matching
- Manual parameter parsing
- Runtime route resolution

### Toolkit Advantages
- Compile-time route generation
- Type-safe parameter handling
- Optimized route matching

## Migration Checklist

- [ ] Replace GoRouter dependency with Flutter Dev Toolkit
- [ ] Convert GoRoute definitions to @GenerateRoute classes
- [ ] Run code generation to create route builders
- [ ] Update MaterialApp.router to MaterialApp with onGenerateRoute
- [ ] Replace context.go() calls with type-safe navigation
- [ ] Convert route guards to RouteGuard classes
- [ ] Update deep link handling configuration
- [ ] Migrate custom transitions to RouteTransition classes
- [ ] Update error handling configuration
- [ ] Convert navigation tests to use TestHelper
- [ ] Test all navigation flows work as expected

## Benefits After Migration

1. **Type Safety**: Compile-time route validation prevents runtime errors
2. **Better IDE Support**: Auto-completion and refactoring for routes
3. **Automatic Parameter Validation**: Built-in parameter type checking
4. **Enhanced Deep Linking**: Automatic URL parsing and validation
5. **Improved Testing**: Type-safe navigation testing utilities
6. **Performance Monitoring**: Built-in navigation performance tracking

## Common Migration Pitfalls

### 1. Forgetting Code Generation
```bash
# Always run after adding @GenerateRoute annotations
flutter packages pub run build_runner build
```

### 2. Not Registering Route Builders
```dart
// Don't forget to register generated route builders
RouteBuilder.instance.registerRoutes([
  HomeRouteBuilder(),
  UserRouteBuilder(),
]);
```

### 3. Mixing Navigation Approaches
```dart
// Don't mix GoRouter and Toolkit navigation
// Choose one approach consistently
```

## Need Help?

If you encounter issues during migration:

1. Check the [Navigation Guide](../navigation.md)
2. Review [Troubleshooting Guide](../troubleshooting.md)
3. See navigation examples in [examples directory](../../example/)
4. Ask questions in [GitHub Discussions](https://github.com/flutter-dev-toolkit/flutter_dev_toolkit/discussions)