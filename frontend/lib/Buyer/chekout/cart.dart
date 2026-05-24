import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../Services/theme_manager.dart';
import 'payment.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // User data
  String _userName = '';
  String _userEmail = '';
  String _deliveryAddress = 'Tap to choose your location';
  LatLng? _selectedLatLng;
  bool _isLoadingUser = true;

  // Cart items
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoadingCart = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCartItems();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }
    setState(() {
      _userEmail = user.email ?? '';
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _userName = doc.data()?['accountHolder'] ?? '';
          _deliveryAddress =
              doc.data()?['address'] ?? 'Tap to choose your location';
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingCart = false);
      return;
    }
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots()
          .listen((snap) {
        if (mounted) {
          setState(() {
            _cartItems = snap.docs.map((d) {
              final data = d.data();
              data['cartDocId'] = d.id;
              return data;
            }).toList();
            _isLoadingCart = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading cart: $e');
      setState(() => _isLoadingCart = false);
    }
  }

  Future<void> _removeCartItem(String cartDocId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(cartDocId)
        .delete();
  }

  Future<void> _updateQuantity(String cartDocId, int delta, int currentQty) async {
    final newQty = currentQty + delta;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (newQty <= 0) {
      await _removeCartItem(cartDocId);
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(cartDocId)
        .update({'quantity': newQty});
  }

  double get _totalPrice {
    return _cartItems.fold(0.0, (sum, item) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      return sum + (price * qty);
    });
  }

  Future<void> _openLocationPicker(BuildContext context, Color accentColor, Color bgColor, Color textColor) async {
    // Ask permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is permanently denied. Please enable it in Settings.')),
        );
      }
      return;
    }

    LatLng initialPos = const LatLng(-6.2088, 106.8456); // Jakarta default
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      initialPos = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    if (!context.mounted) return;

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(
          initialPosition: _selectedLatLng ?? initialPos,
          accentColor: accentColor,
          bgColor: bgColor,
          textColor: textColor,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLatLng = result;
        _deliveryAddress = 'Memuat alamat...';
      });
      // Reverse geocode
      try {
        final placemarks = await placemarkFromCoordinates(result.latitude, result.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = [
            p.street,
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
            p.administrativeArea,
            p.postalCode,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          setState(() => _deliveryAddress = address);
          // Save to Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'address': address,
              'lat': result.latitude,
              'lng': result.longitude,
            });
          }
        }
      } catch (e) {
        setState(() => _deliveryAddress =
            '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}');
      }
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
              'My Cart',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withValues(alpha: 0.08), height: 1),
            ),
          ),
          body: _isLoadingCart
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : _cartItems.isEmpty
                  ? _buildEmptyCart(textColor, subTextColor, accentColor)
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Delivery Address ──────────────────────────
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                color: textColor,
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _openLocationPicker(context, accentColor, bgColor, textColor),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedLatLng != null
                                        ? accentColor.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.location_on, color: accentColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (_userName.isNotEmpty) ...[
                                            Text(
                                              _userName,
                                              style: TextStyle(
                                                color: textColor,
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                          ],
                                          if (_userEmail.isNotEmpty) ...[
                                            Text(
                                              _userEmail,
                                              style: TextStyle(
                                                color: subTextColor,
                                                fontFamily: 'Montserrat',
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          Text(
                                            _deliveryAddress,
                                            style: TextStyle(
                                              color: _deliveryAddress == 'Tap to choose your location'
                                                  ? subTextColor
                                                  : textColor,
                                              fontFamily: 'Montserrat',
                                              fontSize: 13,
                                              fontStyle: _deliveryAddress == 'Tap to choose your location'
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_location_alt_outlined,
                                      color: accentColor,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Shopping List ─────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Shopping List',
                                  style: TextStyle(
                                    color: textColor,
                                    fontFamily: 'Montserrat',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_cartItems.length} item${_cartItems.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: _cartItems.map((item) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildCartItem(item, textColor, cardColor, accentColor, subTextColor),
                                ),
                              ).toList(),
                            ),
                            const SizedBox(height: 60), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),
          bottomNavigationBar: _cartItems.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Text(
                              '₹${_totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _deliveryAddress == 'Tap to choose your location'
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        orderAmount: _totalPrice,
                                        shippingAmount: 30.0,
                                        totalAmount: _totalPrice + 30.0,
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor: accentColor.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Place Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              fontSize: 15,
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

  Widget _buildCartItem(
    Map<String, dynamic> item,
    Color textColor,
    Color cardColor,
    Color accentColor,
    Color subTextColor,
  ) {
    final title = item['title'] as String? ?? 'Product';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = item['imageUrl'] as String? ?? '';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final oldPrice = (item['oldPrice'] as num?)?.toDouble();
    final cartDocId = item['cartDocId'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(cardColor),
                  )
                : _imageFallback(cardColor),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeCartItem(cartDocId),
                      child: Icon(Icons.close, color: subTextColor, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: accentColor,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (oldPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${oldPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: subTextColor,
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Quantity control
                Row(
                  children: [
                    _qtyButton(
                      icon: Icons.remove,
                      onTap: () => _updateQuantity(cartDocId, -1, qty),
                      accentColor: accentColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$qty',
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _qtyButton(
                      icon: Icons.add,
                      onTap: () => _updateQuantity(cartDocId, 1, qty),
                      accentColor: accentColor,
                    ),
                    const Spacer(),
                    Text(
                      'Subtotal: ₹${(price * qty).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: subTextColor,
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap, required Color accentColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: accentColor, size: 16),
      ),
    );
  }

  Widget _imageFallback(Color cardColor) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildEmptyCart(Color textColor, Color subTextColor, Color accentColor) {
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
              child: Icon(Icons.shopping_cart_outlined, size: 56, color: accentColor),
            ),
            const SizedBox(height: 28),
            Text(
              'Your cart is empty',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add products to cart by tapping 🛒 on any product.',
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
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 14),
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
}

// ─── Map Picker Screen ─────────────────────────────────────────────────────────

class _MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;
  final Color accentColor;
  final Color bgColor;
  final Color textColor;

  const _MapPickerScreen({
    required this.initialPosition,
    required this.accentColor,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  late LatLng _pickedLocation;
  final MapController _mapController = MapController();
  StreamSubscription<MapEvent>? _mapEventSubscription;
  String _previewAddress = 'Move map to pick location';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialPosition;
    _reverseGeocode(_pickedLocation);
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd) {
        _reverseGeocode(_pickedLocation);
      }
    });
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final address = [p.street, p.subLocality, p.locality, p.administrativeArea]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        setState(() => _previewAddress = address.isEmpty ? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}' : address);
      }
    } catch (_) {
      setState(() => _previewAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}');
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: widget.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Location',
          style: TextStyle(
            color: widget.textColor,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPosition,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                _pickedLocation = position.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.frontend',
              ),
            ],
          ),
          // Center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, color: Colors.red, size: 48),
            ),
          ),
          // Floating action button for current location
          Positioned(
            bottom: 140,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                  );
                  final target = LatLng(pos.latitude, pos.longitude);
                  _mapController.move(target, 15);
                  _pickedLocation = target;
                  _reverseGeocode(_pickedLocation);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to get current location.')),
                    );
                  }
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          // Bottom address bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: widget.bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: widget.accentColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoadingAddress
                            ? Text(
                                'Loading address...',
                                style: TextStyle(
                                  color: widget.textColor.withValues(alpha: 0.5),
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                _previewAddress,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _pickedLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Use This Location',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
