class AppValidators {
  /// Ensures a string field is not empty.
  static String? requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Ensures email is valid and matches basic standard format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Ensures phone is a valid 10-digit Indian phone number.
  static String? phoneIndia(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a valid 10-digit mobile number.';
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number.';
    }
    return null;
  }

  /// Ensures password is at least 6 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Ensures confirm password matches password.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Ensures a required numeric field is valid and >= 0.
  static String? numberRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final cleaned = value.trim();
    final number = num.tryParse(cleaned);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number < 0) {
      return '$fieldName must be 0 or greater';
    }
    return null;
  }

  /// Ensures a string meets a minimum character length.
  static String? minLength(String? value, String fieldName, int min) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }
}
