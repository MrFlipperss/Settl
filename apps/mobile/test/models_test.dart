import 'package:flutter_test/flutter_test.dart';

import 'package:settl/models/balance.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/models/list_member.dart';
import 'package:settl/models/list_model.dart';
import 'package:settl/models/participant.dart';
import 'package:settl/models/pending_sync_operation.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/models/receipt_detail.dart';

void main() {
  group('Expense', () {
    final expense = Expense(
      id: 'exp-1',
      amount: 2500.50,
      category: 'Food',
      splitType: 'equal',
      payerId: 'part-1',
      listId: 'list-1',
      note: 'Lunch',
      idempotencyKey: 'idem-1',
      version: 2,
      createdAt: DateTime.utc(2026, 7, 1, 10),
    );

    test('fromJson parses snake_case payload', () {
      final json = expense.toJson();
      expect(json['split_type'], 'equal');
      expect(json['payer_id'], 'part-1');
      expect(json['created_at'], '2026-07-01T10:00:00.000Z');

      final parsed = Expense.fromJson(json);
      expect(parsed, expense);
    });

    test('toJson/fromJson round-trips', () {
      final parsed = Expense.fromJson(expense.toJson());
      expect(parsed, expense);
      expect(parsed.hashCode, expense.hashCode);
    });

    test('copyWith updates only provided fields', () {
      final updated = expense.copyWith(amount: 3000, note: 'Dinner');
      expect(updated.amount, 3000);
      expect(updated.note, 'Dinner');
      expect(updated.id, 'exp-1');
      expect(updated.splitType, 'equal');
    });

    test('equality ignores nothing and distinguishes values', () {
      expect(expense, expense);
      expect(expense, expense.copyWith());
      expect(expense == expense.copyWith(amount: 1), isFalse);
    });
  });

  group('ExpenseSplit', () {
    const split = ExpenseSplit(
      id: 'split-1',
      expenseId: 'exp-1',
      participantId: 'part-2',
      shareAmount: 833.50,
      rawInput: 33.33,
    );

    test('toJson/fromJson round-trips', () {
      final parsed = ExpenseSplit.fromJson(split.toJson());
      expect(parsed, split);
      expect(parsed.hashCode, split.hashCode);
    });

    test('null rawInput round-trips', () {
      const minimal = ExpenseSplit(
        id: 'split-2',
        expenseId: 'exp-2',
        participantId: 'part-3',
        shareAmount: 100,
      );
      final parsed = ExpenseSplit.fromJson(minimal.toJson());
      expect(parsed.rawInput, isNull);
      expect(parsed, minimal);
    });

    test('copyWith updates only provided fields', () {
      final updated = split.copyWith(shareAmount: 500);
      expect(updated.shareAmount, 500);
      expect(updated.participantId, 'part-2');
    });
  });

  group('Contact', () {
    final contact = Contact(
      participantId: 'part-9',
      phoneNumber: '+919876543210',
      displayName: 'Rahul',
      createdBy: 'part-1',
      claimedByParticipantId: 'part-5',
      createdAt: DateTime.utc(2026, 6, 15, 8, 30),
    );

    test('fromJson parses snake_case payload', () {
      final json = contact.toJson();
      expect(json['participant_id'], 'part-9');
      expect(json['phone_number'], '+919876543210');
      expect(json['created_by'], 'part-1');
      expect(json['claimed_by_participant_id'], 'part-5');

      expect(Contact.fromJson(json), contact);
    });

    test('unclaimed contact round-trips', () {
      final unclaimed = contact.copyWith(claimedByParticipantId: null);
      final json = unclaimed.toJson();
      expect(json['claimed_by_participant_id'], isNull);
      expect(Contact.fromJson(json), unclaimed);
    });

    test('copyWith updates only provided fields', () {
      final updated = contact.copyWith(displayName: 'Rahul Kumar');
      expect(updated.displayName, 'Rahul Kumar');
      expect(updated.phoneNumber, '+919876543210');
      expect(updated.participantId, 'part-9');
    });
  });

  group('ListModel', () {
    final list = ListModel(
      id: 'list-1',
      name: 'Goa Trip',
      accountNumber: 'LST-0001',
      createdBy: 'part-1',
      createdAt: DateTime.utc(2026, 5, 20, 12),
    );

    test('toJson/fromJson round-trips', () {
      final json = list.toJson();
      expect(json['account_number'], 'LST-0001');
      expect(ListModel.fromJson(json), list);
      expect(ListModel.fromJson(json).hashCode, list.hashCode);
    });

    test('copyWith updates only provided fields', () {
      final updated = list.copyWith(name: 'Flatmates');
      expect(updated.name, 'Flatmates');
      expect(updated.accountNumber, 'LST-0001');
    });
  });

  group('ListMember', () {
    final member = ListMember(
      listId: 'list-1',
      participantId: 'part-2',
      addedAt: DateTime.utc(2026, 5, 21, 9),
    );

    test('toJson/fromJson round-trips', () {
      final parsed = ListMember.fromJson(member.toJson());
      expect(parsed, member);
      expect(parsed.hashCode, member.hashCode);
    });

    test('copyWith updates only provided fields', () {
      final updated = member.copyWith(participantId: 'part-3');
      expect(updated.participantId, 'part-3');
      expect(updated.listId, 'list-1');
    });
  });

  group('Profile', () {
    final profile = Profile(
      userId: 'user-1',
      participantId: 'part-1',
      displayName: 'Dhruv',
      phoneNumber: '+919999999999',
      upiId: 'dhruv@upi',
      createdAt: DateTime.utc(2026, 1, 10, 5),
    );

    test('toJson/fromJson round-trips', () {
      final json = profile.toJson();
      expect(json['user_id'], 'user-1');
      expect(json['participant_id'], 'part-1');
      expect(json['upi_id'], 'dhruv@upi');

      expect(Profile.fromJson(json), profile);
      expect(Profile.fromJson(json).hashCode, profile.hashCode);
    });

    test('profile without upiId round-trips', () {
      final noUpi = profile.copyWith(upiId: null);
      expect(Profile.fromJson(noUpi.toJson()), noUpi);
    });

    test('copyWith updates only provided fields', () {
      final updated = profile.copyWith(displayName: 'Dhruv K');
      expect(updated.displayName, 'Dhruv K');
      expect(updated.userId, 'user-1');
    });
  });

  group('Participant', () {
    const participant = Participant(id: 'part-1', kind: 'user');

    test('toJson/fromJson round-trips', () {
      final json = participant.toJson();
      expect(json['kind'], 'user');
      expect(Participant.fromJson(json), participant);
    });

    test('copyWith updates only provided fields', () {
      final updated = participant.copyWith(kind: 'contact');
      expect(updated.kind, 'contact');
      expect(updated.id, 'part-1');
    });
  });

  group('ReceiptDetail', () {
    final receipt = ReceiptDetail(
      expenseId: 'exp-1',
      createdBy: 'part-1',
      merchant: 'Cafe XYZ',
      ocrTotal: 1250.00,
      ocrDate: '2026-07-01',
      lineItems: ['Coffee', 'Sandwich'],
      createdAt: DateTime.utc(2026, 7, 1, 10, 5),
    );

    test('toJson/fromJson round-trips', () {
      final json = receipt.toJson();
      expect(json['expense_id'], 'exp-1');
      expect(json['line_items'], ['Coffee', 'Sandwich']);
      expect(json['ocr_total'], 1250.00);

      expect(ReceiptDetail.fromJson(json), receipt);
      expect(ReceiptDetail.fromJson(json).hashCode, receipt.hashCode);
    });

    test('null optional fields round-trip', () {
      final minimal = ReceiptDetail(
        expenseId: 'exp-2',
        createdBy: 'part-2',
        createdAt: DateTime.utc(2026, 7, 2, 8),
      );
      final json = minimal.toJson();
      expect(json['merchant'], isNull);
      expect(json['line_items'], isNull);
      expect(ReceiptDetail.fromJson(json), minimal);
    });

    test('copyWith updates only provided fields', () {
      final updated = receipt.copyWith(merchant: 'New Cafe');
      expect(updated.merchant, 'New Cafe');
      expect(updated.expenseId, 'exp-1');
      expect(updated.lineItems, ['Coffee', 'Sandwich']);
    });
  });

  group('Balance', () {
    const balance = Balance(
      fromParticipantId: 'part-2',
      toParticipantId: 'part-1',
      amountOwed: 833.50,
    );

    test('toJson/fromJson round-trips with snake_case payload', () {
      final json = balance.toJson();
      expect(json['from_participant'], 'part-2');
      expect(json['to_participant'], 'part-1');
      expect(json['amount_owed'], 833.50);

      expect(Balance.fromJson(json), balance);
      expect(Balance.fromJson(json).hashCode, balance.hashCode);
    });

    test('copyWith updates only provided fields', () {
      final updated = balance.copyWith(amountOwed: 0);
      expect(updated.amountOwed, 0);
      expect(updated.fromParticipantId, 'part-2');
      expect(updated.toParticipantId, 'part-1');
    });

    test('equality distinguishes direction', () {
      final reversed = balance.copyWith(
        fromParticipantId: 'part-1',
        toParticipantId: 'part-2',
      );
      expect(balance == reversed, isFalse);
    });
  });

  group('PendingSyncOperation', () {
    final op = PendingSyncOperation(
      operationId: 'op-1',
      entityType: 'expense',
      entityId: 'exp-1',
      operation: SyncOperation.insert,
      payload: '{"id":"exp-1"}',
      createdAt: DateTime.utc(2026, 7, 1, 10),
    );

    test('toJson/fromJson round-trips', () {
      final json = op.toJson();
      expect(json['operation_id'], 'op-1');
      expect(json['operation'], 'insert');
      expect(json['entity_type'], 'expense');

      expect(PendingSyncOperation.fromJson(json), op);
      expect(PendingSyncOperation.fromJson(json).hashCode, op.hashCode);
    });

    test('syncedAt round-trips when present', () {
      final synced = op.copyWith(
        syncedAt: DateTime.utc(2026, 7, 1, 10, 1),
      );
      final parsed = PendingSyncOperation.fromJson(synced.toJson());
      expect(parsed.syncedAt, DateTime.utc(2026, 7, 1, 10, 1));
      expect(parsed, synced);
    });

    test('copyWith updates only provided fields', () {
      final updated = op.copyWith(operation: SyncOperation.update);
      expect(updated.operation, SyncOperation.update);
      expect(updated.operationId, 'op-1');
      expect(updated.payload, '{"id":"exp-1"}');
    });
  });

  group('SyncOperation enum', () {
    test('values round-trip by name', () {
      for (final op in SyncOperation.values) {
        expect(SyncOperation.values.byName(op.name), op);
      }
    });
  });
}
