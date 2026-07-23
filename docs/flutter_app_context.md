# Flutter App Integration Guidelines (Settl Mobile)

This document details the critical client-side requirements for Flutter application developers integrating with the Settl Backend API.

---

## 1. Phone Number Normalization
- **Requirement:** Phone numbers MUST be normalized to standard **E.164 format** (e.g. `+919876543210`) before sending to the backend or storing locally.
- **Flutter Implementation:** Use a package like `dcli` or `libphonenumber_plugin` / `phone_number` to parse, validate, and format user input:
  ```dart
  import 'package:phone_number/phone_number.dart';
  
  Future<String?> normalizePhone(String rawInput, String regionCode) async {
    final phoneNumberUtil = PhoneNumberUtil();
    bool isValid = await phoneNumberUtil.validate(rawInput, regionCode);
    if (!isValid) return null;
    final parsed = await phoneNumberUtil.parse(rawInput, regionCode);
    return parsed.e164; // returns "+91..."
  }
  ```

---

## 2. Decimal Input & Currency Handling
- **Requirement:** Floating point values must **never** be used directly for financial arithmetic in JSON requests to prevent IEEE 754 precision loss.
- **Rule:** Amounts must be represented either as exact integers in minor units (paise/cents, e.g. `1050` for ₹10.50) or validated on input to allow at most **2 decimal places**.
- **Flutter Implementation:** 
  - Restrict input text fields using `FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))`.
  - Parse inputs using `Decimal` (`decimal` package) or convert strictly to integer paise (`(doubleVal * 100).round()`) prior to sending to the API.

---

## 3. Idempotency Key & Duplicate Submission Prevention
- **Requirement:** To avoid duplicate expense creation when a user taps "Save" multiple times or experiences network timeout retries, every expense creation request MUST include a unique idempotency key.
- **Header / Payload:** Include `Idempotency-Key: <UUIDv4>` header or `idempotency_key` field in POST `/expenses`.
- **Flutter Implementation:**
  ```dart
  import 'package:uuid/uuid.dart';

  final idempotencyKey = const Uuid().v4();
  final response = await http.post(
    Uri.parse('$baseUrl/expenses'),
    headers: {
      'Authorization': 'Bearer $jwtToken',
      'Idempotency-Key': idempotencyKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode(expensePayload),
  );
  ```

---

## 4. Offline Conflict Resolution Strategies
- **Requirement:** When users edit expenses offline and reconnect, concurrent edits might conflict with updates made by other group members.
- **Strategy - Optimistic Concurrency Control (OCC):**
  1. Every expense returned by the API includes a `version` or `updated_at` timestamp.
  2. When submitting an edit (`PUT /expenses/{id}`), include `version` or `updated_at`.
  3. **409 Conflict Response:** If the server returns `HTTP 409 Conflict`, the client must show a diff modal asking the user to choose:
     - **Keep Local Edits:** Overwrite server version.
     - **Keep Server Version:** Discard local edits and sync latest state.
     - **Merge:** Manually review modified splits or description fields.
