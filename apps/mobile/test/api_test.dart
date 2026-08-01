import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:settl/api/api_client.dart';
import 'package:settl/api/api_exception.dart';
import 'package:settl/api/balances_api.dart';
import 'package:settl/api/collections_api.dart';
import 'package:settl/api/contacts_api.dart';
import 'package:settl/api/expenses_api.dart';
import 'package:settl/api/health_api.dart';
import 'package:settl/api/models/api_balance.dart';
import 'package:settl/api/models/api_collection.dart';
import 'package:settl/api/models/api_contact.dart';
import 'package:settl/api/models/api_contact_search_result.dart';
import 'package:settl/api/models/api_expense.dart';
import 'package:settl/api/models/api_health.dart';
import 'package:settl/api/models/api_profile.dart';
import 'package:settl/api/models/api_receipt.dart';
import 'package:settl/api/models/api_requests.dart';
import 'package:settl/api/profile_api.dart';

ApiClient clientWith(
  MockClient mock, {
  String baseUrl = 'http://localhost:3000/api',
  String? Function()? tokenProvider,
}) =>
    ApiClient(client: mock, baseUrl: baseUrl, tokenProvider: tokenProvider);

void main() {
  group('DTO round-trips', () {
    test('ApiHealth parses status and service', () {
      const health = ApiHealth(status: 'ok', service: 'settl-api');
      expect(ApiHealth.fromJson(health.toJson()), health);
    });

    test('ApiProfile parses snake_case with nullables', () {
      final profile = ApiProfile(
        participantId: 'part-1',
        userId: 'user-1',
        displayName: 'Aarav',
        phoneNumber: '+919876543210',
        upiId: 'aarav@upi',
        createdAt: DateTime.utc(2026, 7, 1, 10),
      );
      final json = profile.toJson();
      expect(json['participant_id'], 'part-1');
      expect(json['user_id'], 'user-1');
      expect(json['display_name'], 'Aarav');
      expect(json['phone_number'], '+919876543210');
      expect(json['upi_id'], 'aarav@upi');

      expect(ApiProfile.fromJson(json), profile);
    });

    test('ApiProfile handles null upiId/updatedAt/deletedAt', () {
      final json = {
        'participant_id': 'part-1',
        'user_id': 'user-1',
        'display_name': 'Aarav',
        'phone_number': '+919876543210',
        'created_at': '2026-07-01T10:00:00.000Z',
      };
      final parsed = ApiProfile.fromJson(json);
      expect(parsed.upiId, isNull);
      expect(parsed.updatedAt, isNull);
      expect(parsed.deletedAt, isNull);
    });

    test('ApiContact parses version and claim state', () {
      final contact = ApiContact(
        participantId: 'part-9',
        displayName: 'Rahul',
        phoneNumber: '+919876543210',
        createdBy: 'part-1',
        claimedByParticipantId: 'part-5',
        createdAt: DateTime.utc(2026, 6, 15, 8, 30),
        version: 3,
      );
      final json = contact.toJson();
      expect(json['claimed_by_participant_id'], 'part-5');
      expect(json['version'], 3);
      expect(ApiContact.fromJson(json), contact);
    });

    test('ApiContactSearchResult parses', () {
      const result = ApiContactSearchResult(
        participantId: 'part-2',
        displayName: 'Priya',
        phoneNumber: '+919812345678',
      );
      expect(ApiContactSearchResult.fromJson(result.toJson()), result);
    });

    test('ApiCollection parses member_count and account_number', () {
      final collection = ApiCollection(
        id: 'list-1',
        accountNumber: 'LST-0001',
        name: 'Mumbai Trip',
        createdBy: 'part-1',
        createdAt: DateTime.utc(2026, 7, 2),
        version: 2,
        memberCount: 4,
      );
      final json = collection.toJson();
      expect(json['account_number'], 'LST-0001');
      expect(json['member_count'], 4);
      expect(ApiCollection.fromJson(json), collection);
    });

    test('ApiExpense parses paise, timestamp key and splits', () {
      final expense = ApiExpense(
        id: 'exp-1',
        groupId: 'list-1',
        payerId: 'part-1',
        amountPaise: 250050,
        category: 'Food',
        note: 'Lunch',
        splitType: 'equal',
        version: 2,
        timestamp: DateTime.utc(2026, 7, 1, 10),
        splits: const [
          ApiSplit(
            id: 'split-1',
            userId: 'part-2',
            shareAmountPaise: 125025,
          ),
        ],
      );
      final json = expense.toJson();
      expect(json['amount_paise'], 250050);
      expect(json['group_id'], 'list-1');
      expect(json['split_type'], 'equal');
      expect(json.containsKey('timestamp'), isTrue);
      expect(json['splits'], hasLength(1));

      final parsed = ApiExpense.fromJson(json);
      expect(parsed, expense);
      expect(parsed.splits.single.shareAmountPaise, 125025);
    });

    test('ApiExpense handles null groupId and empty splits', () {
      final json = {
        'id': 'exp-2',
        'payer_id': 'part-1',
        'amount_paise': 5000,
        'category': 'Uncategorized',
        'split_type': 'exact',
        'version': 1,
        'timestamp': '2026-07-01T10:00:00.000Z',
      };
      final parsed = ApiExpense.fromJson(json);
      expect(parsed.groupId, isNull);
      expect(parsed.splits, isEmpty);
      expect(parsed.amountPaise, 5000);
    });

    test('ApiBalancesResponse parses paise and breakdown', () {
      const response = ApiBalancesResponse(
        totalOwedPaise: 10000,
        totalOwingPaise: 2500,
        netPaise: 7500,
        breakdown: [
          ApiBalanceEntry(
            userId: 'part-2',
            userName: 'Priya',
            amountPaise: 7500,
            currency: 'INR',
          ),
        ],
      );
      final json = response.toJson();
      expect(json['total_owed_paise'], 10000);
      expect(json['net_paise'], 7500);
      expect(json['breakdown'], hasLength(1));

      final parsed = ApiBalancesResponse.fromJson(json);
      expect(parsed, response);
      expect(parsed.breakdown.single.userId, 'part-2');
    });

    test('ApiReceiptDetail parses ocr_total_paise as int', () {
      final receipt = ApiReceiptDetail(
        expenseId: 'exp-1',
        merchant: 'Cafe XYZ',
        ocrTotalPaise: 250050,
        ocrDate: '2026-07-01',
        lineItems: const ['Coffee', 'Sandwich'],
        createdBy: 'part-1',
        createdAt: DateTime.utc(2026, 7, 1, 11),
      );
      final json = receipt.toJson();
      expect(json['ocr_total_paise'], 250050);
      expect(json['line_items'], hasLength(2));

      final parsed = ApiReceiptDetail.fromJson(json);
      expect(parsed, receipt);
    });

    test('ApiReceiptDetail handles no OCR data', () {
      final json = {
        'expense_id': 'exp-2',
        'created_by': 'part-1',
        'created_at': '2026-07-01T11:00:00.000Z',
      };
      final parsed = ApiReceiptDetail.fromJson(json);
      expect(parsed.merchant, isNull);
      expect(parsed.ocrTotalPaise, isNull);
      expect(parsed.ocrDate, isNull);
      expect(parsed.lineItems, isEmpty);
    });

    test('request DTOs omit null fields from JSON', () {
      const profile = ApiCreateProfileRequest(
        displayName: 'Aarav',
        phoneNumber: '+919876543210',
      );
      expect(profile.toJson(), {
        'display_name': 'Aarav',
        'phone_number': '+919876543210',
      });

      const contact = ApiCreateContactRequest(
        id: 'part-9',
        displayName: 'Rahul',
        phoneNumber: '+919876543210',
      );
      expect(contact.toJson(), {
        'id': 'part-9',
        'display_name': 'Rahul',
        'phone_number': '+919876543210',
      });

      const collection = ApiCreateCollectionRequest(name: 'Trip');
      expect(collection.toJson(), {'name': 'Trip'});

      const receipt = ApiCreateReceiptRequest(
        merchant: 'Cafe',
        lineItems: ['Coffee'],
      );
      expect(receipt.toJson(), {
        'merchant': 'Cafe',
        'line_items': ['Coffee'],
      });
    });

    test('ApiCreateExpenseRequest serializes splits and rupees', () {
      const request = ApiCreateExpenseRequest(
        groupId: 'list-1',
        payerId: 'part-1',
        amount: 2500.50,
        splitType: 'equal',
        note: 'Lunch',
        idempotencyKey: 'idem-1',
        splits: [
          ApiCreateSplitItem(userId: 'part-2'),
          ApiCreateSplitItem(userId: 'part-3', exactAmount: 500.25),
        ],
      );
      final json = request.toJson();
      expect(json['amount'], 2500.50);
      expect(json['group_id'], 'list-1');
      expect(json['idempotency_key'], 'idem-1');
      expect(json['category'], isNull);
      expect(json['splits'], hasLength(2));
      expect((json['splits'] as List).first, {'user_id': 'part-2'});
      expect((json['splits'] as List).last, {
        'user_id': 'part-3',
        'exact_amount': 500.25,
      });
    });
  });

  group('ApiClient', () {
    test('attaches Bearer token when tokenProvider yields one', () async {
      late http.Request captured;
      final client = clientWith(
        MockClient((request) async {
          captured = request;
          return http.Response('{}', 200);
        }),
        tokenProvider: () => 'token-123',
      );

      await client.get('v1/health');
      expect(captured.headers['Authorization'], 'Bearer token-123');
      expect(captured.headers['accept'], 'application/json');
    });

    test('omits Authorization when no token', () async {
      late http.Request captured;
      final client = clientWith(
        MockClient((request) async {
          captured = request;
          return http.Response('{}', 200);
        }),
      );

      await client.get('v1/health');
      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('sends JSON content-type with body', () async {
      late http.Request captured;
      final client = clientWith(MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      }));

      await client.post('v1/profile', body: {'name': 'A'});
      expect(captured.headers['content-type'], 'application/json');
      expect(jsonDecode(captured.body), {'name': 'A'});
    });

    test('decodes error body into ApiException', () async {
      final client = clientWith(MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'contact not found'}),
          404,
        ),
      ));

      expect(
        () => client.get('v1/contacts/search'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'contact not found')
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws ApiException with generic message on non-JSON error',
        () async {
      final client = clientWith(
        MockClient((_) async => http.Response('gateway timeout', 502)),
      );

      expect(
        () => client.get('v1/health'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Request failed with status 502',
          ),
        ),
      );
    });

    test('treats 204 as success without throwing', () async {
      final client = clientWith(
        MockClient((_) async => http.Response('', 204)),
      );

      await client.delete('v1/expenses/exp-1');
    });

    test('accepts 201 from post', () async {
      final client = clientWith(MockClient(
        (_) async => http.Response(
          jsonEncode({'id': 'exp-1'}),
          201,
        ),
      ));

      final result = await client.post('v1/expenses/', body: {'x': 1});
      expect(result, {'id': 'exp-1'});
    });

    test('resolves paths against baseUrl preserving trailing slashes',
        () async {
      late Uri uri;
      final client = clientWith(MockClient((request) async {
        uri = request.url;
        return http.Response('[]', 200);
      }));

      await client.get('v1/groups/');
      expect(uri.toString(), 'http://localhost:3000/api/v1/groups/');
    });

    test('strips a leading slash from the path', () async {
      late Uri uri;
      final client = clientWith(MockClient((request) async {
        uri = request.url;
        return http.Response('{}', 200);
      }));

      await client.get('/health');
      expect(uri.toString(), 'http://localhost:3000/api/health');
    });

    test('passes query parameters', () async {
      late Uri uri;
      final client = clientWith(MockClient((request) async {
        uri = request.url;
        return http.Response('{}', 200);
      }));

      await client.get('v1/expenses/', query: {'groupID': 'list-1'});
      expect(uri.queryParameters, {'groupID': 'list-1'});
    });
  });

  group('Domain clients', () {
    test('HealthApi hits root /health without auth', () async {
      late http.Request captured;
      final api = HealthApi(
        clientWith(
          MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({'status': 'ok', 'service': 'settl-api'}),
              200,
            );
          }),
          baseUrl: 'http://localhost:3000',
        ),
      );

      final health = await api.checkHealth();
      expect(captured.url.toString(), 'http://localhost:3000/health');
      expect(captured.headers.containsKey('Authorization'), isFalse);
      expect(health.status, 'ok');
    });

    test('ProfileApi posts to v1/profile and parses response', () async {
      final api = ProfileApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/profile');
          return http.Response(
            jsonEncode({
              'participant_id': 'part-1',
              'user_id': 'user-1',
              'display_name': 'Aarav',
              'phone_number': '+919876543210',
              'created_at': '2026-07-01T10:00:00.000Z',
            }),
            201,
          );
        })),
      );

      final profile = await api.createProfile(
        const ApiCreateProfileRequest(
          displayName: 'Aarav',
          phoneNumber: '+919876543210',
        ),
      );
      expect(profile.participantId, 'part-1');
      expect(profile.userId, 'user-1');
    });

    test('ContactsApi.searchContacts sends q and parses list', () async {
      final api = ContactsApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/contacts/search');
          expect(request.url.queryParameters, {'q': 'rah'});
          return http.Response(
            jsonEncode([
              {
                'participant_id': 'part-9',
                'display_name': 'Rahul',
                'phone_number': '+919876543210',
              },
            ]),
            200,
          );
        })),
      );

      final results = await api.searchContacts('rah');
      expect(results, hasLength(1));
      expect(results.single.displayName, 'Rahul');
    });

    test('ContactsApi.claimContacts returns claimed count', () async {
      final api = ContactsApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/contacts/claim');
          expect(jsonDecode(request.body), {
            'phone_number': '+919876543210',
          });
          return http.Response(
            jsonEncode({'claimed': 2, 'message': '2 contacts claimed'}),
            200,
          );
        })),
      );

      expect(await api.claimContacts('+919876543210'), 2);
    });

    test('CollectionsApi.createCollection posts to trailing-slash route',
        () async {
      final api = CollectionsApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'POST');
          expect(
              request.url.toString(), 'http://localhost:3000/api/v1/groups/');
          return http.Response(
            jsonEncode({
              'id': 'list-1',
              'account_number': 'LST-0001',
              'name': 'Trip',
              'created_by': 'part-1',
              'created_at': '2026-07-02T00:00:00.000Z',
              'version': 1,
              'member_count': 1,
            }),
            201,
          );
        })),
      );

      final collection =
          await api.createCollection(const ApiCreateCollectionRequest(
        name: 'Trip',
      ));
      expect(collection.id, 'list-1');
      expect(collection.accountNumber, 'LST-0001');
    });

    test('CollectionsApi.getCollection and addMember', () async {
      var calls = 0;
      final api = CollectionsApi(
        clientWith(MockClient((request) async {
          calls++;
          if (request.url.path.endsWith('/members')) {
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {'user_id': 'part-9'});
            return http.Response('', 201);
          }
          expect(request.url.path, '/api/v1/groups/list-1');
          return http.Response(
            jsonEncode({
              'id': 'list-1',
              'account_number': 'LST-0001',
              'name': 'Trip',
              'created_by': 'part-1',
              'created_at': '2026-07-02T00:00:00.000Z',
              'version': 1,
              'member_count': 2,
            }),
            200,
          );
        })),
      );

      final collection = await api.getCollection('list-1');
      expect(collection.memberCount, 2);
      await api.addMember('list-1', 'part-9');
      expect(calls, 2);
    });

    test('ExpensesApi.listExpenses sends groupID and RFC3339 window', () async {
      final api = ExpensesApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/expenses/');
          expect(request.url.queryParameters, {
            'groupID': 'list-1',
            'from': '2026-07-01T00:00:00.000Z',
          });
          return http.Response('[]', 200);
        })),
      );

      await api.listExpenses(
        groupId: 'list-1',
        from: DateTime.utc(2026, 7, 1),
      );
    });

    test('ExpensesApi.createExpense posts rupees and parses paise', () async {
      final api = ExpensesApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'POST');
          expect(
              request.url.toString(), 'http://localhost:3000/api/v1/expenses/');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['amount'], 2500.50);
          expect(body['split_type'], 'equal');
          return http.Response(
            jsonEncode({
              'id': 'exp-1',
              'payer_id': 'part-1',
              'amount_paise': 250050,
              'category': 'Uncategorized',
              'split_type': 'equal',
              'version': 1,
              'timestamp': '2026-07-01T10:00:00.000Z',
              'splits': [
                {
                  'id': 'split-1',
                  'user_id': 'part-2',
                  'share_amount_paise': 125025,
                },
              ],
            }),
            201,
          );
        })),
      );

      final expense = await api.createExpense(
        const ApiCreateExpenseRequest(
          payerId: 'part-1',
          amount: 2500.50,
          splitType: 'equal',
          splits: [ApiCreateSplitItem(userId: 'part-2')],
        ),
      );
      expect(expense.amountPaise, 250050);
      expect(expense.splits.single.shareAmountPaise, 125025);
    });

    test('ExpensesApi.deleteExpense accepts 204', () async {
      final api = ExpensesApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/v1/expenses/exp-1');
          return http.Response('', 204);
        })),
      );

      await api.deleteExpense('exp-1');
    });

    test('ExpensesApi receipt create and get', () async {
      var calls = 0;
      final api = ExpensesApi(
        clientWith(MockClient((request) async {
          calls++;
          expect(request.url.path, '/api/v1/expenses/exp-1/receipt');
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'expense_id': 'exp-1',
                'merchant': 'Cafe XYZ',
                'ocr_total_paise': 250050,
                'line_items': ['Coffee'],
                'created_by': 'part-1',
                'created_at': '2026-07-01T11:00:00.000Z',
              }),
              200,
            );
          }
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'merchant': 'Cafe XYZ',
            'line_items': ['Coffee'],
          });
          return http.Response(
            jsonEncode({
              'expense_id': 'exp-1',
              'merchant': 'Cafe XYZ',
              'ocr_total_paise': 250050,
              'line_items': ['Coffee'],
              'created_by': 'part-1',
              'created_at': '2026-07-01T11:00:00.000Z',
            }),
            200,
          );
        })),
      );

      final created = await api.createReceipt(
        'exp-1',
        const ApiCreateReceiptRequest(
          merchant: 'Cafe XYZ',
          lineItems: ['Coffee'],
        ),
      );
      expect(created.ocrTotalPaise, 250050);

      final fetched = await api.getReceipt('exp-1');
      expect(fetched.merchant, 'Cafe XYZ');
      expect(calls, 2);
    });

    test('BalancesApi.getBalances sends personID and parses paise', () async {
      final api = BalancesApi(
        clientWith(MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/balances');
          expect(request.url.queryParameters, {'personID': 'part-9'});
          return http.Response(
            jsonEncode({
              'total_owed_paise': 10000,
              'total_owing_paise': 2500,
              'net_paise': 7500,
              'breakdown': [
                {
                  'user_id': 'part-9',
                  'user_name': 'Rahul',
                  'amount_paise': 7500,
                  'currency': 'INR',
                },
              ],
            }),
            200,
          );
        })),
      );

      final balances = await api.getBalances(personId: 'part-9');
      expect(balances.netPaise, 7500);
      expect(balances.breakdown.single.userName, 'Rahul');
    });
  });
}
