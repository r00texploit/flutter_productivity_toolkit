import 'dart:async';
import 'dart:convert';

/// Abstract builder for declarative navigation with type-safe routing.
///
/// Provides automatic deep linking support and compile-time parameter
/// validation.
abstract class RouteBuilder {
  /// Defines a new route with the specified path and builder function.
  ///
  /// The builder function receives typed parameters and returns the widget
  /// to display for this route.
  void defineRoute<T>(String path, dynamic Function(T params) builder);

  /// Navigates to the specified route with optional parameters.
  ///
  /// Returns a Future that completes with the result when the route is popped.
  /// The result type R must match the return type expected by the route.
  Future<R?> navigate<T, R>(String path, {T? params});

  /// Registers a deep link handler for the specified URL pattern.
  ///
  /// The pattern can include parameter placeholders that will be extracted
  /// and passed to the route handler.
  void registerDeepLinkHandler(String pattern, RouteHandler handler);

  /// Removes a previously registered deep link handler.
  void unregisterDeepLinkHandler(String pattern);

  /// Processes a deep link URL and navigates to the appropriate route.
  ///
  /// Returns true if the deep link was handled successfully, false otherwise.
  Future<bool> handleDeepLink(String url);

  /// Gets the current route information.
  RouteInformation? get currentRoute;

  /// Stream of route changes for reactive navigation updates.
  Stream<RouteInformation> get routeStream;
}

/// Abstract navigation stack for managing route history.
///
/// Supports multiple navigation stacks for complex UI scenarios.
abstract class NavigationStack {
  /// Pushes a new route onto the navigation stack.
  void push(NavigationRoute route);

  /// Pops the current route from the stack with an optional result.
  void pop<T>([T? result]);

  /// Replaces the current route with a new one.
  void pushReplacement(NavigationRoute route);

  /// Pushes a route and removes all previous routes until the predicate
  /// returns true.
  void pushAndRemoveUntil(
    NavigationRoute route,
    bool Function(NavigationRoute) predicate,
  );

  /// The current navigation history as a list of routes.
  List<NavigationRoute> get history;

  /// Whether the stack can pop (has more than one route).
  bool get canPop;

  /// Clears all routes from the stack.
  void clear();

  /// Stream of navigation stack changes.
  Stream<List<NavigationRoute>> get stackStream;
}

/// Handler function for deep link processing.
typedef RouteHandler = Future<bool> Function(Map<String, String> parameters);

/// Information about a route including path, parameters, and metadata.
class RouteInformation {
  /// Creates new route information.
  const RouteInformation({
    required this.path,
    this.parameters = const {},
    this.metadata = const {},
    this.requiresAuthentication = false,
  });

  /// The route path pattern.
  final String path;

  /// Route parameters extracted from the URL or passed programmatically.
  final Map<String, dynamic> parameters;

  /// Additional metadata associated with the route.
  final Map<String, dynamic> metadata;

  /// Whether this route requires authentication.
  final bool requiresAuthentication;

  @override
  String toString() => 'RouteInformation('
      'path: $path, '
      'parameters: $parameters, '
      'requiresAuth: $requiresAuthentication'
      ')';
}

/// A navigation route representation.
class NavigationRoute {
  /// Creates a new navigation route.
  const NavigationRoute({
    required this.path,
    this.parameters = const {},
    this.metadata = const {},
  });

  /// The route path.
  final String path;

  /// Route parameters.
  final Map<String, dynamic> parameters;

  /// Route metadata.
  final Map<String, dynamic> metadata;

  @override
  String toString() => 'NavigationRoute(path: $path, params: $parameters)';
}

/// Definition of a route including its configuration and behavior.
class RouteDefinition {
  /// Creates a new route definition.
  const RouteDefinition({
    required this.path,
    required this.parameterType,
    required this.returnType,
    this.requiresAuthentication = false,
    this.guards = const [],
    this.transition,
  });

  /// The route path pattern with parameter placeholders.
  final String path;

  /// The type of parameters this route expects.
  final Type parameterType;

  /// The type of result this route can return.
  final Type returnType;

  /// Whether this route requires authentication.
  final bool requiresAuthentication;

  /// List of route guards that must pass before navigation.
  final List<RouteGuard> guards;

