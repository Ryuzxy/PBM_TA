import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../Models/product.dart';
import '../../Services/firestore_service.dart';
import '../../Services/theme_manager.dart';

class UpdateProductScreen extends StatefulWidget {
  final Product product;
  const UpdateProductScreen({super.key, required this.product});

  @override
  State<UpdateProductScreen> createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _oldPriceController;
  late TextEditingController _stockController;

  XFile? _pickedImage;
  bool _isLoading = false;
  double? _calculatedDiscount;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _oldPriceController = TextEditingController(
      text: widget.product.oldPrice != null ? widget.product.oldPrice!.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _calculatedDiscount = widget.product.discount;

    _priceController.addListener(_calculateDiscount);
    _oldPriceController.addListener(_calculateDiscount);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.removeListener(_calculateDiscount);
    _priceController.dispose();
    _oldPriceController.removeListener(_calculateDiscount);
    _oldPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    final priceStr = _priceController.text.trim();
    final oldPriceStr = _oldPriceController.text.trim();
    if (priceStr.isNotEmpty && oldPriceStr.isNotEmpty) {
      final price = double.tryParse(priceStr);
      final oldPrice = double.tryParse(oldPriceStr);
      if (price != null && oldPrice != null && oldPrice > price) {
        setState(() {
          _calculatedDiscount = ((oldPrice - price) / oldPrice) * 100;
        });
        return;
      }
    }
    setState(() {
      _calculatedDiscount = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

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
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Change Product Photo',
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
                  if (_pickedImage != null)
                    _photoOptionButton(
                      icon: Icons.restore_rounded,
                      label: 'Reset',
                      accentColor: Colors.orange,
                      textColor: textColor,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _pickedImage = null;
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
              color: accentColor.withOpacity(0.1),
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

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return widget.product.imageUrl;
    const String cloudName = "daiw6umes";
    const String uploadPreset = "smartdrop_preset";

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', _pickedImage!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonDecoded = jsonDecode(responseData);
      return jsonDecoded['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed. Status Code: ${response.statusCode}');
    }
  }

  Future<void> _submitProduct() async {
    // Validation
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final priceStr = _priceController.text.trim();
    final oldPriceStr = _oldPriceController.text.trim();
    final stockStr = _stockController.text.trim();

    if (title.isEmpty || description.isEmpty || priceStr.isEmpty || stockStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields (Title, Description, Price, Stock)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    double? oldPrice;
    if (oldPriceStr.isNotEmpty) {
      oldPrice = double.tryParse(oldPriceStr);
      if (oldPrice == null || oldPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid old price'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (oldPrice <= price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old price must be greater than current price'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String sellerLocation = widget.product.location ?? 'Official Store';
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final city = userDoc.data()?['city'] as String? ?? '';
          final state = userDoc.data()?['state'] as String? ?? '';
          if (city.isNotEmpty) {
            sellerLocation = city;
            if (state.isNotEmpty) {
              sellerLocation = '$city, $state';
            }
          }
        }
      }

      final stock = int.tryParse(stockStr) ?? 0;
      if (stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid stock amount'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final imageUrl = await _uploadImage();
      if (imageUrl == null) throw Exception('Image upload returned null');

      final updatedProduct = Product(
        id: widget.product.id,
        title: title,
        description: description,
        price: price,
        oldPrice: oldPrice,
        discount: _calculatedDiscount,
        imageUrl: imageUrl,
        rating: widget.product.rating,
        reviews: widget.product.reviews,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        location: sellerLocation,
        stock: stock,
      );

      await _firestoreService.updateProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.redAccent,
          ),
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

  Widget _buildFieldLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withOpacity(0.7),
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required Color textColor,
    required Color cardColor,
    required Color accentColor,
    required Color subTextColor,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: textColor,
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          color: subTextColor.withOpacity(0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subTextColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: subTextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
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
              'Update Product',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withOpacity(0.08), height: 1),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: accentColor),
                      const SizedBox(height: 16),
                      Text(
                        'Updating product image to Cloudinary...',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker/Display Container
                      Center(
                        child: GestureDetector(
                          onTap: () => _showPhotoOptions(accentColor, cardColor, textColor),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _pickedImage != null
                                ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                                : widget.product.imageUrl.isNotEmpty
                                    ? Image.network(
                                        widget.product.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Icon(Icons.image_not_supported_outlined, color: subTextColor, size: 36),
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined, color: subTextColor.withOpacity(0.6), size: 36),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Change Photo',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              color: subTextColor.withOpacity(0.7),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap to replace product photo',
                          style: TextStyle(color: subTextColor, fontFamily: 'Montserrat', fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Form Fields
                      _buildFieldLabel('Product Title *', textColor),
                      _buildTextField(
                        controller: _titleController,
                        textColor: textColor,
                        cardColor: cardColor,
                        accentColor: accentColor,
                        subTextColor: subTextColor,
                        hintText: 'e.g. Leather Jacket Classic',
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Product Description *', textColor),
                      _buildTextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        textColor: textColor,
                        cardColor: cardColor,
                        accentColor: accentColor,
                        subTextColor: subTextColor,
                        hintText: 'Describe the materials, sizing, and details...',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Price (Rp) *', textColor),
                                _buildTextField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textColor: textColor,
                                  cardColor: cardColor,
                                  accentColor: accentColor,
                                  subTextColor: subTextColor,
                                  hintText: '999',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Original Price (Rp)', textColor),
                                _buildTextField(
                                  controller: _oldPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textColor: textColor,
                                  cardColor: cardColor,
                                  accentColor: accentColor,
                                  subTextColor: subTextColor,
                                  hintText: '1499',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Stock *', textColor),
                      _buildTextField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        textColor: textColor,
                        cardColor: cardColor,
                        accentColor: accentColor,
                        subTextColor: subTextColor,
                        hintText: 'e.g. 10',
                      ),

                      // Live calculated discount preview
                      if (_calculatedDiscount != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Calculated Discount: ${_calculatedDiscount!.toStringAsFixed(0)}% Off',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Changes',
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
}
