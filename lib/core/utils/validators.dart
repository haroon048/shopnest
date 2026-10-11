// Form validation ke chhote functions.
// Har function: ghalat input par message do, theek ho to null do.
class Validators {
  Validators._();

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Enter your email address.';
    if (!v.contains('@') || !v.contains('.')) {
      return 'Enter a valid email address.';
    }
    return null; // null ka matlab: sab theek hai
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter your password.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.isEmpty) return 'Enter your name.';
    return null;
  }
}
