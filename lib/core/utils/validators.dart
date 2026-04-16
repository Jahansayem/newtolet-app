/// Form field validators used by input forms across the NewTolet application.
class Validators {
  Validators._();

  // ---------------------------------------------------------------------------
  // Generic
  // ---------------------------------------------------------------------------

  /// Validates that a value is not null or empty.
  static String? requiredField(String? value,
      [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  /// Validates an email address.
  ///
  /// Returns `null` when valid, or an error message string.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    // Basic RFC-style regex covering most common patterns.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  /// Validates a password (6 to 20 characters).
  ///
  /// Returns `null` when valid, or an error message string.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 20) {
      return 'Password must not exceed 20 characters';
    }

    return null;
  }

  /// Validates that a confirmation password matches the original.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Name
  // ---------------------------------------------------------------------------

  /// Validates a display name (minimum 2 characters, maximum 50).
  ///
  /// Returns `null` when valid, or an error message string.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  /// Validates a Bangladeshi phone number.
  ///
  /// Accepts formats like `+8801XXXXXXXXX`, `01XXXXXXXXX`, or `8801XXXXXXXXX`.
  /// The local part must be 11 digits starting with `01`.
  ///
  /// Returns `null` when valid, or an error message string.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Strip all non-digit characters.
    String digits = value.replaceAll(RegExp(r'[^\d]'), '');

    // Normalise to local format (strip leading 880).
    if (digits.startsWith('880')) {
      digits = '0${digits.substring(3)}';
    }

    // Must start with 01 and be exactly 11 digits.
    if (!digits.startsWith('01')) {
      return 'Phone number must start with 01 or +880';
    }

    if (digits.length != 11) {
      return 'Phone number must be 11 digits';
    }

    // Valid Bangladeshi operator prefixes: 013, 014, 015, 016, 017, 018, 019.
    final operatorPrefix = digits.substring(0, 3);
    const validPrefixes = [
      '013',
      '014',
      '015',
      '016',
      '017',
      '018',
      '019',
    ];

    if (!validPrefixes.contains(operatorPrefix)) {
      return 'Enter a valid Bangladeshi phone number';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Referral code
  // ---------------------------------------------------------------------------

  /// Validates an optional referral code (at least 4 characters if provided).
  static String? referralCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Referral code is optional.
    }
    if (value.trim().length < 4) {
      return 'Referral code must be at least 4 characters';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Shorthand aliases
  // ---------------------------------------------------------------------------

  /// Alias for [validateEmail] -- usable directly as a FormField validator.
  static String? email(String? value) => validateEmail(value);

  /// Alias for [validatePassword] -- usable directly as a FormField validator.
  static String? password(String? value) => validatePassword(value);

  /// Alias for [validateName] -- usable directly as a FormField validator.
  static String? name(String? value) => validateName(value);

  /// Alias for [validatePhone] -- usable directly as a FormField validator.
  static String? phone(String? value) => validatePhone(value);
}
