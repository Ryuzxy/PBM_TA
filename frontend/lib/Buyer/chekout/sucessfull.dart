import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/theme_manager.dart';

class SuccessfulScreen extends StatefulWidget {
  final double orderAmount;
  final double shippingAmount;
  final double totalAmount;

  const SuccessfulScreen({
    super.key,
    this.orderAmount = 70000.0,
    this.shippingAmount = 15000.0,
    this.totalAmount = 85000.0,
  });

  @override
  State<SuccessfulScreen> createState() => _SuccessfulScreenState();
}

class _SuccessfulScreenState extends State<SuccessfulScreen> {
  String _deliveryAddress = '';
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
    _saveOrderToFirestore();
  }

  Future<void> _saveOrderToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final orderId = 'SD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        final deliveryHour = (DateTime.now().hour + 1) % 24;
        final estimatedTime = '${deliveryHour.toString().padLeft(2, '0')}:45';
        final estimatedDeliveryText = 'Today, $estimatedTime';

        // 1. Get the buyer's account details (for name, address, and coordinates)
        String buyerName = 'Customer';
        String buyerAddress = _deliveryAddress;
        double buyerLat = -6.2188; // Default fallback
        double buyerLng = 106.8456; // Default fallback
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          buyerName = userDoc.data()?['accountHolder'] as String? ?? 'Customer';
          buyerAddress = userDoc.data()?['address'] as String? ?? _deliveryAddress;
          buyerLat = (userDoc.data()?['lat'] as num?)?.toDouble() ?? buyerLat;
          buyerLng = (userDoc.data()?['lng'] as num?)?.toDouble() ?? buyerLng;
        }

        // 2. Fetch all items in the user's cart
        final cartSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

        final List<Map<String, dynamic>> itemsList = [];
        String? orderSellerId;
        
        for (var doc in cartSnap.docs) {
          final cartData = doc.data();
          final productId = cartData['productId'] as String?;
          final quantity = (cartData['quantity'] as num?)?.toInt() ?? 1;
          final title = cartData['title'] as String? ?? 'Product';
          final price = (cartData['price'] as num?)?.toDouble() ?? 0.0;
          final imageUrl = cartData['imageUrl'] as String? ?? '';
          final sellerId = cartData['sellerId'] as String?;

          if (sellerId != null && sellerId.isNotEmpty) {
            orderSellerId ??= sellerId;
          }
          itemsList.add({
            'productId': productId,
            'quantity': quantity,
            'title': title,
            'price': price,
            'imageUrl': imageUrl,
            'sellerId': sellerId,
          });

          // 3. Decrement product stock in products collection
          if (productId != null && productId.isNotEmpty) {
            final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
            final productSnap = await productRef.get();
            if (productSnap.exists && productSnap.data() != null) {
              final productData = productSnap.data()!;
              
              // Determine stock field name (default to 'stock' or 'quantity')
              final stockKey = productData.containsKey('stock')
                  ? 'stock'
                  : (productData.containsKey('quantity') ? 'quantity' : 'stock');
              
              final currentStock = productData[stockKey] as num?;
              if (currentStock != null) {
                final newStock = currentStock.toInt() - quantity;
                if (newStock <= 0) {
                  // Stock runs out, delete the product document
                  await productRef.delete();
                } else {
                  // Decrement stock
                  await productRef.update({stockKey: newStock});
                }
              }
            }
          }
        }
        // 4.5. Get seller storefront coordinates if available
        double sellerStoreLat = -6.2088; // Default fallback
        double sellerStoreLng = 106.8456; // Default fallback
        String sellerAddress = 'Official Store';
        if (orderSellerId != null && orderSellerId.isNotEmpty) {
          try {
            final sellerDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(orderSellerId)
                .get();
            if (sellerDoc.exists && sellerDoc.data() != null) {
              final sLat = (sellerDoc.data()?['lat'] as num?)?.toDouble();
              final sLng = (sellerDoc.data()?['lng'] as num?)?.toDouble();
              if (sLat != null && sLng != null) {
                sellerStoreLat = sLat;
                sellerStoreLng = sLng;
              }
              final sAddress = sellerDoc.data()?['address'] as String?;
              if (sAddress != null && sAddress.isNotEmpty) {
                sellerAddress = sAddress;
              }
            }
          } catch (e) {
            debugPrint('Error fetching seller coordinates: $e');
          }
        }

        // 4. Save to user's orders collection (nested)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .set({
          'orderId': orderId,
          'totalAmount': widget.totalAmount,
          'orderAmount': widget.orderAmount,
          'shippingAmount': widget.shippingAmount,
          'status': 2, // 2 represents In Transit
          'estimatedDelivery': estimatedDeliveryText,
          'createdAt': FieldValue.serverTimestamp(),
          'sellerId': orderSellerId,
          'buyerAddress': buyerAddress,
          'sellerAddress': sellerAddress,
        });

        // 5. Save to the new dedicated ROOT-LEVEL 'tracking' collection
        await FirebaseFirestore.instance
            .collection('tracking')
            .doc(orderId)
            .set({
          'orderId': orderId,
          'buyerId': user.uid,
          'buyerName': buyerName,
          'buyerAddress': buyerAddress,
          'totalAmount': widget.totalAmount,
          'orderAmount': widget.orderAmount,
          'shippingAmount': widget.shippingAmount,
          'status': 2, // 2 represents In Transit
          'estimatedDelivery': estimatedDeliveryText,
          'createdAt': FieldValue.serverTimestamp(),
          'items': itemsList,
          'storeLatitude': sellerStoreLat,
          'storeLongitude': sellerStoreLng,
          'sellerLatitude': sellerStoreLat,
          'sellerLongitude': sellerStoreLng,
          'buyerLatitude': buyerLat,
          'buyerLongitude': buyerLng,
          'sellerId': orderSellerId,
          'sellerAddress': sellerAddress,
        });

        // 6. Clear user's cart after successful checkout
        for (var doc in cartSnap.docs) {
          await doc.reference.delete();
        }

      } catch (e) {
        debugPrint('Error saving order and tracking data to Firestore: $e');
      }
    }
  }

  Future<void> _loadUserAddress() async {
    setState(() => _isLoadingAddress = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final address = doc.data()?['address'] as String?;
          if (address != null && address.isNotEmpty) {
            if (mounted) {
              setState(() {
                _deliveryAddress = address;
                _isLoadingAddress = false;
              });
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading address: $e');
      }
    }
    if (mounted) {
      setState(() {
        _deliveryAddress = 'Tap to choose your location';
        _isLoadingAddress = false;
      });
    }
  }

  void _showEditAddressDialog(BuildContext context, Color cardColor, Color textColor, Color accentColor) {
    final textController = TextEditingController(text: _deliveryAddress == 'Tap to choose your location' ? '' : _deliveryAddress);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Change Delivery Location',
            style: TextStyle(
              color: textColor,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: TextField(
            controller: textController,
            style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your delivery address...',
              hintStyle: TextStyle(color: textColor.withOpacity(0.5), fontFamily: 'Montserrat'),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: textColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newAddress = textController.text.trim();
                if (newAddress.isNotEmpty) {
                  setState(() {
                    _deliveryAddress = newAddress;
                  });
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'address': newAddress,
                      });
                    } catch (e) {
                      debugPrint('Error saving address to firestore: $e');
                    }
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
          body: Stack(
            children: [
              // 1. Background Content (Checkout summary & payment cards)
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // user interacts with overlay, not background
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Checkout',
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 16),

                          // Order Summary
                          _buildSummaryItem('Order', widget.orderAmount, subTextColor),
                          const SizedBox(height: 14),
                          _buildSummaryItem('Shipping', widget.shippingAmount, subTextColor),
                          const SizedBox(height: 14),
                          _buildSummaryItem('Total', widget.totalAmount, textColor, isTotal: true),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Divider(color: Color(0xFFC4C4C4), height: 1, thickness: 1),
                          ),

                          Text(
                            'Payment',
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Visa Card
                          _buildMockPaymentCard(
                            logoWidget: const Text(
                              'VISA',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 20,
                                color: Color(0xFF1A1F71),
                              ),
                            ),
                            cardNumber: '*********2109',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),

                          // PayPal Card
                          _buildMockPaymentCard(
                            logoWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Pay', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 18, color: Color(0xFF003087))),
                                Text('Pal', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 18, color: Color(0xFF0079C1))),
                              ],
                            ),
                            cardNumber: '*********2109',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),

                          // Apple Pay Card
                          _buildMockPaymentCard(
                            logoWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apple, color: textColor, size: 24),
                                const SizedBox(width: 4),
                                Text('Pay', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
                              ],
                            ),
                            cardNumber: '*********2109',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),

                          // COD
                          _buildMockPaymentCard(
                            logoWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.money, color: Colors.green, size: 24),
                                const SizedBox(width: 8),
                                Text('COD', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                              ],
                            ),
                            cardNumber: 'Cash on Delivery',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),

                          // QR Code
                          _buildMockPaymentCard(
                            logoWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 24),
                                const SizedBox(width: 8),
                                Text('QRIS', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                              ],
                            ),
                            cardNumber: 'Scan QR to Pay',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Dimmed Overlay (Figma Node 1:17679: bg-[#0d0b0b] opacity-60)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0D0B0B).withOpacity(0.60),
                ),
              ),

              // 3. Success Card & Location Verification Overlay
              Positioned.fill(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // A. SUCCESS CARD (331px wide, 201px high)
                          Container(
                            width: 331,
                            height: 201,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Wavy Circle Badge (91x91 at left 120, top 42)
                                Positioned(
                                  top: 36,
                                  left: 120, // (331 - 91) / 2
                                  child: SizedBox(
                                    width: 91,
                                    height: 91,
                                    child: CustomPaint(
                                      painter: ScallopedBadgePainter(color: const Color(0xFFF83758)),
                                      child: Center(
                                        child: Transform.rotate(
                                          angle: 4.93 * math.pi / 180,
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Floating Dots (matching Figma node offsets relative to card top-left)
                                _buildFloatingDot(size: 14, left: 218, top: 62, color: const Color(0xFFF83758)),
                                _buildFloatingDot(size: 14, left: 78, top: 37, color: const Color(0xFFF83758)),
                                _buildFloatingDot(size: 7, left: 168, top: 26, color: const Color(0xFFF83758)),
                                _buildFloatingDot(size: 11, left: 95, top: 117, color: const Color(0xFFF83758)),
                                _buildFloatingDot(size: 7, left: 92, top: 76, color: const Color(0xFFF83758)),
                                _buildFloatingDot(size: 7, left: 202, top: 106, color: const Color(0xFFF83758)),

                                // Status text (Montserrat SemiBold, size 14, top 149)
                                Positioned(
                                  top: 149,
                                  left: 0,
                                  right: 0,
                                  child: const Text(
                                    'Payment done successfully.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),



                          const SizedBox(height: 32),

                          // C. CONTINUE BUTTON (309px wide, 59px high, at the bottom)
                          SizedBox(
                            width: 309,
                            height: 59,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF83758),
                                disabledBackgroundColor: const Color(0xFFF83758).withOpacity(0.4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: -0.41,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        Text(
          'Rp ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontFamily: 'Montserrat',
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildMockPaymentCard({
    required Widget logoWidget,
    required String cardNumber,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      height: 59,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          logoWidget,
          Text(
            cardNumber,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDot({
    required double size,
    required double left,
    required double top,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Custom Painter for Scalloped Circle Badge ───────────────────────────────

class ScallopedBadgePainter extends CustomPainter {
  final Color color;

  ScallopedBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double baseRadius = (size.width / 2) - 4;
    final double waveAmplitude = 3.5;
    final int waveCount = 20;

    final Path path = Path();
    for (int i = 0; i <= 360; i++) {
      final double angle = i * math.pi / 180;
      final double r = baseRadius + waveAmplitude * math.sin(waveCount * angle);
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
