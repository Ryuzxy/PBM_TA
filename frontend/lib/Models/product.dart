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
  final String? sellerId;
  final String? sellerName;
  final String? location;
  final bool isDealOfTheDay;
  final bool isTrending;
  final bool isNewArrival;
  final int stock;

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
    this.sellerId,
    this.sellerName,
    this.location,
    this.isDealOfTheDay = false,
    this.isTrending = false,
    this.isNewArrival = false,
    this.stock = 0,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    try {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      double? parseOptionalDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
      }

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return Product(
        id: doc.id,
        title: data['title']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        price: parseDouble(data['price']),
        oldPrice: parseOptionalDouble(data['oldPrice']),
        discount: parseOptionalDouble(data['discount']),
        imageUrl: data['imageUrl']?.toString() ?? '',
        rating: parseDouble(data['rating']),
        reviews: parseInt(data['reviews']),
        sellerId: data['sellerId']?.toString(),
        sellerName: data['sellerName']?.toString(),
        location: data['location']?.toString(),
        isDealOfTheDay: data['isDealOfTheDay'] == true,
        isTrending: data['isTrending'] == true,
        isNewArrival: data['isNewArrival'] == true,
        stock: data['stock'] != null ? parseInt(data['stock']) : 0,
      );
    } catch (e) {
      return Product(
        id: doc.id,
        title: 'Error Loading Product',
        description: 'Error: $e',
        price: 0.0,
        imageUrl: '',
        stock: 0,
        location: 'Unknown',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'location': location,
      'isDealOfTheDay': isDealOfTheDay,
      'isTrending': isTrending,
      'isNewArrival': isNewArrival,
      'stock': stock,
    };
  }
}
