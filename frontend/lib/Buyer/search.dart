import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/product.dart';
import '../Services/firestore_service.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
        fontFamily: 'Montserrat',
      ),
      home: const TrendingProducts(),
    );
  }
}

class TrendingProducts extends StatefulWidget {
  const TrendingProducts({super.key});

  @override
  State<TrendingProducts> createState() => _TrendingProductsState();
}

class _TrendingProductsState extends State<TrendingProducts> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedIndex = 2; // Default to Search

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu, color: Colors.black, size: 20),
          ),
        ),
        title: const Text(
          'SmartDrop',
          style: TextStyle(
            color: Color(0xFF4392F9),
            fontSize: 18,
            fontFamily: 'Libre Caslon Text',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final photoUrl = user?.photoURL ?? '';
                final initial =
                    (user?.email?.isNotEmpty == true) ? user!.email![0].toUpperCase() : 'U';
                if (photoUrl.isNotEmpty) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(photoUrl),
                    onBackgroundImageError: (_, __) {},
                  );
                }
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF4392F9),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 9,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search any Product..',
                  hintStyle: TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Color(0xFFBBBBBB)),
                  suffixIcon: Icon(Icons.mic, color: Color(0xFFBBBBBB)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Items count and Sort/Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '52,082+ Iteams', // Kept original spelling
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    _buildActionChip('Sort', Icons.sort),
                    const SizedBox(width: 8),
                    _buildActionChip('Filter', Icons.filter_list),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Product Grid
            Expanded(
              child: StreamBuilder<List<Product>>(
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
                    return const Center(child: Text('No products available'));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 10,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFEB3030),
          unselectedItemColor: Colors.black,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'wishlist', // Kept original casing
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(1, 1),
          )
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 16, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    height: 136,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 136,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: Colors.grey, size: 32),
                      ),
                    ),
                  )
                : Container(
                    height: 136,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.shopping_bag_outlined,
                          color: Colors.grey, size: 32),
                    ),
                  ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      product.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: const TextStyle(
                              color: Color(0xFFA4A9B3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}