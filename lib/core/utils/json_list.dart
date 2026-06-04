import 'dart:convert';

String encodeIds(List<String> ids) => jsonEncode(ids);

List<String> decodeIds(String json) =>
    (jsonDecode(json) as List<dynamic>).cast<String>();

String encodeWeekdays(Set<int> days) =>
    jsonEncode(days.toList()..sort());

Set<int> decodeWeekdays(String json) =>
    (jsonDecode(json) as List<dynamic>).cast<int>().toSet();

String encodeComment(Map<String, String> comment) => jsonEncode(comment);

Map<String, String> decodeComment(String json) =>
    (jsonDecode(json) as Map<String, dynamic>).cast<String, String>();
