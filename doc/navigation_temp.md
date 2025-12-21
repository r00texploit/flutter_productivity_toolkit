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
    if (someCondition) {
      // Missing return statement
    }
    return false; // Should return true or redirect
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

#### Deep Link Handling

**Problem**: Deep links are not being processed correctly.

**Solutions**:
1. Ensure deep link handlers are registered before URL matching
2. Check that URL patterns match the actual URLs
3. Verify deep link configuration is correct

```dart
// ❌ Pattern doesn't match URL
routeBuilder.registerDeepLinkHandler('/user/:id', handler);
// But trying to handle: myapp://example.com/users/123

// ✅ Correct pattern
routeBuilder.registerDeepLinkHandler('/users/:id', handler);
```

#### Memory Leaks

**Problem**: Navigation components are not being disposed properly.

**Solutions**:
1. Always call `dispose()` methods in widget dispose
2. Cancel stream subscriptions when no longer needed
3. Remove navigation stacks when disposing route builders

```dart
// ✅ Proper disposal
@override
void dispose() {
  _subscription.cancel();
  _routeBuilder.dispose();
  super.dispose();
}
```

## Best Practices Summary

1. **Define Routes Early**: Define all routes during app initialization
2. **Use Type Safety**: Always use typed parameters for navigation
3. **Handle Errors Gracefully**: Implement proper error handling for navigation failures
4. **Test Navigation Flows**: Write comprehensive tests for navigation
5. **Dispose Resources**: Always dispose of navigation components properly
6. **Use Guards Wisely**: Implement route guards for security and validation
7. **Document Deep Links**: Maintain clear documentation of deep link patterns
8. **Monitor Performance**: Keep track of navigation performance in complex apps
9. **Validate Parameters**: Implement validation in parameter classes
10. **Plan Stack Architecture**: Design navigation stack architecture before implementation

## Next Steps

Now that you understand the navigation system, explore these related topics:

- [State Management Guide](state_management.md) - Learn about reactive state management that integrates seamlessly with navigation
- [Testing Guide](testing.md) - Comprehensive testing strategies for navigation flows, including route testing and navigation mocking
- [Performance Guide](performance.md) - Navigation performance optimization and monitoring techniques
- [API Reference](api_reference.md) - Complete navigation API documentation with detailed examples

For more examples and advanced patterns, check out the [example applications](../example/) in the repository.