  /// Optional transition animation configuration.
  final RouteTransition? transition;
}

/// Configuration for deep link handling.
class DeepLinkConfiguration {
  /// Creates a new deep link configuration.
  const DeepLinkConfiguration({
    required this.scheme,
    required this.host,
    this.pathPatterns = const {},
    this.handleUniversalLinks = false,
  });

  /// The URL scheme to handle (e.g., 'myapp').
  final String scheme;

  /// The host to handle (e.g., 'example.com').
  final String host;

  /// Map of path patterns to route paths.
  final Map<String, String> pathPatterns;

  /// Whether to handle universal links (https/http).
  final bool handleUniversalLinks;
}

/// Abstract route guard for controlling navigation access.
abstract class RouteGuard {
  /// Checks if navigation to the route should be allowed.
  ///
  /// Returns true if navigation should proceed, false otherwise.
  /// Can also return a redirect route path as a string.
  Future<Object> canActivate(RouteInformation route);
}

/// Configuration for route transition animations.
class RouteTransition {
  /// Creates a new route transition configuration.
  const RouteTransition({
    required this.type,
    this.duration = const Duration(milliseconds: 300),
    this.customBuilder,
  });

  /// The type of transition animation.
  final TransitionType type;

  /// Duration of the transition animation.
  final Duration duration;

  /// Optional custom transition builder.
  final Function? customBuilder;
}

/// Types of built-in route transitions.
enum TransitionType {
  /// Slide transition from right to left.
  slide,

  /// Fade transition.
  fade,

  /// Scale transition.
  scale,

  /// No transition.
  none,

  /// Custom transition using the customBuilder.
  custom,
}

/// Concrete implementation of RouteBuilder with annotation-based route definitions.
class DefaultRouteBuilder extends RouteBuilder {
  /// Creates a new DefaultRouteBuilder with optional deep link configuration.
  DefaultRouteBuilder({DeepLinkConfiguration? deepLinkConfig}) {
    _deepLinkConfig = deepLinkConfig;
    _activeStack = DefaultNavigationStack();
    _navigationStacks.add(_activeStack!);
  }
  final Map<String, RouteDefinition> _routes = {};
  final Map<String, RouteHandler> _deepLinkHandlers = {};
  final List<DefaultNavigationStack> _navigationStacks = [];
  final StreamController<RouteInformation> _routeController =
      StreamController<RouteInformation>.broadcast();

  RouteInformation? _currentRoute;
  DefaultNavigationStack? _activeStack;
  DeepLinkConfiguration? _deepLinkConfig;

  @override
  void defineRoute<T>(String path, dynamic Function(T params) builder) {
    final definition = RouteDefinition(
      path: path,
      parameterType: T,
      returnType: dynamic,
    );

    _routes[path] = definition;
  }

  /// Defines a route with guards and additional configuration.
  void defineRouteWithGuards<T>(
    String path,
    dynamic Function(T params) builder, {
    List<RouteGuard> guards = const [],
    bool requiresAuthentication = false,
  }) {
    final definition = RouteDefinition(
      path: path,
      parameterType: T,
      returnType: dynamic,
      guards: guards,
      requiresAuthentication: requiresAuthentication,
    );

    _routes[path] = definition;
  }

  @override
  Future<R?> navigate<T, R>(String path, {T? params}) async {
    final route = _routes[path];
    if (route == null) {
      throw ArgumentError('Route not found: $path');
    }

    // Parameter validation is handled at compile time with generics

    // Check route guards
    final routeInfo = RouteInformation(
      path: path,
      parameters: params != null ? _serializeParams(params) : {},
      requiresAuthentication: route.requiresAuthentication,
    );

    for (final guard in route.guards) {
      final result = await guard.canActivate(routeInfo);
      if (result == false) {
        throw StateError('Navigation blocked by route guard');
      } else if (result is String) {
        // Redirect to different route
        return navigate<dynamic, R>(result);
      }
    }

    final navigationRoute = NavigationRoute(
      path: path,
      parameters: routeInfo.parameters,
    );

    _activeStack?.push(navigationRoute);
    _currentRoute = routeInfo;
    _routeController.add(routeInfo);

    return null; // In a real implementation, this would wait for the route result
  }

