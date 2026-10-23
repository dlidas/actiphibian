//Interface for models to ensure consistant mapping to and
//from the database and memory
abstract class IMappable<T> {
  Map<String, Object?> toMap();
}