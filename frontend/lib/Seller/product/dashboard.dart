import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Models/product.dart';
import '../../Services/firestore_service.dart';
import '../../Services/theme_manager.dart';
import 'add.dart';
import 'update.dart';
import 'delete.dart';

class ProductDashboard extends StatefulWidget {
  const ProductDashboard({super.key});

  @override
  State<ProductDashboard> createState() => _ProductDashboardState();
}

class _ProductDashboardState extends State<ProductDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _safeImage({
    required String url,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    Color? bgColor,
    IconData icon = Icons.image_outlined,
  }) {
    final bg = bgColor ?? Colors.grey.shade200;
    final fallback = Container(
      height: height,
      width: width,
      color: bg,
      child: Center(
        child: Icon(icon, color: Colors.grey.shade400, size: 24),
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width,
          color: bg,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
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
              'Manage Products',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withOpacity(0.08), height: 1),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: accentColor,
            elevation: 4,
            tooltip: 'Add New Product',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: textColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products by title...',
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        color: subTextColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search, color: subTextColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: subTextColor),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Product Stream List
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: _firestoreService.getProductsBySeller(
                    FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: accentColor));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading products',
                          style: TextStyle(fontFamily: 'Montserrat', color: textColor),
                        ),
                      );
                    }
                    final products = snapshot.data ?? [];
                    final filteredProducts = products.where((p) {
                      return p.title.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2_outlined, size: 48, color: accentColor),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchQuery.isNotEmpty ? 'No Matching Products' : 'No Products Found',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try adjusting your search filters or clear the query.'
                                    : 'Get started by creating a new product using the floating plus button.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: subTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: cardColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: textColor.withOpacity(0.06),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _safeImage(
                                    url: product.imageUrl,
                                    width: 80,
                                    height: 80,
                                    bgColor: bgColor,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.description,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          color: subTextColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'Rp ${product.price.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: accentColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (product.oldPrice != null) ...[
                                            Text(
                                              'Rp ${product.oldPrice!.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 11,
                                                color: subTextColor,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            if (product.discount != null && product.discount! > 0)
                                              Text(
                                                '${product.discount!.toStringAsFixed(0)}% off',
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 12, color: subTextColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Stock: ${product.stock}',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Actions (Edit / Delete)
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: accentColor, size: 22),
                                      tooltip: 'Edit',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UpdateProductScreen(product: product),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                      tooltip: 'Delete',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DeleteProductScreen(product: product),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
