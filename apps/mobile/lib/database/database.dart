abstract class Database {
  // Drift database instance
  Object get instance;

  Future<void> initialize();
  Future<void> close();
}