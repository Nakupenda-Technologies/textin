import 'package:equatable/equatable.dart';

class CurrentItem extends Equatable {
  const CurrentItem({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  static CurrentItem? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    final description = json['description'];
    return CurrentItem(
      id: id,
      name: name,
      description: description is String && description.isNotEmpty
          ? description
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, description];
}
