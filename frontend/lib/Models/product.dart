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
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      oldPrice: data['oldPrice'] != null ? data['oldPrice'].toDouble() : null,
      discount: data['discount'] != null ? data['discount'].toDouble() : null,
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      sellerId: data['sellerId'] as String?,
      sellerName: data['sellerName'] as String?,
      location: data['location'] as String?,
      isDealOfTheDay: data['isDealOfTheDay'] ?? false,
      isTrending: data['isTrending'] ?? false,
      isNewArrival: data['isNewArrival'] ?? false,
      stock: data['stock'] != null ? (data['stock'] as num).toInt() : 0,
    );
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
