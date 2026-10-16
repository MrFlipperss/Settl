/// Formats an amount with Indian digit grouping, e.g. 14280 -> "14,280".
String formatInr(num value) {
  final s = value.round().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}
