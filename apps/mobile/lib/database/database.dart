import 'package:drift/drift.dart';

abstract class Database {
  // Drift database instance
  Object get instance;

  Future<void> initialize();
  Future<void> close();
}