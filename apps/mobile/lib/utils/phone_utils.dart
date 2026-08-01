import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Normalizes a raw phone input to E.164 format (e.g. `+919876543210`).
///
/// Returns `null` when the input cannot be parsed as a valid phone number
/// for [region]. Mirrors the E.164 mandate in `docs/flutter_app_context.md`:
/// every phone number must be normalized to E.164 before it is stored or
/// sent to the backend.
String? normalizePhone(String rawInput, {IsoCode region = IsoCode.IN}) {
  if (rawInput.trim().isEmpty) return null;
  try {
    final parsed = PhoneNumber.parse(rawInput, callerCountry: region);
    if (!parsed.isValid()) return null;
    return parsed.international;
  } catch (_) {
    return null;
  }
}
