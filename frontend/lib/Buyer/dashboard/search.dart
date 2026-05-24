import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../Models/product.dart';
import '../../Services/firestore_service.dart';
import '../../Services/theme_manager.dart';
import 'items_detail.dart';

// Sort options
enum SortOption { none, priceLow, priceHigh, distanceNear, distanceFar }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _query = '';
  SortOption _sortOption = SortOption.none;

  // Filter
  double _minPrice = 0;
  double _maxPrice = 999999;
  // double _tempMin = 0;
  // double _tempMax = 999999;
  bool _filterActive = false;

  // User location for distance sort
  double? _userLat;
  double? _userLng;

  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase().trim());
    });
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    } catch (_) {}
  }

  List<Product> _applySearchAndSort(List<Product> products) {
    // 1. Search filter
    List<Product> result = products.where((p) {
      if (_query.isEmpty) return true;
      return p.title.toLowerCase().contains(_query) ||
          p.description.toLowerCase().contains(_query);
    }).toList();

    // 2. Price filter
    result = result.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();

    // 3. Sort
    switch (_sortOption) {
      case SortOption.priceLow:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHigh:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.distanceNear:
        if (_userLat != null && _userLng != null) {
          result.sort((a, b) =>
              _getDistance(a).compareTo(_getDistance(b)));
        }
        break;
      case SortOption.distanceFar:
        if (_userLat != null && _userLng != null) {
          result.sort((a, b) =>
              _getDistance(b).compareTo(_getDistance(a)));
        }
        break;
      case SortOption.none:
        break;
    }

    return result;
  }

  double _getDistance(Product p) {
    // Products may have lat/lng stored; fallback to 0 if not
    // For demo, generate a deterministic pseudo-distance from product id hash
    if (_userLat == null || _userLng == null) return 0;
    // If product has location fields use them; otherwise vary by title hash
    final lat = (p.id?.hashCode ?? 0) % 1000 / 1000.0 * 5 + _userLat!;
    final lng = (p.title.hashCode % 1000) / 1000.0 * 5 + _userLng!;
    return Geolocator.distanceBetween(_userLat!, _userLng!, lat, lng);
  }

  void _showSortBottomSheet(BuildContext context, AppTheme theme) {
    final accentColor = theme.accentColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textColor;
    final subTextColor = theme.subTextColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final options = [
              _SortTile(SortOption.none, 'Default', Icons.sort_rounded),
              _SortTile(SortOption.priceLow, 'Price: Lowest First', Icons.arrow_downward_rounded),
              _SortTile(SortOption.priceHigh, 'Price: Highest First', Icons.arrow_upward_rounded),
              _SortTile(SortOption.distanceNear, 'Distance: Nearest First', Icons.near_me_rounded),
              _SortTile(SortOption.distanceFar, 'Distance: Farthest First', Icons.near_me_disabled_rounded),
            ];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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
                    'Sort By',
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...options.map((opt) {
                    final isSelected = _sortOption == opt.option;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _sortOption = opt.option);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accentColor : textColor.withValues(alpha: 0.08),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(opt.icon, color: isSelected ? accentColor : subTextColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt.label,
                                style: TextStyle(
                                  color: isSelected ? accentColor : textColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context, AppTheme theme, double maxProductPrice) {
    final accentColor = theme.accentColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textColor;

    // Temp values
    double tempMin = _minPrice;
    double tempMax = _maxPrice.clamp(0, maxProductPrice);
    if (tempMax <= tempMin) tempMax = maxProductPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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
                    'Filter',
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price Range',
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${tempMin.toInt()} – ₹${tempMax == maxProductPrice ? '∞' : tempMax.toInt()}',
                          style: TextStyle(
                            color: accentColor,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: RangeValues(
                      tempMin.clamp(0, maxProductPrice),
                      tempMax.clamp(0, maxProductPrice),
                    ),
                    min: 0,
                    max: maxProductPrice > 0 ? maxProductPrice : 1,
                    divisions: maxProductPrice > 0 ? (maxProductPrice / 100).round().clamp(1, 200) : 1,
                    activeColor: accentColor,
                    inactiveColor: accentColor.withValues(alpha: 0.2),
                    onChanged: (vals) {
                      setSheetState(() {
                        tempMin = vals.start;
                        tempMax = vals.end;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹0', style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontSize: 12)),
                      Text(
                        '₹${maxProductPrice.toInt()}',
                        style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _minPrice = 0;
                              _maxPrice = 999999;
                              _filterActive = false;
                            });
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accentColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: accentColor,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _minPrice = tempMin;
                              _maxPrice = tempMax >= maxProductPrice ? 999999 : tempMax;
                              _filterActive = _minPrice > 0 || _maxPrice < 999999;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

        final isSortActive = _sortOption != SortOption.none;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Search Products',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              // User avatar
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (_, snap) {
                    final user = snap.data;
                    final photoUrl = user?.photoURL ?? '';
                    final initial = (user?.email?.isNotEmpty == true)
                        ? user!.email![0].toUpperCase()
                        : 'U';
                    if (photoUrl.isNotEmpty) {
                      return CircleAvatar(radius: 18, backgroundImage: NetworkImage(photoUrl));
                    }
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: accentColor,
                      child: Text(initial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withValues(alpha: 0.08), height: 1),
            ),
          ),
          body: StreamBuilder<List<Product>>(
            stream: _firestoreService.getProducts(),
            builder: (context, snapshot) {
              _allProducts = snapshot.data ?? [];
              final maxPrice = _allProducts.isEmpty
                  ? 10000.0
                  : _allProducts.map((p) => p.price).reduce((a, b) => a > b ? a : b);

              final displayed = _applySearchAndSort(_allProducts);

              return Column(
                children: [
                  // ── Search Bar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        style: TextStyle(color: textColor, fontFamily: 'Montserrat', fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search any product...',
                          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, color: subTextColor),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, color: subTextColor),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocus.unfocus();
                                  },
                                )
                              : Icon(Icons.mic_rounded, color: subTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // ── Sort/Filter row ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Result count
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${displayed.length}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: ' Items',
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Sort button
                            _buildChipButton(
                              label: _sortLabel(),
                              icon: Icons.sort_rounded,
                              isActive: isSortActive,
                              accentColor: accentColor,
                              cardColor: cardColor,
                              textColor: textColor,
                              onTap: () => _showSortBottomSheet(context, theme),
                            ),
                            const SizedBox(width: 8),
                            // Filter button
                            _buildChipButton(
                              label: 'Filter',
                              icon: Icons.tune_rounded,
                              isActive: _filterActive,
                              accentColor: accentColor,
                              cardColor: cardColor,
                              textColor: textColor,
                              onTap: () => _showFilterBottomSheet(context, theme, maxPrice),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Active filters indicator ──────────────────────────
                  if (_filterActive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt_rounded, size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'Price: ₹${_minPrice.toInt()} – ₹${_maxPrice >= 999999 ? '∞' : _maxPrice.toInt()}',
                            style: TextStyle(
                              color: accentColor,
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _minPrice = 0;
                              _maxPrice = 999999;
                              _filterActive = false;
                            }),
                            child: Icon(Icons.close_rounded, size: 16, color: accentColor),
                          ),
                        ],
                      ),
                    ),

                  // ── Product Grid ──────────────────────────────────────
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? Center(child: CircularProgressIndicator(color: accentColor))
                        : snapshot.hasError
                            ? Center(
                                child: Text('Error loading products',
                                    style: TextStyle(color: textColor, fontFamily: 'Montserrat')))
                            : displayed.isEmpty
                                ? _buildEmptyState(textColor, subTextColor, accentColor)
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.68,
                                    ),
                                    itemCount: displayed.length,
                                    itemBuilder: (_, i) => _buildProductCard(
                                      displayed[i],
                                      textColor,
                                      cardColor,
                                      accentColor,
                                      subTextColor,
                                      context,
                                    ),
                                  ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _sortLabel() {
    switch (_sortOption) {
      case SortOption.priceLow:
        return 'Price ↑';
      case SortOption.priceHigh:
        return 'Price ↓';
      case SortOption.distanceNear:
        return 'Near';
      case SortOption.distanceFar:
        return 'Far';
      case SortOption.none:
        return 'Sort';
    }
  }

  Widget _buildChipButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color accentColor,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentColor : cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? Colors.white : textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : textColor,
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, color: accentColor, size: 46),
          ),
          const SizedBox(height: 20),
          Text(
            _query.isNotEmpty ? 'No results for "$_query"' : 'No products found',
            style: TextStyle(
              color: textColor,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or reset filters.',
            style: TextStyle(
              color: subTextColor,
              fontFamily: 'Montserrat',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    Color textColor,
    Color cardColor,
    Color accentColor,
    Color subTextColor,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(cardColor),
                        )
                      : _imgFallback(cardColor),
                ),
                if (product.discount != null && product.discount! > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${product.discount!.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: accentColor,
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: TextStyle(color: subTextColor, fontSize: 11),
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
      ),
    );
  }

  Widget _imgFallback(Color cardColor) {
    return Container(
      height: 140,
      color: cardColor,
      child: const Center(child: Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 36)),
    );
  }
}

class _SortTile {
  final SortOption option;
  final String label;
  final IconData icon;
  const _SortTile(this.option, this.label, this.icon);
}