String normalizeArabic(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAllMapped(RegExp(r'[\u0660-\u0669\u06F0-\u06F9]'), (match) {
        final digit = match.group(0)!.codeUnitAt(0);
        final zero = digit >= 0x06F0 ? 0x06F0 : 0x0660;
        return String.fromCharCode(0x30 + digit - zero);
      })
      .replaceAll(RegExp(r'\s+'), ' ');
}

String compactArabic(String value) =>
    normalizeArabic(value).replaceAll(' ', '');

bool containsPlateQuery({
  required String query,
  required String carNumber,
  required String letters,
  required String companyName,
}) {
  final normalizedQuery = normalizeArabic(query);
  if (normalizedQuery.isEmpty) return true;
  final compactQuery = compactArabic(query);
  return normalizeArabic(carNumber).contains(normalizedQuery) ||
      normalizeArabic(letters).contains(normalizedQuery) ||
      compactArabic(letters).contains(compactQuery) ||
      normalizeArabic(companyName).contains(normalizedQuery);
}
