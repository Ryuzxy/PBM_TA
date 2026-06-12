import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Models/product.dart';
import '../../Services/theme_manager.dart';
import '../chekout/cart.dart';
import '../chekout/payment.dart';

class ItemDetailScreen extends StatefulWidget {
  final Product product;

  const ItemDetailScreen({super.key, required this.product});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _selectedImageIndex = 0;
  String? _selectedSize;
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isAddingToCart = false;
  String _sellerLocation = 'Official Store';

  final List<String> _availableSizes = ['6 UK', '7 UK', '8 UK', '9 UK', '10 UK', '11 UK'];

  @override
  void initState() {
    super.initState();
    _sellerLocation = (widget.product.location != null && widget.product.location!.isNotEmpty)
        ? widget.product.location!
        : 'Official Store';
    _checkWishlistStatus();
    _loadSellerLocation();
  }

  Future<void> _loadSellerLocation() async {
    final sellerId = widget.product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final city = data['city'] as String? ?? '';
          final state = data['state'] as String? ?? '';
          if (city.isNotEmpty) {
            setState(() {
              _sellerLocation = city;
              if (state.isNotEmpty) {
                _sellerLocation = '$city, $state';
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading seller location: $e');
      }
    }
  }

  Future<void> _checkWishlistStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.product.id == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(widget.product.id)
        .get();
    if (mounted) setState(() => _isWishlisted = doc.exists);
  }

  Future<void> _toggleWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.product.id == null) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(widget.product.id);

