import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/theme_manager.dart';
import 'sucessfull.dart';

class ConfirmScreen extends StatefulWidget {
  final double orderAmount;
  final double shippingAmount;
  final double totalAmount;

  const ConfirmScreen({
    super.key,
    required this.orderAmount,
    required this.shippingAmount,
    required this.totalAmount,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  
  Timer? _countdownTimer;
  int _secondsRemaining = 300; // 5 minutes
  bool _isVerifying = false;
  late String _transactionId;

  // Location Verification State variables
  String _deliveryAddress = '';
  bool _isLoadingAddress = true;
  bool _isLocationConfirmed = false;

  @override
  void initState() {
    super.initState();
    
    // Generate a random-looking transaction ID
    final now = DateTime.now();
    _transactionId = 'TXN${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecond}${now.microsecond.toString().substring(0, 3)}';

    // Scanner animation: moves scanning line up and down
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _scanController.repeat(reverse: true);

    // Start 5 minute countdown
    _startCountdown();

    // Load Delivery Address
    _loadUserAddress();
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

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _countdownTimer?.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Payment Session Expired',
            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'The QR code has expired. Please try checking out again.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop confirm screen back to payment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF83758),
              ),
              child: const Text('Back to Checkout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _simulateVerification(Color accentColor) async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
    });

    // Simulate network delay to verify payment status
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
      
      // Go to successful screen, replace current route so back button works correctly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessfulScreen(
            orderAmount: widget.orderAmount,
            shippingAmount: widget.shippingAmount,
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
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
              'QR Payment',
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Amount banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Amount to Pay',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.currency_rupee,
                              size: 24,
                              color: textColor,
                            ),
                            Text(
                              widget.totalAmount.toStringAsFixed(0),
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code Box Container
                  Text(
                    'Scan the QR Code to pay',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compatible with Google Pay, PhonePe, Paytm, etc.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulated QR Scanner Graphic
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Stylized QR Box
                        Container(
                          width: 240,
                          height: 240,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.08),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Grid background mockup or stylized QR Icon
                              Center(
                                child: Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 200,
                                  color: const Color(0xFF222222),
                                ),
                              ),
                              // Custom Animated Scanning Line
                              AnimatedBuilder(
                                animation: _scanAnimation,
                                builder: (context, child) {
                                  // Top offset: from 0 to container height minus scan line height
                                  final double topOffset = _scanAnimation.value * 200;
                                  return Positioned(
                                    top: topOffset,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentColor.withOpacity(0.8),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Corner borders to make it look like scanner bounds
                        _buildScannerCorner(top: -4, left: -4, isTop: true, isLeft: true, color: accentColor),
                        _buildScannerCorner(top: -4, right: -4, isTop: true, isLeft: false, color: accentColor),
                        _buildScannerCorner(bottom: -4, left: -4, isTop: false, isLeft: true, color: accentColor),
                        _buildScannerCorner(bottom: -4, right: -4, isTop: false, isLeft: false, color: accentColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Expiry timer countdown
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Expires in ${_formatDuration(_secondsRemaining)}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction Reference ID
                  Text(
                    'Transaction ID:',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _transactionId,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          // Simple visual copy confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction ID copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Icon(Icons.copy, size: 16, color: accentColor),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // B. LOCATION VERIFICATION CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: accentColor, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Delivery Location',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => _showEditAddressDialog(context, cardColor, textColor, accentColor),
                              icon: Icon(Icons.edit, size: 14, color: accentColor),
                              label: Text(
                                'Change',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: accentColor,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isLoadingAddress
                              ? 'Loading your address...'
                              : _deliveryAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: subTextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, thickness: 0.5, color: textColor.withOpacity(0.1)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isLocationConfirmed = !_isLocationConfirmed;
                            });
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _isLocationConfirmed,
                                  activeColor: accentColor,
                                  onChanged: (val) {
                                    setState(() {
                                      _isLocationConfirmed = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Confirm this location is correct',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Primary Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 59,
                    child: ElevatedButton(
                      onPressed: (_isVerifying || !_isLocationConfirmed) ? null : () => _simulateVerification(accentColor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        disabledBackgroundColor: accentColor.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Verify Payment Status',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: -0.41,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cancel / Back Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: subTextColor,
                    ),
                    child: const Text(
                      'Cancel Payment',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
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

  Widget _buildScannerCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
    required Color color,
  }) {
    const double length = 20.0;
    const double thickness = 4.0;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: length + 8,
        height: length + 8,
        alignment: Alignment(
          isLeft ? -1.0 : 1.0,
          isTop ? -1.0 : 1.0,
        ),
        child: Container(
          width: length,
          height: length,
          decoration: BoxDecoration(
            border: Border(
              top: isTop ? BorderSide(color: color, width: thickness) : BorderSide.none,
              bottom: !isTop ? BorderSide(color: color, width: thickness) : BorderSide.none,
              left: isLeft ? BorderSide(color: color, width: thickness) : BorderSide.none,
              right: !isLeft ? BorderSide(color: color, width: thickness) : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
