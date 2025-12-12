import 'dart:async';

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
  /// The route path pattern.
  final String path;

  /// Route parameters extracted from the URL or passed programmatically.
  final Map<String, dynamic> parameters;

  /// Additional metadata associated with the route.
  final Map<String, dynamic> metadata;

  /// Whether this route requires authentication.
  final bool requiresAuthentication;

  /// Creates new route information.
  const RouteInformation({
    required this.path,
    this.parameters = const {},
    this.metadata = const {},
    this.requiresAuthentication = false,
  });

  @override
  String toString() => 'RouteInformation('
      'path: $path, '
      'parameters: $parameters, '
      'requiresAuth: $requiresAuthentication'
      ')';
}

/// A navigation route representation.
class NavigationRoute {
  /// The route path.
  final String path;

  /// Route parameters.
  final Map<String, dynamic> parameters;

  /// Route metadata.
  final Map<String, dynamic> metadata;

  /// Creates a new navigation route.
  const NavigationRoute({
    required this.path,
    this.parameters = const {},
    this.metadata = const {},
  });

  @override
  String toString() => 'NavigationRoute(path: $path, params: $parameters)';
}

/// Definition of a route including its configuration and behavior.
class RouteDefinition {
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

  /// Creates a new route definition.
  const RouteDefinition({
    required this.path,
    required this.parameterType,
    required this.returnType,
    this.requiresAuthentication = false,
    this.guards = const [],
    this.transition,
  });
}

/// Configuration for deep link handling.
class DeepLinkConfiguration {
  /// The URL scheme to handle (e.g., 'myapp').
  final String scheme;

  /// The host to handle (e.g., 'example.com').
  final String host;

  /// Map of path patterns to route paths.
  final Map<String, String> pathPatterns;

  /// Whether to handle universal links (https/http).
  final bool handleUniversalLinks;

  /// Creates a new deep link configuration.
  const DeepLinkConfiguration({
    required this.scheme,
    required this.host,
    this.pathPatterns = const {},
    this.handleUniversalLinks = false,
  });
}

/// Abstract route guard for controlling navigation access.
abstract class RouteGuard {
  /// Checks if navigation to the route should be allowed.
  ///
  /// Returns true if navigation should proceed, false otherwise.
  /// Can also return a redirect route path as a string.
  Future<dynamic> canActivate(RouteInformation route);
}

/// Configuration for route transition animations.
class RouteTransition {
  /// The type of transition animation.
  final TransitionType type;

  /// Duration of the transition animation.
  final Duration duration;

  /// Optional custom transition builder.
  final dynamic Function(
    dynamic context,
    dynamic animation,
    dynamic secondaryAnimation,
    dynamic child,
  )? customBuilder;

  /// Creates a new route transition configuration.
  const RouteTransition({
    required this.type,
    this.duration = const Duration(milliseconds: 300),
    this.customBuilder,
  });
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
