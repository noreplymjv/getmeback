/// Local-only name cleanup: strips control chars / newline spam that break layouts.
String sanitizeTargetName(String raw, {int maxLength = 48}) {
  final cleaned = raw
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F\u200B-\u200F\u202A-\u202E]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.length <= maxLength) return cleaned;
  return cleaned.substring(0, maxLength).trimRight();
}
