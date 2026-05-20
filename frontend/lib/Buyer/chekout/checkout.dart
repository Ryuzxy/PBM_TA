import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Credit Card';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Order', '\$ 79.00'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Delivery', '\$ 5.00'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Tax', '\$ 2.50'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, color: Colors.grey),
                    ),
                    _buildSummaryRow('Total', '\$ 86.50', isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildPaymentOption(
                title: 'Credit / Debit Card',
                icon: Icons.credit_card,
                value: 'Credit Card',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                title: 'PayPal',
                icon: Icons.account_balance_wallet,
                value: 'PayPal',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                title: 'Cash on Delivery',
                icon: Icons.money,
                value: 'COD',
              ),
              const SizedBox(height: 24),

              // Promo Code
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter Promo Code',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: TextButton(
                      onPressed: () {},
                      child: const Text('Apply', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // Handle Payment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Processing Payment...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Pay Now (\$ 86.50)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey.shade600,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: Colors.black,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({required String title, required IconData icon, required String value}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPaymentMethod == value ? Colors.pink : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (_selectedPaymentMethod != value)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: Colors.pink,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
