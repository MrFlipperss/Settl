import '../database/database.dart';
import '../models/list_model.dart';
import '../models/list_member.dart';

class ListsRepository {
  final Database _db;

  ListsRepository(this._db);

  Future<List<ListModel>> getLists() async {
    final response = await _db.client.from('lists').select();
    return response.map((json) => ListModel.fromJson(json)).toList();
  }

  Future<ListModel> createList(ListModel list) async {
    final response = await _db.client
        .from('lists')
        .insert(list.toJson())
        .select()
        .single();
    return ListModel.fromJson(response);
  }

  Future<List<ListMember>> getMembers(String listId) async {
    final response = await _db.client
        .from('list_members')
        .select()
        .eq('list_id', listId);
    return response.map((json) => ListMember.fromJson(json)).toList();
  }

  Future<void> addMember(ListMember member) async {
    await _db.client.from('list_members').insert(member.toJson());
  }
}
