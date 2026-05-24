import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QRIS',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Kamera Scanner
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                // Mencegah scan berulang kali dalam 1 detik
                if (!_isScanned && barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  final String code = barcode.rawValue!;
                  
                  // Menutup halaman kamera dan membawa data teks hasil scan
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          // Overlay Kotak Pembidik (Opsional biar UI lebih cantik)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Arahkan kamera ke QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Montserrat'),
            ),
          ),
        ],
      ),
    );
  }
}