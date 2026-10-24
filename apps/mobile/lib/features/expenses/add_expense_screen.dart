import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/profile.dart';
import '../../providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _splitInputControllers = <String, TextEditingController>{};
  late Future<_PeopleData> _peopleFuture;
  final _selectedIds = <String>{};
  String _splitType = 'equal';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _peopleFuture = _loadPeople();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (final controller in _splitInputControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_PeopleData> _loadPeople() async {
    final session = ref.read(authStateProvider).value ??
        await ref.read(authStateProvider.future);
    if (session == null) throw StateError('Sign in to add an expense.');
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfileByUserId(session.userId);
    if (profile == null || profile.participantId.trim().isEmpty) {
      throw StateError('Your profile is not ready.');
    }
    final contacts = await ref
        .read(contactRepositoryProvider)
        .getContactsByUser(profile.participantId);
    final people = [
      _Person(id: profile.participantId, name: profile.displayName),
      for (final contact in contacts)
        if (contact.participantId != profile.participantId)
          _Person(id: contact.participantId, name: contact.displayName),
    ];
    _selectedIds.add(profile.participantId);
    return _PeopleData(profile: profile, people: people);
  }

  Future<void> _submit(_PeopleData data) async {
    final description = _descriptionController.text.trim();
    final amountPaise = _parsePaise(_amountController.text);
    if (description.isEmpty) {
      _showMessage('Enter a description.');
      return;
    }
    if (amountPaise == null || amountPaise <= 0) {
      _showMessage('Enter a positive amount with up to two decimals.');
      return;
    }
    if (_selectedIds.isEmpty) {
      _showMessage('Select at least one person.');
      return;
    }
    final splitValues = _readSplitValues();
    if (splitValues == null) return;
    try {
      _calculateShares(amountPaise, splitValues);
    } on ArgumentError catch (error) {
      _showMessage(error.message?.toString() ?? 'Check the split values.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(expenseRepositoryProvider).createPeopleExpense(
            description: description,
            amountPaise: amountPaise,
            payerId: data.profile.participantId,
            participantIds: _selectedIds.toList(),
            splitType: _splitType,
            splitValues: splitValues,
          );
      final sync = ref.read(syncServiceProvider);
      unawaited(sync.requestSync());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Expense saved locally and queued to sync.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Could not save expense: ${_friendlyError(error)}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static int? _parsePaise(String value) {
    final text = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final rupees = int.tryParse(parts.first);
    if (rupees == null) return null;
    final decimals = parts.length == 1 ? '' : parts[1].padRight(2, '0');
    return rupees * 100 + int.parse(decimals.isEmpty ? '0' : decimals);
  }

  static String _friendlyError(Object error) => error is StateError
      ? error.message
      : error is ArgumentError
          ? error.message?.toString() ?? 'invalid expense'
          : 'Please try again.';

  TextEditingController _splitController(String participantId) =>
      _splitInputControllers.putIfAbsent(
        participantId,
        () => TextEditingController(),
      );

  void _changeSplitType(String splitType, _PeopleData data) {
    final ids = data.people
        .where((person) => _selectedIds.contains(person.id))
        .map((person) => person.id)
        .toList();
    final amount = _parsePaise(_amountController.text) ?? 0;
    final base = ids.isEmpty ? 0 : amount ~/ ids.length;
    final remainder = ids.isEmpty ? 0 : amount % ids.length;
    final percentageBase = ids.isEmpty ? 0 : 10000 ~/ ids.length;
    final percentageRemainder = ids.isEmpty ? 0 : 10000 % ids.length;
    setState(() {
      _splitType = splitType;
      for (var i = 0; i < ids.length; i++) {
        final controller = _splitController(ids[i]);
        controller.text = switch (splitType) {
          'exact' => _formatPaise(base + (i < remainder ? 1 : 0)),
          'percentage' => _formatPercentage(
              percentageBase + (i < percentageRemainder ? 1 : 0)),
          'shares' => '1',
          _ => '',
        };
      }
    });
  }

  Map<String, num>? _readSplitValues({bool showErrors = true}) {
    if (_splitType == 'equal') return const {};
    final values = <String, num>{};
    for (final id in _selectedIds) {
      final raw = _splitController(id).text.trim();
      if (_splitType == 'shares') {
        final count = int.tryParse(raw);
        if (count == null || count <= 0) {
          if (showErrors) {
            _showMessage('Enter a positive whole share count for everyone.');
          }
          return null;
        }
        values[id] = count;
      } else {
        final number = double.tryParse(raw.replaceAll(',', '.'));
        if (number == null || number < 0 || !number.isFinite) {
          if (showErrors) {
            _showMessage('Enter a valid split value for everyone.');
          }
          return null;
        }
        if (_splitType == 'exact' && _parsePaise(raw) == null) {
          if (showErrors) {
            _showMessage('Amounts must have at most two decimal places.');
          }
          return null;
        }
        if (_splitType == 'percentage' &&
            !RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(raw)) {
          if (showErrors) {
            _showMessage('Percentages can have at most two decimal places.');
          }
          return null;
        }
        values[id] = number;
      }
    }
    return values;
  }

  List<int> _calculateShares(int totalPaise, Map<String, num> values) {
    final ids = _peopleInSelection();
    if (_splitType == 'equal') {
      final base = totalPaise ~/ ids.length;
      final remainder = totalPaise % ids.length;
      return [
        for (var i = 0; i < ids.length; i++) base + (i < remainder ? 1 : 0),
      ];
    }
    if (_splitType == 'exact') {
      final shares = [
        for (final id in ids) _parsePaise(values[id]!.toString())!
      ];
      if (shares.fold<int>(0, (sum, value) => sum + value) != totalPaise) {
        throw ArgumentError('Split amounts must add up to the expense total.');
      }
      return shares;
    }
    if (_splitType == 'percentage') {
      final percentages = [
        for (final id in ids) (values[id]! * 100).round(),
      ];
      if (percentages.fold<int>(0, (sum, value) => sum + value) != 10000) {
        throw ArgumentError('Percentages must add up to exactly 100%.');
      }
      var allocated = 0;
      return [
        for (var i = 0; i < percentages.length; i++)
          if (i == percentages.length - 1)
            totalPaise - allocated
          else
            (() {
              final share = totalPaise * percentages[i] ~/ 10000;
              allocated += share;
              return share;
            })(),
      ];
    }
    final counts = [for (final id in ids) values[id]!.toInt()];
    final totalShares = counts.fold<int>(0, (sum, value) => sum + value);
    var allocated = 0;
    return [
      for (var i = 0; i < counts.length; i++)
        if (i == counts.length - 1)
          totalPaise - allocated
        else
          (() {
            final share = totalPaise * counts[i] ~/ totalShares;
            allocated += share;
            return share;
          })(),
    ];
  }

  List<String> _peopleInSelection() => _selectedIds.toList();

  static String _formatPaise(int paise) =>
      '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';

  static String _formatPercentage(int basisPoints) =>
      '${basisPoints ~/ 100}.${(basisPoints % 100).toString().padLeft(2, '0')}';

  Future<void> _openCalculator() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _CalculatorDialog(initialValue: _amountController.text),
    );
    if (result == null || !mounted) return;
    setState(() {
      _amountController.text = result == result.roundToDouble()
          ? result.toStringAsFixed(0)
          : result.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add expense')),
        body: FutureBuilder<_PeopleData>(
          future: _peopleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(_friendlyError(snapshot.error!)));
            }
            final data = snapshot.data!;
            final amountPaise = _parsePaise(_amountController.text);
            final splitValues = _readSplitValues(showErrors: false);
            List<int>? previewShares;
            String? previewError;
            if (amountPaise != null && splitValues != null) {
              try {
                previewShares = _calculateShares(amountPaise, splitValues);
              } on ArgumentError catch (error) {
                previewError = error.message?.toString();
              }
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Dinner, taxi, groceries…',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          hintText: '0.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Open calculator',
                      onPressed: _isSubmitting ? null : _openCalculator,
                      icon: const Icon(Icons.calculate_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _splitType,
                  decoration: const InputDecoration(labelText: 'Split method'),
                  items: const [
                    DropdownMenuItem(value: 'equal', child: Text('Equal')),
                    DropdownMenuItem(value: 'exact', child: Text('By amount')),
                    DropdownMenuItem(
                        value: 'percentage', child: Text('By percentage')),
                    DropdownMenuItem(value: 'shares', child: Text('By shares')),
                  ],
                  onChanged: _isSubmitting || _selectedIds.isEmpty
                      ? null
                      : (value) {
                          if (value != null) _changeSplitType(value, data);
                        },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Payer'),
                  child: Text('Paid by you (${data.profile.displayName})'),
                ),
                const SizedBox(height: 20),
                Text(
                  _splitType == 'equal'
                      ? 'Split equally between'
                      : 'People and split values',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                for (final person in data.people) ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedIds.contains(person.id),
                    title: Text(person.name),
                    onChanged:
                        _isSubmitting || person.id == data.profile.participantId
                            ? null
                            : (selected) => setState(() {
                                  if (selected == true) {
                                    _selectedIds.add(person.id);
                                    if (_splitType != 'equal') {
                                      _splitController(person.id).text =
                                          _splitType == 'shares' ? '1' : '0';
                                    }
                                  } else {
                                    _selectedIds.remove(person.id);
                                  }
                                }),
                  ),
                  if (_selectedIds.contains(person.id) && _splitType != 'equal')
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 56, right: 8, bottom: 8),
                      child: TextField(
                        controller: _splitController(person.id),
                        keyboardType: _splitType == 'shares'
                            ? TextInputType.number
                            : const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: InputDecoration(
                          labelText: switch (_splitType) {
                            'exact' => 'Amount (₹)',
                            'percentage' => 'Percentage (%)',
                            _ => 'Shares',
                          },
                          isDense: true,
                          suffixText: _splitType == 'percentage' ? '%' : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
                if (previewShares != null)
                  for (var i = 0; i < _peopleInSelection().length; i++)
                    Text(
                      '${data.people.firstWhere((person) => person.id == _peopleInSelection()[i]).name}: ₹${_formatPaise(previewShares[i])}',
                    ),
                if (previewError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      previewError,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : () => _submit(data),
                  child: Text(_isSubmitting ? 'Saving…' : 'Save expense'),
                ),
              ],
            );
          },
        ),
      );
}