    setState(() => _isWishlisted = !_isWishlisted);
    if (_isWishlisted) {
      await ref.set({
        'title': widget.product.title,
        'price': widget.product.price,
        'imageUrl': widget.product.imageUrl,
        'oldPrice': widget.product.oldPrice,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  Future<void> _addToCart(BuildContext context, Color accentColor) async {
    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produk ini sudah habis (Sold Out)'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items to cart')),
      );
      return;
    }
    setState(() => _isAddingToCart = true);
    try {
      // Check if product already in cart
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .where('productId', isEqualTo: widget.product.id)
          .get();

      if (existing.docs.isNotEmpty) {
        // Increment quantity
        final currentQty = (existing.docs.first.data()['quantity'] as num?)?.toInt() ?? 1;
        await existing.docs.first.reference.update({'quantity': currentQty + _quantity});
      } else {
        // Add new cart item
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .add({
          'productId': widget.product.id,
          'title': widget.product.title,
          'price': widget.product.price,
          'imageUrl': widget.product.imageUrl,
          'oldPrice': widget.product.oldPrice,
          'size': _selectedSize,
          'quantity': _quantity,
          'addedAt': FieldValue.serverTimestamp(),
          'sellerId': widget.product.sellerId,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.title} added to cart!'),
            backgroundColor: accentColor,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _goToPayment(BuildContext context) {
    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produk ini sudah habis (Sold Out)'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final total = widget.product.price * _quantity;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          orderAmount: total,
          shippingAmount: 15000.0,
          totalAmount: total + 15000.0,
          sellerId: widget.product.sellerId,
          directProduct: widget.product,
          directQuantity: _quantity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        final bgColor = theme.bgColor;
        final textColor = theme.textColor;
        final cardColor = theme.cardColor;
        final accentColor = theme.accentColor;
        final subTextColor = theme.subTextColor;

        // Build image list — use product's main image + placeholders for carousel
        final images = widget.product.imageUrl.isNotEmpty
            ? [widget.product.imageUrl]
            : <String>[];

        return Scaffold(
          backgroundColor: bgColor,
          body: CustomScrollView(
            slivers: [
              // ── Image Hero + AppBar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: bgColor,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 18),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: _toggleWishlist,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            key: ValueKey(_isWishlisted),
                            color: _isWishlisted ? accentColor : textColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Product image
                      images.isNotEmpty
                          ? PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) =>
                                  setState(() => _selectedImageIndex = i),
                              itemBuilder: (_, i) => _buildProductImage(images[i], cardColor),
                            )
                          : _buildProductImage('', cardColor),
                      // SOLD OUT overlay
                      if (widget.product.stock <= 0)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'SOLD OUT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Dot indicators
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _selectedImageIndex == i ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _selectedImageIndex == i ? accentColor : Colors.white60,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Discount badge
                      if (widget.product.discount != null && widget.product.discount! > 0)
                        Positioned(
                          top: 60,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${widget.product.discount!.toInt()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Product Details ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row & price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.title,
                                    style: TextStyle(
                                      color: textColor,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.storefront_outlined, size: 14, color: accentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Seller: ${widget.product.sellerName ?? 'Official Seller'}',
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: accentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Lokasi: $_sellerLocation',
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 14, color: widget.product.stock <= 0 ? Colors.red : accentColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.product.stock <= 0
                                            ? 'Stok Habis (Sold Out)'
                                            : 'Stok Tersedia: ${widget.product.stock}',
                                        style: TextStyle(
                                          color: widget.product.stock <= 0 ? Colors.red : subTextColor,
                                          fontFamily: 'Montserrat',
                                          fontWeight: widget.product.stock <= 0 ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.product.description.isNotEmpty
                                        ? widget.product.description
                                        : 'Vision Alta Men\'s Shoes Size (All Colours)',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price row
                        Row(
                          children: [
                            Text(
                              'Rp ${widget.product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: accentColor,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                            if (widget.product.oldPrice != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                'Rp ${widget.product.oldPrice!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Rating & reviews
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              final rating = widget.product.rating;
                              if (i < rating.floor()) {
                                return const Icon(Icons.star_rounded, color: Colors.amber, size: 18);
                              } else if (i < rating) {
                                return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 18);
                              }
                              return Icon(Icons.star_outline_rounded, color: Colors.amber.withValues(alpha: 0.4), size: 18);
                            }),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.product.rating.toStringAsFixed(1)} (${widget.product.reviews} reviews)',
                              style: TextStyle(
                                color: subTextColor,
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Divider(color: textColor.withValues(alpha: 0.08)),
                        const SizedBox(height: 20),

                        // Size selector
                        Text(
                          'Size: ${_selectedSize ?? 'Choose a size'}',
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _availableSizes.map((size) {
                            final isSelected = _selectedSize == size;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = size),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected ? accentColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? accentColor : accentColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : accentColor,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),
                        Divider(color: textColor.withValues(alpha: 0.08)),
                        const SizedBox(height: 20),

                        // Quantity selector
                        Row(
                          children: [
                            Text(
                              'Quantity',
                              style: TextStyle(
                                color: textColor,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            _qtyButton(Icons.remove, () {
                              if (_quantity > 1) setState(() => _quantity--);
                            }, cardColor, accentColor),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '$_quantity',
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _qtyButton(Icons.add, () {
                              if (widget.product.stock > 0 && _quantity < widget.product.stock) {
                                setState(() => _quantity++);
                              }
                            }, cardColor, accentColor),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Divider(color: textColor.withValues(alpha: 0.08)),
                        const SizedBox(height: 20),

                        // Product details section
                        Text(
                          'Product Details',
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.product.description.isNotEmpty
                              ? widget.product.description
                              : 'Experience unmatched comfort and style with this premium product. Designed for everyday use, this item combines high-quality materials with a modern aesthetic. Perfect for various occasions, making it a versatile addition to your collection.',
                          style: TextStyle(
                            color: subTextColor,
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Action Buttons ──────────────────────────────────────
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Add to Cart
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.product.stock <= 0
                          ? null
                          : (_isAddingToCart
                              ? null
                              : () => _addToCart(context, accentColor)),
                      icon: widget.product.stock <= 0
                          ? Icon(Icons.block, size: 18, color: Colors.grey.shade400)
                          : (_isAddingToCart
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                                )
                              : Icon(Icons.shopping_cart_outlined, size: 18, color: accentColor)),
                      label: Text(
                        widget.product.stock <= 0 ? 'Sold Out' : 'Add to Cart',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: widget.product.stock <= 0 ? Colors.grey.shade400 : accentColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: widget.product.stock <= 0 ? Colors.grey.shade300 : accentColor,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Buy Now / Go Shop Now
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.product.stock <= 0
                          ? null
                          : () => _goToPayment(context),
                      icon: Icon(
                        widget.product.stock <= 0 ? Icons.block : Icons.flash_on_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        widget.product.stock <= 0 ? 'Sold Out' : 'Go Shop Now',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.product.stock <= 0 ? Colors.grey : accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String url, Color cardColor) {
    return url.isNotEmpty
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(cardColor),
          )
        : _imagePlaceholder(cardColor);
  }

  Widget _imagePlaceholder(Color cardColor) {
    return Container(
      color: cardColor,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 80),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap, Color cardColor, Color accentColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accentColor, size: 18),
      ),
    );
  }
}
