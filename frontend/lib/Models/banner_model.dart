import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipe banner yang digunakan di dashboard:
/// 'promo'         → banner promo utama (kanan atas)
/// 'special_offer' → banner penawaran spesial
/// 'flat_heels'    → banner flat & heels
/// 'summer_sale'   → banner hot summer sale
/// 'sponsored'     → banner sponsored
class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String type;
  final int order;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.order,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BannerModel(
      id: doc.id,
      imageUrl: (data['imageUrl'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      type: (data['type'] as String?) ?? '',
      order: (data['order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'order': order,
    };
  }
}
