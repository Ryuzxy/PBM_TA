import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/theme_manager.dart';
import '../../Models/product.dart';
// import 'sucessfull.dart';
// import 'confirm.dart';
import '../dashboard/tracking.dart';
import '../dashboard/qr_scanner.dart';

class PaymentScreen extends StatefulWidget {
  final double orderAmount;
  final double shippingAmount;
  final double totalAmount;
  final String? sellerId;
  final Product? directProduct;
  final int? directQuantity;

  const PaymentScreen({
    super.key,
    this.orderAmount = 70000.0,
    this.shippingAmount = 15000.0,
    this.totalAmount = 85000.0,
    this.sellerId,
    this.directProduct,
    this.directQuantity,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'visa';
  bool _isProcessingPayment = false;

  // ── Logika Tombol Continue (Pengecekan Pembayaran) ───────────────────────
  Future<void> _handlePayment(Color accentColor, Color cardColor, Color textColor) async {
    // 1. JIKA COD (Langsung Sukses)
    if (_selectedMethod == 'cod') {
      final orderId = await _processOrderToDatabase(); // Panggil fungsi simpan database
      if (mounted && orderId != null) {
        _showSuccessDialog(context, accentColor, cardColor, textColor, orderId);
      }
      return;
    }

    // 2. JIKA QRIS (Buka Kamera Dulu, Baru Verifikasi)
    if (_selectedMethod == 'qris') {
      final scannedCode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );
      if (scannedCode == null) return; 
    }

    // 3. PROSES VERIFIKASI (Untuk QRIS dan Kartu Debit/Kredit)
    setState(() => _isProcessingPayment = true);
    
    // Pura-pura menghubungi backend server (Midtrans/dll) selama 3 detik
    await Future.delayed(const Duration(seconds: 3));

    // Simpan ke database setelah pembayaran berhasil
    final orderId = await _processOrderToDatabase();
    
    if (mounted) {
      setState(() => _isProcessingPayment = false);
      if (orderId != null) {
        _showSuccessDialog(context, accentColor, cardColor, textColor, orderId);
      }
    }
  }

  // --- FUNGSI BARU UNTUK MENYIMPAN DATA KE FIRESTORE ---
  Future<String?> _processOrderToDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Buat ID Pesanan unik (contoh: SD-84729)
    final String orderId = 'SD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      final deliveryHour = (DateTime.now().hour + 1) % 24;
      final estimatedTime = '${deliveryHour.toString().padLeft(2, '0')}:45';
      final estimatedDeliveryText = 'Today, $estimatedTime';

      // 1. Get the buyer's account details (for name, address, and coordinates)
      String buyerName = 'SmartDrop Customer';
      String buyerAddress = '';
      double buyerLat = -8.1718; // Default fallback
      double buyerLng = 113.7005; // Default fallback
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        buyerName = userDoc.data()?['accountHolder'] as String? ?? buyerName;
        buyerAddress = userDoc.data()?['address'] as String? ?? buyerAddress;
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
      String? orderSellerId = widget.sellerId;
      
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
            final stockKey = productData.containsKey('stock')
                ? 'stock'
                : (productData.containsKey('quantity') ? 'quantity' : 'stock');
            
            final currentStock = productData[stockKey] as num?;
            if (currentStock != null) {
              final newStock = (currentStock.toInt() - quantity).clamp(0, currentStock.toInt());
              await productRef.update({stockKey: newStock});
            }
          }
        }
      }

      // If cart is empty and direct product is provided (Buy Now flow)
      if (itemsList.isEmpty && widget.directProduct != null) {
        final product = widget.directProduct!;
        final qty = widget.directQuantity ?? 1;
        orderSellerId ??= product.sellerId;

        itemsList.add({
          'productId': product.id,
          'quantity': qty,
          'title': product.title,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'sellerId': product.sellerId,
        });

        // Decrement product stock in products collection
        if (product.id != null && product.id!.isNotEmpty) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(product.id);
          final productSnap = await productRef.get();
          if (productSnap.exists && productSnap.data() != null) {
            final productData = productSnap.data()!;
            final stockKey = productData.containsKey('stock')
                ? 'stock'
                : (productData.containsKey('quantity') ? 'quantity' : 'stock');
            
            final currentStock = productData[stockKey] as num?;
            if (currentStock != null) {
              final newStock = (currentStock.toInt() - qty).clamp(0, currentStock.toInt());
              await productRef.update({stockKey: newStock});
            }
          }
        }
      }

      // 4. Get seller storefront coordinates and address if available
      orderSellerId ??= user.uid;

      double sellerStoreLat = -8.1643; 
      double sellerStoreLng = 113.7169;
      String sellerAddress = 'Official Store';
      if (orderSellerId.isNotEmpty) {
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

      // 5. Simpan ke Riwayat Pesanan Pembeli (Muncul di My Orders)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set({
        'orderId': orderId,
        'status': 2, // 2 = In Transit (Langsung masuk tahap pengiriman)
        'totalAmount': widget.totalAmount,
        'estimatedDelivery': estimatedDeliveryText,
        'createdAt': FieldValue.serverTimestamp(),
        'sellerId': orderSellerId,
        'buyerAddress': buyerAddress,
        'sellerAddress': sellerAddress,
      });

      // 6. Simpan ke Sistem Tracking Global (Agar Seller Panel bisa mendeteksi)
      await FirebaseFirestore.instance.collection('tracking').doc(orderId).set({
        'orderId': orderId,
        'buyerId': user.uid,
        'buyerName': buyerName,
        'buyerAddress': buyerAddress,
        'sellerId': orderSellerId, 
        'status': 2,
        'totalAmount': widget.totalAmount,
        'storeLatitude': sellerStoreLat,
        'storeLongitude': sellerStoreLng,
        'buyerLatitude': buyerLat,
        'buyerLongitude': buyerLng,
        'sellerLatitude': sellerStoreLat, // Posisi awal kurir sama dengan lokasi toko
        'sellerLongitude': sellerStoreLng,
        'sellerAddress': sellerAddress,
        'items': itemsList,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 7. Clear user's cart after successful checkout
      for (var doc in cartSnap.docs) {
        await doc.reference.delete();
      }

      return orderId;
    } catch (e) {
      debugPrint('Gagal menyimpan pesanan: $e');
      return null;
    }
  }

  void _showSuccessDialog(BuildContext context, Color accentColor, Color cardColor, Color textColor, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.green.withOpacity(0.12),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order #$orderId has been placed successfully and is now in transit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // pop dialog
                    Navigator.pop(context); // pop payment screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackingScreen(
                          orderId: orderId,
                          totalAmount: widget.totalAmount,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining, color: Colors.white),
                  label: const Text(
                    'Track Live Delivery',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // pop dialog
                  Navigator.pop(context); // pop payment screen
                },
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
              'Checkout',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Divider(
                color: textColor.withOpacity(0.08),
                height: 1,
                thickness: 1,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary lines
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

                  // Visa
                  _buildPaymentCard(
                    id: 'visa',
                    logoWidget: _buildVisaLogo(),
                    cardNumber: '*********2109',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // PayPal
                  _buildPaymentCard(
                    id: 'paypal',
                    logoWidget: _buildPayPalLogo(),
                    cardNumber: '*********2109',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // Maestro
                  _buildPaymentCard(
                    id: 'maestro',
                    logoWidget: _buildMaestroLogo(),
                    cardNumber: '*********2109',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // Apple Pay
                  _buildPaymentCard(
                    id: 'apple',
                    logoWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple, color: textColor, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          'Pay',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    cardNumber: '*********2109',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // COD
                  _buildPaymentCard(
                    id: 'cod',
                    logoWidget: _buildCODLogo(textColor),
                    cardNumber: 'Cash on Delivery',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 16),

                  // QR Code
                  _buildPaymentCard(
                    id: 'qris',
                    logoWidget: _buildQRLogo(textColor),
                    cardNumber: 'Scan QR to Pay',
                    accentColor: accentColor,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  
                  const SizedBox(height: 48),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 59,
                    child: ElevatedButton(
                      onPressed: _isProcessingPayment 
                          ? null 
                          : () => _handlePayment(accentColor, cardColor, textColor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessingPayment
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: -0.41,
                              ),
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

  Widget _buildSummaryItem(String title, double amount, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontFamily: 'Montserrat',
            fontWeight: isTotal ? FontWeight.w500 : FontWeight.w500,
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

  Widget _buildPaymentCard({
    required String id,
    required Widget logoWidget,
    required String cardNumber,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 59,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
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
      ),
    );
  }

  Widget _buildVisaLogo() {
    return const Text(
      'VISA',
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: 20,
        color: Color(0xFF1A1F71),
      ),
    );
  }

  Widget _buildPayPalLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Pay',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 18,
            color: Color(0xFF003087),
          ),
        ),
        Text(
          'Pal',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 18,
            color: Color(0xFF0079C1),
          ),
        ),
      ],
    );
  }

  Widget _buildMaestroLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
            Positioned(
              left: 10,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A2E8).withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        const Text(
          'maestro',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCODLogo(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.money, color: Colors.green, size: 24),
        const SizedBox(width: 8),
        Text(
          'COD',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ],
    );
  }
  Widget _buildQRLogo(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 24),
        const SizedBox(width: 8),
        Text(
          'QRIS',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
