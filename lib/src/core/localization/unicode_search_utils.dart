/// Utility for Unicode-safe multilingual search and matching across Indian scripts.
/// Preserves original stored strings while applying safe comparison heuristics.
class UnicodeSearchUtils {
  UnicodeSearchUtils._();

  /// Normalize a string for search matching:
  /// - Trims leading and trailing whitespace
  /// - Collapses multiple spaces
  /// - Lowercases characters (where case applies, e.g. English/Latin)
  static String normalizeForSearch(String input) {
    if (input.isEmpty) return '';
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Determines if `target` matches `query` across Indian scripts or Latin.
  /// Does not strip matras or vowels from Indic scripts.
  static bool matches(String? target, String query) {
    if (target == null || target.isEmpty) return false;
    if (query.trim().isEmpty) return true;

    final normalizedTarget = normalizeForSearch(target);
    final normalizedQuery = normalizeForSearch(query);

    return normalizedTarget.contains(normalizedQuery);
  }

  /// Prefix matching for autocomplete
  static bool startsWithPrefix(String? target, String prefix) {
    if (target == null || target.isEmpty) return false;
    if (prefix.trim().isEmpty) return true;

    final normalizedTarget = normalizeForSearch(target);
    final normalizedPrefix = normalizeForSearch(prefix);

    return normalizedTarget.startsWith(normalizedPrefix);
  }

  /// Multi-field search helper across name, phone, village/address, and notes
  static bool matchesAny(List<String?> fields, String query) {
    if (query.trim().isEmpty) return true;
    for (final field in fields) {
      if (matches(field, query)) return true;
    }
    return false;
  }
}
