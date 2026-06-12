import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/product.dart';
import '../Models/category_model.dart';
import '../Models/banner_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────────── Products ─────────────────────
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> getProductsBySeller(String sellerId) {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    if (product.id != null) {
      await _db.collection('products').doc(product.id).update(product.toMap());
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // ───────────────────── Categories ─────────────────────
  /// Stream dari koleksi 'categories', diurutkan berdasarkan field 'order'
  Stream<List<CategoryModel>> getCategories() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList());
  }

  // ───────────────────── Banners ─────────────────────
  /// Stream dari koleksi 'banners', diurutkan berdasarkan field 'order'
  /// Tipe banner: 'promo', 'special_offer', 'flat_heels', 'summer_sale', 'sponsored'
  Stream<List<BannerModel>> getBanners() {
    return _db
        .collection('banners')
        .orderBy('order')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BannerModel.fromFirestore(doc)).toList());
  }

  // ───────────────────── Marketing Queries & CRUD ─────────────────────
  Stream<List<Product>> getDealProducts() {
    return _db
        .collection('products')
        .where('isDealOfTheDay', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> getTrendingProducts() {
    return _db
        .collection('products')
        .where('isTrending', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Stream<List<Product>> getNewArrivalProducts() {
    return _db
        .collection('products')
        .where('isNewArrival', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<void> toggleProductFlag(String productId, String fieldName, bool value) async {
    await _db.collection('products').doc(productId).update({fieldName: value});
  }

  Future<void> addBanner(BannerModel banner) async {
    await _db.collection('banners').add(banner.toMap());
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _db.collection('banners').doc(banner.id).update(banner.toMap());
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }

  Stream<DocumentSnapshot> getSettings(String docName) {
    return _db.collection('settings').doc(docName).snapshots();
  }

  Future<void> updateSettings(String docName, Map<String, dynamic> data) async {
    await _db.collection('settings').doc(docName).set(data, SetOptions(merge: true));
  }
}
