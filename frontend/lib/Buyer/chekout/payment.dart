import 'package:flutter/material.dart';
import '../../Services/theme_manager.dart';
import 'sucessfull.dart';
import 'confirm.dart';

class PaymentScreen extends StatefulWidget {
  final double orderAmount;
  final double shippingAmount;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    this.orderAmount = 7000.0,
    this.shippingAmount = 30.0,
    this.totalAmount = 7030.0,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'visa';

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
                    id: 'qr',
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
                      onPressed: () {
                        if (_selectedMethod == 'qr') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConfirmScreen(
                                orderAmount: widget.orderAmount,
                                shippingAmount: widget.shippingAmount,
                                totalAmount: widget.totalAmount,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
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
        Row(
          children: [
            Icon(
              Icons.currency_rupee,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 2),
            Text(
              amount.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontFamily: 'Montserrat',
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ],
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
          'QR Code / UPI',
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
