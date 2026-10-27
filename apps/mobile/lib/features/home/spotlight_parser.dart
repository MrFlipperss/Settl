/// Rule-based parser for the Home spotlight. The parser is kept independent
/// from persistence and UI so a model-backed categorizer can replace the
/// keyword implementation without changing the caller.
enum SpotlightActionType { expense, budget, request, subscription }

class SpotlightPerson {
  const SpotlightPerson({required this.id, required this.name});

  final String id;
  final String name;
}

class SpotlightGroup {
  const SpotlightGroup({
    required this.id,
    required this.name,
    required this.memberIds,
  });

  final String id;
  final String name;
  final List<String> memberIds;
}

abstract interface class ExpenseCategorizer {
  String categorize(String text);
}

/// Keyword categorization is deliberately isolated behind [ExpenseCategorizer]
/// so it can later be swapped for embeddings or a remote classifier.
class KeywordExpenseCategorizer implements ExpenseCategorizer {
  const KeywordExpenseCategorizer();

  static const Map<String, List<String>> keywords = {
    'Food': [
      'food',
      'dinner',
      'lunch',
      'breakfast',
      'brunch',
      'snack',
      'chai',
      'coffee',
      'cafe',
      'restaurant',
      'swiggy',
      'zomato',
      'pizza',
      'biryani',
      'groceries',
      'grocery',
      'dining',
    ],
    'Transport': [
      'uber',
      'ola',
      'cab',
      'taxi',
      'auto',
      'metro',
      'fuel',
      'petrol',
      'diesel',
      'flight',
      'train',
      'bus',
      'toll',
      'parking',
      'transport',
    ],
    'Entertainment': [
      'movie',
      'cinema',
      'pvr',
      'concert',
      'game',
      'netflix',
      'spotify',
      'show',
      'entertainment',
    ],
    'Shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'shopping',
      'clothes',
      'mall',
    ],
    'Rent': [
      'rent',
      'maintenance',
      'electricity',
      'water',
      'wifi',
      'housing',
    ],
    'Health': ['doctor', 'medicine', 'pharmacy', 'hospital', 'health'],
  };

  static const categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Rent',
    'Health',
    'Other',
  ];

  @override
  String categorize(String text) {
    final normalized = text.toLowerCase();
    for (final entry in keywords.entries) {
      if (entry.value.any((keyword) => _containsWord(normalized, keyword))) {
        return entry.key;
      }
    }
    return 'Other';
  }
}

bool _containsWord(String text, String word) =>
    RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text);

class SpotlightAction {
  const SpotlightAction({
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.personName,
    this.personId,
    this.participantIds = const [],
    this.groupId,
    this.groupName,
    this.subscriptionName,
    this.billingCycle,
    this.upiId = '',
  });

  final SpotlightActionType type;
  final double amount;
  final String category;
  final String description;
  final String? personName;
  final String? personId;
  final List<String> participantIds;
  final String? groupId;
  final String? groupName;
  final String? subscriptionName;
  final String? billingCycle;
  final String upiId;

  SpotlightAction copyWith({
    double? amount,
    String? category,
    String? description,
    String? personName,
    String? personId,
    List<String>? participantIds,
    String? groupId,
    String? groupName,
    String? subscriptionName,
    String? billingCycle,
    String? upiId,
  }) =>
      SpotlightAction(
        type: type,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        description: description ?? this.description,
        personName: personName ?? this.personName,
        personId: personId ?? this.personId,
        participantIds: participantIds ?? this.participantIds,
        groupId: groupId ?? this.groupId,
        groupName: groupName ?? this.groupName,
        subscriptionName: subscriptionName ?? this.subscriptionName,
        billingCycle: billingCycle ?? this.billingCycle,
        upiId: upiId ?? this.upiId,
      );
}

class SpotlightParser {
  const SpotlightParser({
    this.categorizer = const KeywordExpenseCategorizer(),
  });

  final ExpenseCategorizer categorizer;

  SpotlightAction? parse(
    String input, {
    required String currentParticipantId,
    Iterable<SpotlightPerson> people = const [],
    Iterable<SpotlightGroup> groups = const [],
    String currentUpiId = '',
  }) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final knownPeople = people.toList();
    final knownGroups = groups.toList();

    final budget = RegExp(
      r'^(?:set|update|change)\s+(.+?)\s+budget\s+(?:to\s+)?(?:₹|rs\.?|inr)?\s*([\d,]+(?:\.\d{1,2})?)\s*$',
      caseSensitive: false,
    ).firstMatch(text);
    if (budget != null) {
      final categoryText = budget.group(1)!.trim();
      return SpotlightAction(
        type: SpotlightActionType.budget,
        amount: _parseAmount(budget.group(2)!),
        category: categorizer.categorize(categoryText) == 'Other'
            ? _titleCase(categoryText)
            : categorizer.categorize(categoryText),
        description: '',
      );
    }

    final request = RegExp(
      r'^(?:please\s+)?(?:request|ask|collect)\s+(?:₹|rs\.?|inr)?\s*([\d,]+(?:\.\d{1,2})?)\s+from\s+(.+?)\s*$',
      caseSensitive: false,
    ).firstMatch(text);
    if (request != null) {
      final mention = request.group(2)!.trim();
      final matches = _matchPeople(mention, knownPeople);
      final person = matches.isEmpty ? null : matches.first;
      return SpotlightAction(
        type: SpotlightActionType.request,
        amount: _parseAmount(request.group(1)!),
        category: 'Other',
        description: '',
        personName: person?.name ?? mention,
        personId: person?.id,
        upiId: currentUpiId,
      );
    }

