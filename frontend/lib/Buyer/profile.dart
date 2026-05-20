import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/theme_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: '***********'); // Placeholder
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _pincodeController.text = data['pincode'] ?? '';
            _addressController.text = data['address'] ?? '';
            _cityController.text = data['city'] ?? '';
            _stateController.text = data['state'] ?? '';
            _countryController.text = data['country'] ?? '';
            _bankAccountController.text = data['bankAccount'] ?? '';
            _accountHolderController.text = data['accountHolder'] ?? '';
            _ifscController.text = data['ifscCode'] ?? '';
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $e')),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'pincode': _pincodeController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'bankAccount': _bankAccountController.text.trim(),
        'accountHolder': _accountHolderController.text.trim(),
        'ifscCode': _ifscController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email has been sent to ${user.email}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reset email: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _bankAccountController.dispose();
    _accountHolderController.dispose();
    _ifscController.dispose();
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
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: textColor,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: accentColor, width: 2),
                              color: cardColor,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              'http://localhost:3845/assets/e2db1865e7299c33d1d7de36aa46e37cda72d981.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: cardColor,
                                  child: Center(
                                    child: Text(
                                      'AS',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 32,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Personal Details
                    Text(
                      'Personal Details',
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Email Address', textColor),
                    _buildTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Password', textColor),
                    _buildTextField(
                      controller: _passwordController,
                      obscureText: true,
                      readOnly: true,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _changePassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            color: accentColor,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Divider(color: subTextColor.withOpacity(0.3), thickness: 0.5),
                    const SizedBox(height: 16),

                    // Section 2: Business Address Details
                    Text(
                      'Business Address Details',
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Pincode', textColor),
                    _buildTextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Address', textColor),
                    _buildTextField(
                      controller: _addressController,
                      maxLines: 2,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('City', textColor),
                    _buildTextField(
                      controller: _cityController,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('State', textColor),
                    _buildTextField(
                      controller: _stateController,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Country', textColor),
                    _buildTextField(
                      controller: _countryController,
                      suffixIcon: Icon(Icons.keyboard_arrow_down, color: textColor),
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),

                    Divider(color: subTextColor.withOpacity(0.3), thickness: 0.5),
                    const SizedBox(height: 16),

                    // Section 3: Bank Account Details
                    Text(
                      'Bank Account Details',
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Bank Account Number', textColor),
                    _buildTextField(
                      controller: _bankAccountController,
                      keyboardType: TextInputType.number,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Account Holder’s Name', textColor),
                    _buildTextField(
                      controller: _accountHolderController,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('IFSC Code', textColor),
                    _buildTextField(
                      controller: _ifscController,
                      textColor: textColor,
                      cardColor: cardColor,
                      accentColor: accentColor,
                      subTextColor: subTextColor,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    GestureDetector(
                      onTap: _saveUserProfile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Save',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.075,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withOpacity(0.8),
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    required Color textColor,
    required Color cardColor,
    required Color accentColor,
    required Color subTextColor,
  }) {
    final isDark = cardColor.computeLuminance() < 0.5;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly ? textColor.withOpacity(0.5) : textColor,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly 
            ? (isDark ? cardColor.withOpacity(0.7) : const Color(0xFFF5F5F5))
            : cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: subTextColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: subTextColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: readOnly ? subTextColor.withOpacity(0.5) : accentColor,
            width: readOnly ? 1.0 : 1.5,
          ),
        ),
      ),
    );
  }
}
