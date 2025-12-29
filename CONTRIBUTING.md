# Contributing to Flutter Productivity Toolkit

Thank you for your interest in contributing to the Flutter Productivity Toolkit! We welcome contributions from the community and are grateful for your help in making this package better.

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Git

### Setting Up the Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/r00texploit/flutter_productivity_toolkit.git
   cd flutter_productivity_toolkit
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run tests to ensure everything is working:
   ```bash
   flutter test
   ```

## Development Workflow

### Code Style

We follow the official Dart style guide and use `flutter_lints` for code analysis.

- Run `flutter analyze` to check for linting issues
- Use `dart format .` to format your code
- Follow the existing code patterns and naming conventions

### Testing

- Write tests for all new functionality
- Ensure all existing tests pass before submitting
- Aim for high test coverage
- Use property-based testing for complex logic

### Code Generation

This package uses code generation. After making changes to annotated classes:

```bash
flutter packages pub run build_runner build
```

## Submitting Changes

### Pull Request Process

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them with clear, descriptive messages
3. Push your branch to your fork
4. Create a pull request against the main repository

### Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Include tests for new functionality
- Update documentation as needed
- Ensure all CI checks pass

## Types of Contributions

### Bug Reports

When reporting bugs, please include:
- Flutter and Dart versions
- Steps to reproduce the issue
- Expected vs actual behavior
- Minimal code example if possible

### Feature Requests

For new features:
- Describe the use case and problem it solves
- Provide examples of how it would be used
- Consider backward compatibility

### Documentation

Documentation improvements are always welcome:
- Fix typos or unclear explanations
- Add examples or use cases
- Improve API documentation

## Code of Conduct

Please be respectful and constructive in all interactions. We want to maintain a welcoming environment for all contributors.

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Start a discussion in the GitHub Discussions tab
- Reach out to the maintainers

Thank you for contributing!