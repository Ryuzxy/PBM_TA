import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Models/product.dart';
import '../../Models/category_model.dart';
import '../../Models/banner_model.dart';
import '../../Services/firestore_service.dart';
import 'profile.dart';
import 'setting.dart';
import '../../Services/theme_manager.dart';
import '../chekout/cart.dart';
import 'wishlist.dart';
import 'search.dart';
import 'items_detail.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedIndex = 0;

  String? _userPhotoUrl;
  String _userInitials = 'U';

  List<BannerModel> _banners = [];
  StreamSubscription<List<BannerModel>>? _bannersSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _bannersSubscription = _firestoreService.getBanners().listen(
      (banners) {
        if (mounted) setState(() => _banners = banners);
      },
      onError: (e) => debugPrint('Banners stream error: $e'),
    );
  }

  @override
  void dispose() {
    _bannersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
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
        });
      }
    } catch (e) {
      debugPrint('Error loading user data in dashboard: $e');
    }
  }

  BannerModel? _getBanner(String type) {
    try {
      return _banners.firstWhere((b) => b.type == type);
    } catch (_) {
      return null;
    }
  }

  Widget _safeImage({
    required String url,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    Color? bgColor,
    IconData icon = Icons.image_outlined,
  }) {
    final bg = bgColor ?? Colors.grey.shade200;
    final fallback = Container(
      height: height,
      width: width,
      color: bg,
      child: Center(
        child: Icon(icon, color: Colors.grey.shade400, size: 32),
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width,
          color: bg,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
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

        final promoBanner = _getBanner('promo');
        final specialOfferBanner = _getBanner('special_offer');
        final flatHeelsBanner = _getBanner('flat_heels');
        final summerSaleBanner = _getBanner('summer_sale');
        final sponsoredBanner = _getBanner('sponsored');

        return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            Text(
              'SmartDrop',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: _buildProfileAvatar(accentColor),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Featured',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 90,
                child: StreamBuilder<List<CategoryModel>>(
                  stream: _firestoreService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;

                    if (isLoading && categories.isEmpty) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (_, __) => _buildCategoryShimmer(cardColor),
                      );
                    }

                    if (categories.isEmpty) {
                      final defaults = [
                        ('Beauty', Icons.face_retouching_natural),
                        ('Fashion', Icons.checkroom),
                        ('Kids', Icons.child_care),
                        ('Mens', Icons.man),
                        ('Womens', Icons.woman),
                      ];
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: defaults
                            .map((e) => _buildDefaultCategoryItem(
                                e.$1, e.$2, textColor, accentColor))
                            .toList(),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) =>
                          _buildCategoryItem(categories[index], textColor, accentColor),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promoBanner?.title ?? '50-40% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            promoBanner?.subtitle ?? 'Now in (product)\nAll colours',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Shop Now', style: TextStyle(color: Colors.white)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _safeImage(
                        url: promoBanner?.imageUrl ?? '',
                        width: 100,
                        height: 120,
                        bgColor: Colors.white.withOpacity(0.25),
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(true, accentColor, subTextColor),
                  _buildDot(false, accentColor, subTextColor),
                  _buildDot(false, accentColor, subTextColor),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deal of the Day',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            StreamBuilder<DocumentSnapshot>(
                              stream: _firestoreService.getSettings('deals_of_days'),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data() as Map<String, dynamic>?;
                                final remainingText = data != null ? (data['remainingText'] as String? ?? 'No deal') : 'Loading...';
                                return Text(
                                  remainingText,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Row(
                        children: [
                          Text('View all',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 315,
                child: StreamBuilder<List<Product>>(
                  stream: _firestoreService.getDealProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading products'));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Text('No products available'));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(products[index], currentTheme),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 1),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _safeImage(
                        url: specialOfferBanner?.imageUrl ?? '',
                        width: 50,
                        height: 50,
                        bgColor: accentColor.withOpacity(0.15),
                        icon: Icons.local_offer_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialOfferBanner?.title ?? 'Special Offers 🛍️',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialOfferBanner?.subtitle ??
                                'We make sure you get the offer you need at best prices',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _safeImage(
                        url: flatHeelsBanner?.imageUrl ?? '',
                        width: 100,
                        height: 100,
                        bgColor: Colors.pink.shade100,
                        icon: Icons.checkroom,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            flatHeelsBanner?.title ?? 'Flat and Heels',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            flatHeelsBanner?.subtitle ??
                                'Stand a chance to get rewarded',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Visit now',
                                    style: TextStyle(color: Colors.white)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trending Products',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            StreamBuilder<DocumentSnapshot>(
                              stream: _firestoreService.getSettings('trending'),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data() as Map<String, dynamic>?;
                                final lastDate = data != null ? (data['lastDate'] as String? ?? '') : 'Loading...';
                                return Text(
                                  lastDate,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Row(
                        children: [
                          Text('View all',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 315,
                child: StreamBuilder<List<Product>>(
                  stream: _firestoreService.getTrendingProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading products'));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Text('No products available'));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(products[index], currentTheme),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _safeImage(
                  url: summerSaleBanner?.imageUrl ?? '',
                  height: 150,
                  width: double.infinity,
                  bgColor: Colors.orange.shade200,
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Arrivals',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor)),
                      Text("Summer' 25 Collections",
                          style: TextStyle(color: subTextColor)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Row(
                      children: [
                        Text('View all',
                            style: TextStyle(color: Colors.white, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 315,
                child: StreamBuilder<List<Product>>(
                  stream: _firestoreService.getNewArrivalProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading products'));
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return const Center(child: Text('No products available'));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(products[index], currentTheme),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Text('Sponsored',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 1),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: _safeImage(
                        url: sponsoredBanner?.imageUrl ?? '',
                        width: double.infinity,
                        height: 200,
                        bgColor: Colors.grey.shade200,
                        icon: Icons.campaign_outlined,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sponsoredBanner?.title ?? 'up to 50% Off',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 16, color: subTextColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            selectedItemColor: accentColor,
            unselectedItemColor: subTextColor,
            backgroundColor: cardColor,
            showUnselectedLabels: true,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on Home/Dashboard, do nothing
                  setState(() => _selectedIndex = 0);
                  break;
                case 1:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                  break;
                case 2:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                  break;
                case 3:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                  break;
                case 4:
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingScreen()));
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border), label: 'Wishlist'),
              BottomNavigationBarItem(
                  icon: SizedBox.shrink(), label: ''), 
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined), label: 'Setting'),
            ],
          ),
          Positioned(
            top: -20,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              backgroundColor: accentColor,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              elevation: 4,
              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildFilterChip(
      String label, IconData icon, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: textColor),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      CategoryModel category, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: accentColor.withOpacity(0.1),
            backgroundImage: category.imageUrl.isNotEmpty
                ? NetworkImage(category.imageUrl)
                : null,
            onBackgroundImageError:
                category.imageUrl.isNotEmpty ? (_, __) {} : null,
            child: category.imageUrl.isEmpty
                ? Icon(Icons.category, color: accentColor)
                : null,
          ),
          const SizedBox(height: 8),
          Text(category.name,
              style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildDefaultCategoryItem(
      String name, IconData icon, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: accentColor.withOpacity(0.1),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildCategoryShimmer(Color cardColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: cardColor),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive, Color accentColor, Color subTextColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        color: isActive ? accentColor : subTextColor.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildProductCard(Product product, AppTheme currentTheme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(product: product)),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: currentTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                spreadRadius: 1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: _safeImage(
                    url: product.imageUrl,
                    height: 120,
                    width: double.infinity,
                    bgColor: currentTheme.cardColor,
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                if (product.stock <= 0)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SOLD OUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: currentTheme.textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                        fontSize: 10, color: currentTheme.subTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: currentTheme.subTextColor),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.location != null && product.location!.isNotEmpty
                              ? product.location!
                              : 'Official Store',
                          style: TextStyle(
                            fontSize: 10,
                            color: currentTheme.subTextColor,
                            fontFamily: 'Montserrat',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 10, color: product.stock <= 0 ? Colors.red : currentTheme.subTextColor),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.stock <= 0 ? 'Stok Habis' : 'Stock: ${product.stock}',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.stock <= 0 ? Colors.red : currentTheme.subTextColor,
                            fontFamily: 'Montserrat',
                            fontWeight: product.stock <= 0 ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: currentTheme.accentColor),
                  ),
                  if (product.oldPrice != null)
                    Row(
                      children: [
                        Text(
                          'Rp ${product.oldPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: currentTheme.subTextColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (product.discount != null)
                          Text(
                            '${product.discount!.toStringAsFixed(0)}% off',
                            style:
                                const TextStyle(fontSize: 10, color: Colors.red),
                          ),
                      ],
                    ),
                  if (product.reviews > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating} (${product.reviews})',
                          style: TextStyle(
                              fontSize: 10, color: currentTheme.subTextColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
