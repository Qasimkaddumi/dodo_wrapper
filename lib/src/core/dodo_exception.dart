/// Base type for every error thrown by this package.
abstract class DodoException implements Exception {
  /// Creates an exception with a human readable [message].
  const DodoException(this.message);

  /// Human readable description of the problem.
  final String message;

  @override
  // Not runtimeType: release web builds minify it.
  String toString() => 'DodoException: $message';
}

/// Thrown when the package is used before `Dodo.initialize` completed.
class DodoNotInitializedException extends DodoException {
  /// Creates the exception.
  const DodoNotInitializedException()
    : super('Dodo is not initialized. Call Dodo.initialize() first.');
}

/// Thrown when the configuration passed to the package is invalid.
class DodoConfigurationException extends DodoException {
  /// Creates the exception.
  const DodoConfigurationException(super.message);
}

/// Thrown when checkout options are invalid. Raised before anything is sent
/// to the checkout SDK.
class DodoValidationException extends DodoException {
  /// Creates the exception.
  const DodoValidationException(super.message);
}

/// Thrown when the current platform is not supported (anything but web).
class DodoUnsupportedPlatformException extends DodoException {
  /// Creates the exception.
  const DodoUnsupportedPlatformException()
    : super('The Dodo checkout SDK is only available on Flutter web.');
}

/// Thrown when the checkout SDK script could not be loaded.
class DodoScriptLoadException extends DodoException {
  /// Creates the exception.
  const DodoScriptLoadException(super.message);
}

/// Thrown when a call into the checkout SDK fails.
class DodoJsException extends DodoException {
  /// Creates the exception.
  const DodoJsException(super.message, {this.raw});

  /// The original error thrown by the checkout SDK.
  final Object? raw;
}
