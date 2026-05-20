import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.order,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      order: (data['order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'order': order,
    };
  }
}
