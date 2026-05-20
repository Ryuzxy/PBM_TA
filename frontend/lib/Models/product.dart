import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String title;
  final String description;
  final double price;
  final double? oldPrice;
  final double? discount;
  final String imageUrl;
  final double rating;
  final int reviews;

  Product({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    this.oldPrice,
    this.discount,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviews = 0,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      oldPrice: data['old_price'] != null ? data['old_price'].toDouble() : null,
      discount: data['discount'] != null ? data['discount'].toDouble() : null,
      imageUrl: data['image_url'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'old_price': oldPrice,
      'discount': discount,
      'image_url': imageUrl,
      'rating': rating,
      'reviews': reviews,
    };
  }
}
