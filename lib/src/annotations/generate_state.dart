/// Annotation for generating state management code.
///
/// When applied to a class, this annotation triggers the generation
/// of a corresponding state manager with reactive updates and
/// optional persistence capabilities.
class GenerateState {
  /// Whether to enable automatic persistence for this state.
  final bool persist;

  /// Storage key for persisted state. If null, uses the class name.
  final String? storageKey;

  /// Whether to enable debugging features like state transition logging.
  final bool enableDebugging;

  /// Whether to automatically dispose of the state manager.
  final bool autoDispose;

  /// Initial state factory function name.
  final String? initialStateFactory;

  /// Creates a new GenerateState annotation.
  const GenerateState({
    this.persist = false,
    this.storageKey,
    this.enableDebugging = false,
    this.autoDispose = true,
    this.initialStateFactory,
  });
}

/// Annotation for marking state properties that should be reactive.
///
/// Properties marked with this annotation will automatically trigger
/// widget rebuilds when their values change.
class ReactiveProperty {
  /// Whether changes to this property should be logged.
  final bool logChanges;

  /// Custom equality function for change detection.
  final String? equalityFunction;

  /// Creates a new ReactiveProperty annotation.
  const ReactiveProperty({
    this.logChanges = false,
    this.equalityFunction,
  });
}

/// Annotation for marking state methods that should trigger updates.
///
/// Methods marked with this annotation will automatically notify
/// listeners when called.
class StateAction {
  /// Name of the action for debugging purposes.
  final String? actionName;

  /// Whether this action should be logged.
  final bool logAction;

  /// Creates a new StateAction annotation.
  const StateAction({
    this.actionName,
    this.logAction = false,
  });
}
