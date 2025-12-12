/// Annotation for generating type-safe route definitions.
///
/// When applied to a method or class, this annotation triggers the generation
/// of corresponding route definitions with parameter validation and
/// deep link support.
class GenerateRoute {
  /// The route path pattern with parameter placeholders.
  ///
  /// Example: '/user/:id/profile'
  final String path;

  /// Whether this route requires authentication.
  final bool requiresAuth;

  /// HTTP methods this route should handle (for web).
  final List<String> methods;

  /// Whether to generate deep link handlers for this route.
  final bool enableDeepLinking;

  /// Custom transition animation for this route.
  final String? transition;

  /// Route guards that must pass before navigation.
  final List<String> guards;

  /// Creates a new GenerateRoute annotation.
  const GenerateRoute(
    this.path, {
    this.requiresAuth = false,
    this.methods = const ['GET'],
    this.enableDeepLinking = true,
    this.transition,
    this.guards = const [],
  });
}

/// Annotation for marking route parameters.
///
/// Used to specify parameter types and validation rules
/// for route parameters.
class RouteParam {
  /// The parameter name in the route path.
  final String name;

  /// Whether this parameter is required.
  final bool required;

  /// Default value if the parameter is not provided.
  final dynamic defaultValue;

  /// Validation pattern for the parameter value.
  final String? pattern;

  /// Creates a new RouteParam annotation.
  const RouteParam({
    required this.name,
    this.required = true,
    this.defaultValue,
    this.pattern,
  });
}

/// Annotation for marking route query parameters.
///
/// Used to specify query parameter handling for routes.
class QueryParam {
  /// The query parameter name.
  final String name;

  /// Whether this parameter is required.
  final bool required;

  /// Default value if the parameter is not provided.
  final dynamic defaultValue;

  /// Creates a new QueryParam annotation.
  const QueryParam({
    required this.name,
    this.required = false,
    this.defaultValue,
  });
}

/// Annotation for defining route guards.
///
/// Route guards are functions that determine whether
/// navigation to a route should be allowed.
class RouteGuard {
  /// The guard function name.
  final String guardFunction;

  /// Parameters to pass to the guard function.
  final Map<String, dynamic> parameters;

  /// Creates a new RouteGuard annotation.
  const RouteGuard({
    required this.guardFunction,
    this.parameters = const {},
  });
}