    final subscription = RegExp(
      r'^(?:add|create|new)\s+(?:subscription\s+(?:for\s+)?)?(.+?)\s+(?:₹|rs\.?|inr)?\s*([\d,]+(?:\.\d{1,2})?)\s*(monthly|month|yearly|annual|annually|year)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (subscription != null) {
      final cycle = subscription.group(3)!.toLowerCase();
      return SpotlightAction(
        type: SpotlightActionType.subscription,
        amount: _parseAmount(subscription.group(2)!),
        category: 'Other',
        description: '',
        subscriptionName: subscription.group(1)!.trim(),
        billingCycle: cycle.startsWith('year') || cycle.startsWith('annual')
            ? 'Yearly'
            : 'Monthly',
      );
    }

    final amountMatch = RegExp(
      r'(?:₹|rs\.?|inr)\s*([\d,]+(?:\.\d{1,2})?)|\b([\d,]+(?:\.\d{1,2})?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (amountMatch == null) return null;

    final amountText = amountMatch.group(1) ?? amountMatch.group(2)!;
    final groupMatch = _matchGroup(text, knownGroups);
    final matches = _matchPeople(text, knownPeople);

    // Extract person name from "with <name>" or "for <name>" if not pre-matched
    String? explicitPersonName;
    final withMatch = RegExp(
      r'\b(?:with|for)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (withMatch != null) {
      final candidate = withMatch.group(1)!.trim();
      // Only treat as person if it doesn't match the group name
      if (groupMatch == null ||
          !groupMatch.name.toLowerCase().contains(candidate.toLowerCase())) {
        explicitPersonName = candidate;
      }
    }

    final participantIds = <String>{
      if (currentParticipantId.isNotEmpty) currentParticipantId,
    };
    if (groupMatch != null) {
      participantIds.addAll(groupMatch.memberIds);
    }
    participantIds.addAll(matches.map((person) => person.id));

    final description = _expenseDescription(
      text,
      amountMatch.group(0)!,
      matches,
      groupMatch,
      explicitPersonName,
    );

    final resolvedPersonName = matches.isNotEmpty
        ? matches.map((p) => p.name).join(', ')
        : explicitPersonName;

    return SpotlightAction(
      type: SpotlightActionType.expense,
      amount: _parseAmount(amountText),
      category: categorizer.categorize(text),
      description: description.isEmpty ? 'Expense' : _titleCase(description),
      personName: resolvedPersonName,
      participantIds: participantIds.toList(),
      groupId: groupMatch?.id,
      groupName: groupMatch?.name,
    );
  }

  static double _parseAmount(String amount) =>
      double.parse(amount.replaceAll(',', ''));

  static List<SpotlightPerson> _matchPeople(
    String text,
    List<SpotlightPerson> people,
  ) {
    final normalized = text.toLowerCase();
    final hits = <({SpotlightPerson person, int index})>[];
    for (final person in people) {
      final fullName = person.name.trim().toLowerCase();
      if (fullName.isEmpty) continue;
      var index = _wordIndex(normalized, fullName);
      if (index < 0) {
        final firstName = fullName.split(RegExp(r'\s+')).first;
        if (firstName.length >= 3) index = _wordIndex(normalized, firstName);
      }
      if (index >= 0) hits.add((person: person, index: index));
    }
    hits.sort((a, b) => a.index.compareTo(b.index));
    final seen = <String>{};
    return hits
        .map((hit) => hit.person)
        .where((person) => seen.add(person.id))
        .toList();
  }

  static SpotlightGroup? _matchGroup(
    String text,
    List<SpotlightGroup> groups,
  ) {
    if (groups.isEmpty) return null;
    final sorted = groups.toList()
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    final normalized = text.toLowerCase();
    for (final group in sorted) {
      final name = group.name.trim().toLowerCase();
      if (name.isEmpty) continue;
      final pattern = RegExp(
        '(?:\\b(?:in|for|at|under)\\s+)?\\b${RegExp.escape(name)}\\b',
        caseSensitive: false,
      );
      if (pattern.hasMatch(normalized)) return group;
    }
    return null;
  }

  static String _expenseDescription(
    String text,
    String amountText,
    List<SpotlightPerson> people,
    SpotlightGroup? group,
    String? rawPersonName,
  ) {
    var description = text.replaceFirst(amountText, ' ');
    if (group != null) {
      description = description.replaceAll(
        RegExp(
          '(?:\\b(?:in|for|at|under)\\s+)?\\b${RegExp.escape(group.name)}\\b',
          caseSensitive: false,
        ),
        ' ',
      );
    }
    for (final person in people) {
      description = description.replaceAll(
        RegExp(RegExp.escape(person.name), caseSensitive: false),
        ' ',
      );
      final firstName = person.name.split(RegExp(r'\s+')).first;
      if (firstName.length >= 3) {
        description = description.replaceAll(
          RegExp('\\b${RegExp.escape(firstName)}\\b', caseSensitive: false),
          ' ',
        );
      }
    }
    if (rawPersonName != null && rawPersonName.isNotEmpty) {
      description = description.replaceAll(
        RegExp(RegExp.escape(rawPersonName), caseSensitive: false),
        ' ',
      );
    }
    // Remove "with <name>" remnants
    description = description.replaceAll(
      RegExp(r'\b(?:with|for)\s+[a-zA-Z]+', caseSensitive: false),
      ' ',
    );
    return description
        .replaceAll(
            RegExp(r'\b(with|and|paid|spent|in|on|at|under|by|for)\b',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'[^A-Za-z0-9\u0080-\uFFFF ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _wordIndex(String text, String word) {
    final match = RegExp('\\b${RegExp.escape(word)}\\b').firstMatch(text);
    return match?.start ?? -1;
  }

  static String _titleCase(String text) {
    final value = text.trim();
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
