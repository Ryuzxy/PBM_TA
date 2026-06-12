import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/theme_manager.dart';
import '../../Models/product.dart';
import 'items_detail.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // Simulated wishlist — in real app, load from Firestore user's wishlist subcollection
  final List<String> _wishlistIds = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen to user's wishlist subcollection
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          _wishlistIds
            ..clear()
            ..addAll(snap.docs.map((d) => d.id));
        });
      }
    });
  }

  Future<void> _removeFromWishlist(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(productId)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from wishlist'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, currentTheme, _) {
        final bgColor = currentTheme.bgColor;
        final textColor = currentTheme.textColor;
        final cardColor = currentTheme.cardColor;
        final accentColor = currentTheme.accentColor;
        final subTextColor = currentTheme.subTextColor;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'My Wishlist',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: accentColor),
                tooltip: 'Clear all',
                onPressed: _wishlistIds.isEmpty ? null : () => _confirmClearAll(context, accentColor, cardColor, textColor),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withValues(alpha: 0.08), height: 1),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, productSnap) {
              // Also watch user wishlist
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                return _buildEmptyState(textColor, subTextColor, accentColor);
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('wishlist')
                    .snapshots(),
                builder: (context, wishSnap) {
                  if (wishSnap.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: accentColor));
                  }

                  final wishlistDocs = wishSnap.data?.docs ?? [];

                  if (wishlistDocs.isEmpty) {
                    return _buildEmptyState(textColor, subTextColor, accentColor);
                  }

                  // Get all products from wishlist
                  final allProducts = productSnap.data?.docs
                      .map((d) {
                        try {
                          return Product.fromFirestore(d);
                        } catch (_) {
                          return null;
                        }
                      })
                      .whereType<Product>()
                      .toList() ?? [];

                  final wishlistProductIds = wishlistDocs.map((d) => d.id).toSet();
                  final wishlistProducts = allProducts
                      .where((p) => wishlistProductIds.contains(p.id))
                      .toList();

                  // If Firestore products collection empty, show fallback items from wishlist metadata
                  final itemsToShow = wishlistProducts.isNotEmpty
                      ? wishlistProducts
                      : null;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${wishlistDocs.length} item${wishlistDocs.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: itemsToShow != null
                            ? _buildProductGrid(itemsToShow, wishlistDocs, textColor, cardColor, accentColor, subTextColor)
                            : _buildWishlistFallback(wishlistDocs, textColor, cardColor, accentColor, subTextColor),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(
    List<Product> products,
    List<QueryDocumentSnapshot> wishlistDocs,
    Color textColor,
    Color cardColor,
    Color accentColor,
    Color subTextColor,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, textColor, cardColor, accentColor, subTextColor);
      },
    );
  }

  Widget _buildProductCard(
    Product product,
    Color textColor,
    Color cardColor,
    Color accentColor,
    Color subTextColor,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(140, cardColor),
                        )
                      : _imageFallback(140, cardColor),
                ),
                // Remove from wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeFromWishlist(product.id ?? ''),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Discount badge
                if (product.discount != null && product.discount! > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discount!.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: subTextColor),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.location != null && product.location!.isNotEmpty
                              ? product.location!
                              : 'Official Store',
                          style: TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                            fontFamily: 'Montserrat',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 10, color: subTextColor),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          'Stock: ${product.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            color: subTextColor,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: accentColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (product.oldPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Rp ${product.oldPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: subTextColor,
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 11,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistFallback(
    List<QueryDocumentSnapshot> wishlistDocs,
    Color textColor,
    Color cardColor,
    Color accentColor,
    Color subTextColor,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: wishlistDocs.length,
      itemBuilder: (context, index) {
        final data = wishlistDocs[index].data() as Map<String, dynamic>? ?? {};
        final name = data['title'] as String? ?? 'Product';
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        final imageUrl = data['imageUrl'] as String? ?? '';

        final product = Product(
          id: wishlistDocs[index].id,
          title: name,
          description: data['description'] as String? ?? '',
          price: price,
          oldPrice: data['oldPrice'] != null ? (data['oldPrice'] as num).toDouble() : null,
          imageUrl: imageUrl,
          sellerId: data['sellerId'] as String?,
          sellerName: data['sellerName'] as String?,
          location: data['location'] as String?,
          stock: data['stock'] != null ? (data['stock'] as num).toInt() : 10,
        );

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(product: product)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback(140, cardColor),
                            )
                          : _imageFallback(140, cardColor),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeFromWishlist(wishlistDocs[index].id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(Icons.favorite_rounded, color: accentColor, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        price > 0 ? 'Rp ${price.toStringAsFixed(0)}' : 'Price TBD',
                        style: TextStyle(
                          color: accentColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageFallback(double height, Color cardColor) {
    return Container(
      height: height,
      width: double.infinity,
      color: cardColor,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save items you love by tapping the ♡ icon on any product.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontFamily: 'Montserrat',
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'Browse Products',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, Color accentColor, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Wishlist?',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          'This will remove all items from your wishlist. This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: textColor.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textColor, fontFamily: 'Montserrat')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              for (final id in List<String>.from(_wishlistIds)) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('wishlist')
                    .doc(id)
                    .delete();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Clear All', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
