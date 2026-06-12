import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/product.dart';
import '../Services/firestore_service.dart';
import '../Services/theme_manager.dart';
import 'market/discount.dart';
import 'market/deals_of_days.dart';
import 'market/spesial_offer.dart';
import 'market/trending.dart';
import 'market/sponsored.dart';
import 'profile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  int _currentTab = 0;
  String? _userPhotoUrl;
  String _userInitials = 'A';
  String _adminLocation = '';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email ?? '';
    if (email.isNotEmpty && mounted) {
      setState(() => _userInitials = email[0].toUpperCase());
    }

    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      if (mounted) setState(() => _userPhotoUrl = user.photoURL);
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        setState(() {
          final name = (data['accountHolder'] as String?) ?? '';
          if (name.isNotEmpty) _userInitials = name[0].toUpperCase();
          final photoUrl = (data['photoUrl'] as String?) ?? '';
          if (photoUrl.isNotEmpty) _userPhotoUrl = photoUrl;

          final city = (data['city'] as String?) ?? '';
          final state = (data['state'] as String?) ?? '';
          if (city.isNotEmpty) {
            _adminLocation = city;
            if (state.isNotEmpty) {
              _adminLocation = '$city, $state';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading admin data in dashboard: $e');
    }
  }

  Widget _buildProfileAvatar(Color accentColor) {
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: accentColor,
        backgroundImage: NetworkImage(_userPhotoUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: accentColor,
      child: Text(
        _userInitials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showProductForm({Product? product}) {
    final titleController = TextEditingController(text: product?.title ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final oldPriceController = TextEditingController(text: product?.oldPrice?.toString() ?? '');
    final discountController = TextEditingController(text: product?.discount?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    final initialLocation = (product?.location != null && product!.location!.isNotEmpty)
        ? product.location!
        : (_adminLocation.isNotEmpty ? _adminLocation : 'Official Store');
    final locationController = TextEditingController(text: initialLocation);
    final stockController = TextEditingController(text: product?.stock.toString() ?? '10');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: oldPriceController, decoration: const InputDecoration(labelText: 'Old Price (Optional)'), keyboardType: TextInputType.number),
                TextField(controller: discountController, decoration: const InputDecoration(labelText: 'Discount (Optional)'), keyboardType: TextInputType.number),
                TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'Image URL')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location (e.g. Jakarta)')),
                TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newProduct = Product(
                  id: product?.id,
                  title: titleController.text,
                  description: descController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                  oldPrice: double.tryParse(oldPriceController.text),
                  discount: double.tryParse(discountController.text),
                  imageUrl: imageUrlController.text,
                  location: locationController.text,
                  rating: product?.rating ?? 0.0,
                  reviews: product?.reviews ?? 0,
                  stock: int.tryParse(stockController.text) ?? 0,
                );

                if (product == null) {
                  await _firestoreService.addProduct(newProduct);
                } else {
                  await _firestoreService.updateProduct(newProduct);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading products'));
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(child: Text('No products available.'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                    : const Icon(Icons.image, size: 50),
                title: Text(product.title),
                subtitle: Text('Rp ${product.price} | Stock: ${product.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showProductForm(product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _firestoreService.deleteProduct(product.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarketingTab() {
    final marketingOptions = [
      {
        'title': 'Discounts',
        'subtitle': 'Promo & Summer Sale Banners',
        'icon': Icons.percent,
        'color': Colors.amber.shade700,
        'screen': const DiscountManager(),
      },
      {
        'title': 'Deals of the Day',
        'subtitle': 'Countdown & Selected Deals',
        'icon': Icons.alarm,
        'color': Colors.blue.shade700,
        'screen': const DealsOfDaysManager(),
      },
      {
        'title': 'Special Offers',
        'subtitle': 'Special Promo & Flat Heels',
        'icon': Icons.local_offer,
        'color': Colors.red.shade700,
        'screen': const SpecialOfferManager(),
      },
      {
        'title': 'Trending & New Arrivals',
        'subtitle': 'Highlights & New Collection Toggles',
        'icon': Icons.trending_up,
        'color': Colors.purple.shade700,
        'screen': const TrendingManager(),
      },
      {
        'title': 'Sponsored',
        'subtitle': 'Featured Partnerships & Ads',
        'icon': Icons.campaign,
        'color': Colors.green.shade700,
        'screen': const SponsoredManager(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
        ),
        itemCount: marketingOptions.length,
        itemBuilder: (context, index) {
          final opt = marketingOptions[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => opt['screen'] as Widget),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (opt['color'] as Color).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        opt['icon'] as IconData,
                        color: opt['color'] as Color,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      opt['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        final textColor = theme.textColor;
        final accentColor = theme.accentColor;

        return Scaffold(
          backgroundColor: theme.bgColor,
          appBar: AppBar(
            title: Text(
              _currentTab == 0 ? 'Admin Panel - Products' : 'Admin Panel - Marketing',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: theme.bgColor,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withOpacity(0.08), height: 1),
            ),
            actions: [
              if (_currentTab == 0)
                IconButton(
                  icon: Icon(Icons.add, color: textColor),
                  onPressed: () => _showProductForm(),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                      );
                      _loadAdminData();
                    },
                    child: _buildProfileAvatar(accentColor),
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentTab,
            children: [
              _buildProductsTab(),
              _buildMarketingTab(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) {
              setState(() {
                _currentTab = index;
              });
            },
            backgroundColor: theme.cardColor,
            selectedItemColor: accentColor,
            unselectedItemColor: theme.subTextColor,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign),
                label: 'Marketing',
              ),
            ],
          ),
        );
      },
    );
  }
}
