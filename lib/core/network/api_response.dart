/// Helpers for Gateway response shapes from API_REFERENCE.md.
///
/// Auth/Users/Stores often return a bare JSON array. Older mocks wrap lists as
/// `{ "items": [...] }` — both are accepted.
List<Map<String, dynamic>> parseObjectList(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (data is Map) {
    final items = data['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  return const [];
}

String? apiErrorCode(dynamic data) {
  if (data is Map && data['code'] is String) return data['code'] as String;
  return null;
}

String? apiErrorMessage(dynamic data) {
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return null;
}
