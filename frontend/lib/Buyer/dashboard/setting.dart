import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Services/theme_manager.dart';
import 'profile.dart';
import '../../Splash/splash_1.dart'; 
import 'qr_scanner.dart';
import 'tracking.dart';
import 'my_orders.dart';
import '../../Seller/dashboard.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isLoading = true;
  String _userName = 'User';
  String _userEmail = '';
  String _userPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          if (mounted) {
            setState(() {
              String fetchedName = doc.data()?['accountHolder'] ?? '';
              _userName = fetchedName.trim().isEmpty ? 'User' : fetchedName;
              _userPhotoUrl = doc.data()?['photoUrl'] ?? '';
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user data in settings: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI LOGOUT & SWITCH ACCOUNT ---
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Mengarahkan kembali ke SplashScreen / Login dan menghapus history routing
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen1()),
        (route) => false,
      );
    }
  }

  void _showSwitchAccountDialog(Color cardColor, Color textColor, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Switch Account', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: textColor)),
        content: Text(
          'You need to log out first to switch to another account. Do you want to log out now?',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: textColor.withOpacity(0.8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textColor, fontFamily: 'Montserrat')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI DUMMY UNTUK SCAN QR ---
  Future<void> _openQRScanner() async {
    final scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    // Jika user berhasil scan (tidak menekan tombol back/cancel)
    if (scannedCode != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil Scan: $scannedCode'),
          backgroundColor: ThemeManager.currentTheme.value.accentColor,
          duration: const Duration(seconds: 4),
        ),
      );
      // Nanti di sini kita akan melempar kode QR tersebut ke Backend Go
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Ordered';
      case 1: return 'Shipped';
      case 2: return 'In Transit';
      case 3: return 'Delivered';
      default: return 'Processing';
    }
  }

  void _showThemeSelectionBottomSheet(
    BuildContext context,
    AppTheme currentTheme,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customize Background',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a background theme preset:',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ThemeManager.themes.map((theme) {
                  final isSelected = theme.name == currentTheme.name;
                  return GestureDetector(
                    onTap: () {
                      ThemeManager.changeTheme(theme.name);
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.bgColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.accentColor : Colors.grey[300]!,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: theme.textColor, size: 20)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
              'Settings',
              style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.palette_outlined, color: textColor),
                onPressed: () => _showThemeSelectionBottomSheet(context, currentTheme, cardColor, textColor, subTextColor, accentColor),
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: Profile ──────────────────────────────────────────
                      _buildSectionHeader('Profile', textColor),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _boxStyle(cardColor),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accentColor, width: 2),
                                color: Colors.grey[200],
                                image: _userPhotoUrl.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(_userPhotoUrl), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: _userPhotoUrl.isEmpty ? const Center(child: Icon(Icons.person, color: Colors.grey, size: 30)) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_userName, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                                  const SizedBox(height: 4),
                                  Text(_userEmail, style: TextStyle(color: subTextColor.withOpacity(0.8), fontSize: 12, fontFamily: 'Montserrat')),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: accentColor),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                ).then((_) => _loadUserData());
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Section 2: Payment Methods (NEW) ──────────────────────────
                      _buildSectionHeader('Payment Methods', textColor),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _boxStyle(cardColor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kartu Placeholder
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [accentColor.withOpacity(0.8), accentColor]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Visa Debit Card', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontSize: 12)),
                                      SizedBox(height: 8),
                                      Text('**** **** **** 1234', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                                    ],
                                  ),
                                  Icon(Icons.credit_card, color: Colors.white.withOpacity(0.5), size: 36),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Tombol Aksi Pembayaran
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: Icon(Icons.add_card_rounded, size: 16, color: accentColor),
                                    label: Text('Add Card', style: TextStyle(color: accentColor, fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: accentColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openQRScanner,
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                                    label: const Text('QRIS Scan', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Section 3: Package Tracking ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('Package Tracking', textColor),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (user != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders').orderBy('createdAt', descending: true).limit(1).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: accentColor));
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: _boxStyle(cardColor), child: Text("Belum ada pesanan aktif saat ini.", style: TextStyle(color: subTextColor, fontFamily: 'Montserrat')));
                            }
                            final orderData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                            final orderId = orderData['orderId'] ?? 'SD-UNKNOWN';
                            final estimatedDelivery = orderData['estimatedDelivery'] ?? 'Estimating...';
                            final int currentStatus = orderData['status'] ?? 0;
                            final statusText = _getStatusText(currentStatus);

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: _boxStyle(cardColor),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Order #$orderId', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Montserrat')),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                        child: Text(statusText, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Montserrat')),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Estimated Delivery: $estimatedDelivery', style: TextStyle(color: subTextColor, fontSize: 12, fontFamily: 'Montserrat')),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      _buildTrackerStep('Ordered', currentStatus >= 0, accentColor, textColor, isActive: currentStatus == 0),
                                      _buildTrackerLine(currentStatus >= 1, currentStatus >= 1 ? accentColor : Colors.grey),
                                      _buildTrackerStep('Shipped', currentStatus >= 1, accentColor, textColor, isActive: currentStatus == 1),
                                      _buildTrackerLine(currentStatus >= 2, currentStatus >= 2 ? accentColor : Colors.grey),
                                      _buildTrackerStep('In Transit', currentStatus >= 2, accentColor, textColor, isActive: currentStatus == 2),
                                      _buildTrackerLine(currentStatus >= 3, currentStatus >= 3 ? accentColor : Colors.grey),
                                      _buildTrackerStep('Delivered', currentStatus >= 3, accentColor, textColor, isActive: currentStatus == 3),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TrackingScreen(
                                              totalAmount: (orderData['totalAmount'] as num?)?.toDouble() ?? 7030.0,
                                              orderId: orderId,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.map_rounded, size: 16, color: Colors.white),
                                      label: const Text('Track Live Delivery', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),

                      // ── Section 4: Account Management (NEW) ────────────────────────
                      _buildSectionHeader('Account Management', textColor),
                      Container(
                        width: double.infinity,
                        decoration: _boxStyle(cardColor),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.palette_outlined, color: textColor),
                              title: Text('Customize Theme', style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
                              onTap: () => _showThemeSelectionBottomSheet(context, currentTheme, cardColor, textColor, subTextColor, accentColor),
                            ),
                            Divider(height: 1, color: subTextColor.withOpacity(0.1)),
                            ListTile(
                              leading: Icon(Icons.swap_horiz_rounded, color: textColor),
                              title: Text('Switch Account', style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
                              onTap: () => _showSwitchAccountDialog(cardColor, textColor, accentColor),
                            ),
                            Divider(height: 1, color: subTextColor.withOpacity(0.1)),
                            ListTile(
                              leading: Icon(Icons.storefront_outlined, color: textColor),
                              title: Text('Seller Panel', style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SellerDashboard()),
                                );
                              },
                            ),
                            Divider(height: 1, color: subTextColor.withOpacity(0.1)),
                            ListTile(
                              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
                              onTap: () => _showSwitchAccountDialog(cardColor, textColor, accentColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // Helper Widget untuk Styling Kotak
  BoxDecoration _boxStyle(Color cardColor) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(title, style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildTrackerStep(String label, bool isDone, Color activeColor, Color textColor, {bool isActive = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isDone ? activeColor : Colors.grey[200], shape: BoxShape.circle,
              border: isActive ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 6, spreadRadius: 2)] : null,
            ),
            child: isDone ? const Icon(Icons.check, color: Colors.white, size: 14) : Icon(Icons.circle_outlined, color: Colors.grey[400], size: 14),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isDone ? FontWeight.w600 : FontWeight.normal, color: isDone ? textColor : Colors.grey[500], fontFamily: 'Montserrat')),
        ],
      ),
    );
  }

  Widget _buildTrackerLine(bool isDone, Color color) {
    return Container(width: 30, height: 2, color: isDone ? color : Colors.grey[300]);
  }
}