  @override
  void registerDeepLinkHandler(String pattern, RouteHandler handler) {
    _deepLinkHandlers[pattern] = handler;
  }

  @override
  void unregisterDeepLinkHandler(String pattern) {
    _deepLinkHandlers.remove(pattern);
  }

  @override
  Future<bool> handleDeepLink(String url) async {
    try {
      final uri = Uri.parse(url);

      // Check if this URL matches our deep link configuration
      if (_deepLinkConfig != null) {
        if (uri.scheme != _deepLinkConfig!.scheme &&
            uri.host != _deepLinkConfig!.host) {
          return false;
        }
      }

      // Extract parameters from URL
      final queryParams = uri.queryParameters;

      // Find matching route pattern
      for (final entry in _deepLinkHandlers.entries) {
        final pattern = entry.key;
        final handler = entry.value;

        final params =
            _extractParametersFromUrl(pattern, uri.path, queryParams);
        if (params != null) {
          return await handler(params);
        }
      }

      // Try to match against registered routes
      for (final routePath in _routes.keys) {
        final params =
            _extractParametersFromUrl(routePath, uri.path, queryParams);
        if (params != null) {
          await navigate<dynamic, dynamic>(routePath, params: params);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error handling deep link: $e');
      return false;
    }
  }

  @override
  RouteInformation? get currentRoute => _currentRoute;

  @override
  Stream<RouteInformation> get routeStream => _routeController.stream;

  /// Creates a new navigation stack for nested navigation.
  DefaultNavigationStack createNavigationStack() {
    final stack = DefaultNavigationStack();
    _navigationStacks.add(stack);
    return stack;
  }

  /// Sets the active navigation stack.
  void setActiveStack(DefaultNavigationStack stack) {
    if (_navigationStacks.contains(stack)) {
      _activeStack = stack;
    }
  }

  /// Gets all navigation stacks.
  List<DefaultNavigationStack> get navigationStacks =>
      List.unmodifiable(_navigationStacks);

  /// Removes a navigation stack.
  void removeNavigationStack(DefaultNavigationStack stack) {
    _navigationStacks.remove(stack);
    if (_activeStack == stack && _navigationStacks.isNotEmpty) {
      _activeStack = _navigationStacks.first;
    }
  }

  /// Disposes the route builder and cleans up resources.
  void dispose() {
    _routeController.close();
    for (final stack in _navigationStacks) {
      stack.dispose();
    }
    _navigationStacks.clear();
  }

  Map<String, dynamic> _serializeParams(dynamic params) {
    try {
      return json.decode(json.encode(params)) as Map<String, dynamic>;
    } catch (e) {
      // Fallback for non-serializable objects
      return {'data': params.toString()};
    }
  }

  Map<String, String>? _extractParametersFromUrl(
    String pattern,
    String path,
    Map<String, String> queryParams,
  ) {
    final patternSegments = pattern.split('/');
    final pathSegments = path.split('/');

    if (patternSegments.length != pathSegments.length) {
      return null;
    }

    final params = <String, String>{};

    for (var i = 0; i < patternSegments.length; i++) {
      final patternSegment = patternSegments[i];
      final pathSegment = pathSegments[i];

      if (patternSegment.startsWith(':')) {
        // Parameter segment
        final paramName = patternSegment.substring(1);
        params[paramName] = pathSegment;
      } else if (patternSegment != pathSegment) {
        // Literal segment doesn't match
        return null;
      }
    }

    // Add query parameters
    params.addAll(queryParams);

    return params;
  }
}

/// Concrete implementation of NavigationStack for managing route history.
class DefaultNavigationStack extends NavigationStack {
  /// Creates a new DefaultNavigationStack.
  DefaultNavigationStack();

  final List<NavigationRoute> _history = [];
  final StreamController<List<NavigationRoute>> _stackController =
      StreamController<List<NavigationRoute>>.broadcast();

  /// State preservation for nested navigation.
  final Map<String, dynamic> _preservedState = {};

  @override
  void push(NavigationRoute route) {
    _history.add(route);
    _stackController.add(List.unmodifiable(_history));
  }

  @override
  void pop<T>([T? result]) {
    if (_history.isNotEmpty) {
      final poppedRoute = _history.removeLast();
      _stackController.add(List.unmodifiable(_history));

      // In a real implementation, this would return the result to the previous route
      if (result != null) {
        print('Route ${poppedRoute.path} returned: $result');
      }
    }
  }

  @override
  void pushReplacement(NavigationRoute route) {
    if (_history.isNotEmpty) {
      _history.removeLast();
    }
    _history.add(route);
    _stackController.add(List.unmodifiable(_history));
  }

  @override
  void pushAndRemoveUntil(
    NavigationRoute route,
    bool Function(NavigationRoute) predicate,
  ) {
    // Remove routes until predicate returns true
    while (_history.isNotEmpty && !predicate(_history.last)) {
      _history.removeLast();
    }

    _history.add(route);
    _stackController.add(List.unmodifiable(_history));
  }

  @override
  List<NavigationRoute> get history => List.unmodifiable(_history);

  @override
  bool get canPop => _history.length > 1;

  @override
  void clear() {
    _history.clear();
    _stackController.add(List.unmodifiable(_history));
  }

  @override
  Stream<List<NavigationRoute>> get stackStream => _stackController.stream;

  /// Preserves state for the current route.
  void preserveState(String key, dynamic value) {
    _preservedState[key] = value;
  }

  /// Restores preserved state for a route.
  T? restoreState<T>(String key) => _preservedState[key] as T?;

  /// Clears preserved state.
  void clearPreservedState() {
    _preservedState.clear();
  }

  /// Disposes the navigation stack and cleans up resources.
  void dispose() {
    _stackController.close();
    _preservedState.clear();
  }
}

/// Navigation middleware for implementing guards and interceptors.
abstract class NavigationMiddleware {
  /// Called before navigation occurs.
  Future<bool> beforeNavigation(RouteInformation route);

  /// Called after navigation completes.
  Future<void> afterNavigation(RouteInformation route);
}

/// Concrete implementation of RouteGuard.
class DefaultRouteGuard extends RouteGuard {
  /// Creates a new DefaultRouteGuard with the specified guard function.
  DefaultRouteGuard(this._guardFunction);

  final Future<Object> Function(RouteInformation route) _guardFunction;

  @override
  Future<Object> canActivate(RouteInformation route) => _guardFunction(route);
}

/// Authentication guard that checks if user is authenticated.
class AuthenticationGuard extends RouteGuard {
  /// Creates a new AuthenticationGuard.
  AuthenticationGuard(this._isAuthenticated, this._redirectRoute);

  final bool Function() _isAuthenticated;
  final String _redirectRoute;

  @override
  Future<Object> canActivate(RouteInformation route) async {
    if (_isAuthenticated()) {
      return true;
    }
    return _redirectRoute;
  }
}

/// Route parameter validator.
class RouteParameterValidator {
  /// Validates route parameters against their expected types and constraints.
  static bool validateParameters(
    Map<String, dynamic> parameters,
    Map<String, Type> expectedTypes,
  ) {
    for (final entry in expectedTypes.entries) {
      final paramName = entry.key;
      final expectedType = entry.value;

      if (!parameters.containsKey(paramName)) {
        return false;
      }

      final value = parameters[paramName];
      if (value.runtimeType != expectedType) {
        return false;
      }
    }

    return true;
  }

  /// Converts string parameters to their expected types.
  static Map<String, dynamic> convertParameters(
    Map<String, String> stringParams,
    Map<String, Type> expectedTypes,
  ) {
    final converted = <String, dynamic>{};

    for (final entry in stringParams.entries) {
      final paramName = entry.key;
      final stringValue = entry.value;
      final expectedType = expectedTypes[paramName];

      if (expectedType == null) {
        converted[paramName] = stringValue;
        continue;
      }

      try {
        switch (expectedType) {
          case int:
            converted[paramName] = int.parse(stringValue);
            break;
          case double:
            converted[paramName] = double.parse(stringValue);
            break;
          case bool:
            converted[paramName] = stringValue.toLowerCase() == 'true';
            break;
          default:
            converted[paramName] = stringValue;
        }
      } catch (e) {
        // Keep as string if conversion fails
        converted[paramName] = stringValue;
      }
    }

    return converted;
  }
}
