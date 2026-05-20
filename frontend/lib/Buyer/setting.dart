import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/theme_manager.dart';
import 'profile.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isLoading = true;
  String _userName = 'User';
  String _userEmail = '';

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
          setState(() {
            _userName = doc.data()?['accountHolder'] ?? 'User';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data in settings: $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
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
          'Settings',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Profile Quick View
                  _buildSectionHeader('Profile', textColor),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 2),
                            color: Colors.grey[200],
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Colors.grey, size: 30),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail,
                                style: TextStyle(
                                  color: subTextColor.withOpacity(0.8),
                                  fontSize: 12,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
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

                  // Section: Background Customization
                  _buildSectionHeader('Customize Background Color', textColor),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose theme background preset:',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ThemeManager.themes.map((theme) {
                            final isSelected = theme.name == currentTheme.name;
                            return GestureDetector(
                              onTap: () {
                                ThemeManager.changeTheme(theme.name);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
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
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Package Tracking
                  _buildSectionHeader('Package Tracking', textColor),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #SD-9843-TRK',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'In Transit',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estimated Delivery: Today, 5:00 PM',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Horizontal Tracker Timeline
                        Row(
                          children: [
                            _buildTrackerStep('Ordered', true, accentColor, textColor),
                            _buildTrackerLine(true, accentColor),
                            _buildTrackerStep('Shipped', true, accentColor, textColor),
                            _buildTrackerLine(true, accentColor),
                            _buildTrackerStep('In Transit', true, accentColor, textColor, isActive: true),
                            _buildTrackerLine(false, Colors.grey),
                            _buildTrackerStep('Delivered', false, Colors.grey, textColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Activity Log / History
                  _buildSectionHeader('Activity History', textColor),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHistoryItem(
                          icon: Icons.lock_open,
                          title: 'Box opened by J&T Express',
                          subtitle: 'Today, 2:32 PM',
                          textColor: textColor,
                          subTextColor: subTextColor,
                          accentColor: accentColor,
                        ),
                        _buildDivider(),
                        _buildHistoryItem(
                          icon: Icons.check_circle_outline,
                          title: 'Delivery secure confirmed',
                          subtitle: 'Yesterday, 4:15 PM',
                          textColor: textColor,
                          subTextColor: subTextColor,
                          accentColor: accentColor,
                        ),
                        _buildDivider(),
                        _buildHistoryItem(
                          icon: Icons.edit_location_outlined,
                          title: 'Changed delivery address details',
                          subtitle: '20 May 2026, 11:20 AM',
                          textColor: textColor,
                          subTextColor: subTextColor,
                          accentColor: accentColor,
                        ),
                        _buildDivider(),
                        _buildHistoryItem(
                          icon: Icons.login_outlined,
                          title: 'Logged in from Pixel 8 Pro',
                          subtitle: '19 May 2026, 9:15 AM',
                          textColor: textColor,
                          subTextColor: subTextColor,
                          accentColor: accentColor,
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

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildTrackerStep(String label, bool isDone, Color activeColor, Color textColor, {bool isActive = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? activeColor : Colors.grey[200],
              shape: BoxShape.circle,
              border: isActive ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Icon(Icons.circle_outlined, color: Colors.grey[400], size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
              color: isDone ? textColor : Colors.grey[500],
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerLine(bool isDone, Color color) {
    return Container(
      width: 30,
      height: 2,
      color: isDone ? color : Colors.grey[300],
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 11,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withOpacity(0.1),
      thickness: 1,
      height: 1,
    );
  }
}