class _PeopleData {
  const _PeopleData({required this.profile, required this.people});
  final Profile profile;
  final List<_Person> people;
}

class _Person {
  const _Person({required this.id, required this.name});
  final String id;
  final String name;
}

class _CalculatorDialog extends StatefulWidget {
  const _CalculatorDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  late String _display;
  double? _storedValue;
  String? _pendingOperator;
  bool _startNewNumber = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = double.tryParse(widget.initialValue);
    _display = initial == null ? '0' : _format(initial);
  }

  void _digit(String digit) {
    setState(() {
      _error = null;
      if (digit == '.' && !_startNewNumber && _display.contains('.')) return;
      if (_startNewNumber) {
        _display = digit == '.' ? '0.' : digit;
        _startNewNumber = false;
      } else {
        _display = _display == '0' && digit != '.' ? digit : '$_display$digit';
      }
    });
  }

  void _operator(String operator) {
    final value = double.tryParse(_display) ?? 0;
    if (_pendingOperator == '/' && value == 0 && !_startNewNumber) {
      setState(() => _error = 'Cannot divide by zero.');
      return;
    }
    setState(() {
      _storedValue = _pendingOperator == null || _startNewNumber
          ? value
          : _apply(_storedValue ?? value, value, _pendingOperator!);
      _pendingOperator = operator;
      _startNewNumber = true;
      _error = null;
    });
  }

  void _equals() {
    if (_pendingOperator == null || _storedValue == null) return;
    final current = double.tryParse(_display) ?? 0;
    if (_pendingOperator == '/' && current == 0) {
      setState(() => _error = 'Cannot divide by zero.');
      return;
    }
    setState(() {
      _display = _format(_apply(_storedValue!, current, _pendingOperator!));
      _storedValue = null;
      _pendingOperator = null;
      _startNewNumber = true;
      _error = null;
    });
  }

  static double _apply(double left, double right, String operator) =>
      switch (operator) {
        '+' => left + right,
        '−' => left - right,
        '×' => left * right,
        '÷' => left / right,
        _ => right,
      };

  static String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final keys = [
      'C',
      '⌫',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '−',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '0',
      '.',
      'Done',
    ];
    return AlertDialog(
      title: const Text('Calculator'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                _display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final key in keys)
                  FilledButton.tonal(
                    onPressed: () {
                      switch (key) {
                        case 'C':
                          setState(() {
                            _display = '0';
                            _storedValue = null;
                            _pendingOperator = null;
                            _startNewNumber = true;
                            _error = null;
                          });
                          break;
                        case '⌫':
                          setState(() {
                            _display = _display.length <= 1
                                ? '0'
                                : _display.substring(0, _display.length - 1);
                            _startNewNumber = false;
                          });
                          break;
                        case '+':
                        case '−':
                        case '×':
                        case '÷':
                          _operator(key);
                          break;
                        case '=':
                          _equals();
                          break;
                        case 'Done':
                          var result = double.tryParse(_display);
                          if (_pendingOperator != null &&
                              _storedValue != null &&
                              result != null) {
                            if (_pendingOperator == '/' && result == 0) {
                              setState(() => _error = 'Cannot divide by zero.');
                              break;
                            }
                            result = _apply(
                              _storedValue!,
                              result,
                              _pendingOperator!,
                            );
                          }
                          if (result != null && result.isFinite) {
                            Navigator.of(context).pop(result);
                          }
                          break;
                        default:
                          _digit(key);
                          break;
                      }
                    },
                    child: Text(key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
