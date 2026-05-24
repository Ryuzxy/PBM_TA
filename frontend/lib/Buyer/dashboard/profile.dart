import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../Services/theme_manager.dart';
import 'package:csc_picker/csc_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isUploading = false;

  // Profile photo
  String _photoUrl = '';
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: '***********');
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ifscController = TextEditingController();

  // Location dropdowns
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;


  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _photoUrl = user.photoURL ?? '';

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _pincodeController.text = data['pincode'] ?? '';
          _addressController.text = data['address'] ?? '';
          _bankAccountController.text = data['bankAccount'] ?? '';
          _accountHolderController.text = data['accountHolder'] ?? '';
          _ifscController.text = data['ifscCode'] ?? '';
          // Prefer Cloudinary URL from Firestore, fallback to Firebase Auth
          final firestorePhoto = data['photoUrl'] ?? '';
          _photoUrl = firestorePhoto.isNotEmpty ? firestorePhoto : _photoUrl;

          // Set dropdown values (CSCPicker handles validation)
          _selectedCountry = (data['country'] ?? '').toString();
          _selectedState = (data['state'] ?? '').toString();
          _selectedCity = (data['city'] ?? '').toString();
          if (_selectedCountry!.isEmpty) _selectedCountry = null;
          if (_selectedState!.isEmpty) _selectedState = null;
          if (_selectedCity!.isEmpty) _selectedCity = null;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Photo Picker ─────────────────────────────────────────────────────────────

  void _showPhotoOptions(Color accentColor, Color cardColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _photoOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    accentColor: accentColor,
                    textColor: textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _photoOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    accentColor: accentColor,
                    textColor: textColor,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_photoUrl.isNotEmpty || _pickedImage != null)
                    _photoOptionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      accentColor: Colors.redAccent,
                      textColor: textColor,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _pickedImage = null;
                          _photoUrl = '';
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOptionButton({
    required IconData icon,
    required String label,
    required Color accentColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) setState(() => _pickedImage = image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return _photoUrl.isNotEmpty ? _photoUrl : null;
    setState(() => _isUploading = true);
    
    try {
      // 📝 GANTI PRESET INI DENGAN MILIKMU
      const String cloudName = "daiw6umes"; // Ini sudah sesuai screenshot kamu
      const String uploadPreset = "smartdrop_preset"; 

      // Tembak langsung ke server Cloudinary
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', _pickedImage!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonDecoded = jsonDecode(responseData);
        final String secureUrl = jsonDecoded['secure_url'] as String;

        // Tetap update foto di Firebase Auth menggunakan URL Cloudinary
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(secureUrl);
        
        setState(() => _photoUrl = secureUrl);
        return secureUrl;
      } else {
        throw Exception('Gagal upload ke Cloudinary. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Save Profile ─────────────────────────────────────────────────────────────

  Future<void> _saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final uploadedUrl = await _uploadPhoto(user.uid);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'pincode': _pincodeController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _selectedCity ?? '',
        'state': _selectedState ?? '',
        'country': _selectedCountry ?? '',
        'bankAccount': _bankAccountController.text.trim(),
        'accountHolder': _accountHolderController.text.trim(),
        'ifscCode': _ifscController.text.trim(),
        'photoUrl': uploadedUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to ${user.email}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _accountHolderController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        final bgColor = theme.bgColor;
        final textColor = theme.textColor;
        final cardColor = theme.cardColor;
        final accentColor = theme.accentColor;
        final subTextColor = theme.subTextColor;

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
              'Profile',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withValues(alpha: 0.08), height: 1),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile Photo ───────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => _showPhotoOptions(accentColor, cardColor, textColor),
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accentColor, width: 2.5),
                                  color: cardColor,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildAvatar(accentColor),
                              ),
                              // Upload indicator
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                  ),
                                ),
                              // Edit badge
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bgColor, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap to change photo',
                          style: TextStyle(color: subTextColor, fontFamily: 'Montserrat', fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Section 1: Personal Details ─────────────────
                      _sectionTitle('Personal Details', textColor),
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
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: subTextColor.withValues(alpha: 0.2), thickness: 0.5),
                      const SizedBox(height: 20),

                      // ── Section 2: Address Details ──────────────────
                      _sectionTitle('Business Address Details', textColor),
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

                      // ── CSC Picker (Negara, Provinsi, Kota Seluruh Dunia) ──
                      _buildFieldLabel('Location (Country, State, City)', textColor),
                      CSCPicker(
                        showStates: true,
                        showCities: true,
                        
                        // Default data dari Firestore jika user sudah pernah simpan
                        currentCountry: _selectedCountry,
                        currentState: _selectedState,
                        currentCity: _selectedCity,

                        // Styling menyesuaikan tema aplikasimu
                        dropdownDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: cardColor,
                            border: Border.all(color: subTextColor.withValues(alpha: 0.3), width: 1)),
                        disabledDropdownDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: subTextColor.withValues(alpha: 0.06),
                            border: Border.all(color: subTextColor.withValues(alpha: 0.3), width: 1)),
                        
                        // Text styling
                        selectedItemStyle: TextStyle(
                          color: textColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        dropdownHeadingStyle: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold),
                        
                        // Text Placeholder
                        countrySearchPlaceholder: "Cari Negara",
                        stateSearchPlaceholder: "Cari Provinsi",
                        citySearchPlaceholder: "Cari Kota",
                        countryDropdownLabel: "Pilih Negara",
                        stateDropdownLabel: "Pilih Provinsi",
                        cityDropdownLabel: "Pilih Kota",
                        
                        // Saat data dipilih, simpan ke variabel State kamu
                        onCountryChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            // Reset state & city jika negara ganti
                            _selectedState = null; 
                            _selectedCity = null;
                          });
                        },
                        onStateChanged: (value) {
                          setState(() {
                            _selectedState = value;
                            _selectedCity = null;
                          });
                        },
                        onCityChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Divider(color: subTextColor.withValues(alpha: 0.2), thickness: 0.5),
                      const SizedBox(height: 20),

                      // ── Section 3: Bank Details ─────────────────────
                      _sectionTitle('Bank Account Details', textColor),
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
                      _buildFieldLabel("Account Holder's Name", textColor),
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
                      const SizedBox(height: 36),

                      // ── Save Button ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _saveUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAvatar(Color accentColor) {
    if (_pickedImage != null) {
      return Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
    }
    if (_photoUrl.isNotEmpty) {
      return Image.network(
        _photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarInitials(accentColor),
      );
    }
    return _avatarInitials(accentColor);
  }

  Widget _avatarInitials(Color accentColor) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
    return Container(
      color: accentColor.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: accentColor,
            fontSize: 38,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.7),
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
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
    bool readOnly = false,
    required Color textColor,
    required Color cardColor,
    required Color accentColor,
    required Color subTextColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: TextStyle(
        color: readOnly ? textColor.withValues(alpha: 0.5) : textColor,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly ? subTextColor.withValues(alpha: 0.06) : cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subTextColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subTextColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: readOnly ? subTextColor.withValues(alpha: 0.3) : accentColor,
            width: readOnly ? 1 : 1.5,
          ),
        ),
      ),
    );
  }

}
