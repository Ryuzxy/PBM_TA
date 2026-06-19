import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/product.dart';
import '../Models/banner_model.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _currentTab = 0;
  int _analyticsTab = 0;
  String? _userPhotoUrl;
  String _userInitials = 'A';
  String _adminName = 'Dominique Ch.';
  String _adminLocation = '';

  final TextEditingController _peopleSearchController = TextEditingController();
  String _peopleFilterRole = 'All';

  final TextEditingController _productsSearchController = TextEditingController();

  int _productSubTab = 1; // 1 = All Products, 0 = Find Product
  int _productsCurrentPage = 1;
  final List<String> _productsSelectedCategories = [];
  final List<String> _productsSelectedLocations = [];
  final List<String> _productsSelectedStockStatuses = [];

  // Find Product Advanced Search Controllers
  final TextEditingController _findProductNameController = TextEditingController();
  final TextEditingController _findProductMinPriceController = TextEditingController();
  final TextEditingController _findProductMaxPriceController = TextEditingController();
  final TextEditingController _findProductDescController = TextEditingController();
  final TextEditingController _findProductMinStockController = TextEditingController();
  final TextEditingController _findProductMaxStockController = TextEditingController();
  String _findProductCategory = 'All';
  String _findProductLocation = 'All';
  bool _findProductOnlyDiscount = false;

  // Reports/Marketing State Properties
  int _marketingSubTab = 1; // 1 = Find Promo, 0 = Promo Timetable, 2 = Customer Feedback, 3 = Quizzes, 4 = Promo Registration
  String _filterPromoType = 'All';
  String _filterPromoCategory = 'All';
  String _filterPromoSeller = 'All';
  String _filterPromoPeriod = 'All';
  DateTime? _filterPromoStartDate;
  DateTime? _filterPromoEndDate;
  bool _filterPromoActual = true;
  bool _filterShowInactive = false;
  final TextEditingController _promoSearchQueryController = TextEditingController();

  // Calendar State Properties
  int _calendarSelectedYear = 2026;
  String _calendarSelectedBranch = 'All';

  final List<Map<String, dynamic>> _calendarEventsList = [
    {'date': '2026-01-01', 'title': 'Libur Tahun Baru 2026', 'type': 'holiday'},
    {'date': '2026-01-25', 'title': 'Promo Imlek Discount', 'type': 'promo'},
    {'date': '2026-02-14', 'title': 'Valentine Flash Sale', 'type': 'promo'},
    {'date': '2026-03-29', 'title': 'Libur Hari Raya Nyepi', 'type': 'holiday'},
    {'date': '2026-04-03', 'title': 'Libur Wafat Isa Almasih', 'type': 'holiday'},
    {'date': '2026-04-18', 'title': 'Promo Ramadhan Mega Deal', 'type': 'promo'},
    {'date': '2026-04-19', 'title': 'Promo Ramadhan Mega Deal', 'type': 'promo'},
    {'date': '2026-05-01', 'title': 'Libur Hari Buruh', 'type': 'holiday'},
    {'date': '2026-05-13', 'title': 'Libur Hari Raya Waisak', 'type': 'holiday'},
    {'date': '2026-05-25', 'title': 'Promo Gajian Payday Sale', 'type': 'promo'},
    {'date': '2026-06-01', 'title': 'Libur Hari Lahir Pancasila', 'type': 'holiday'},
    {'date': '2026-06-18', 'title': 'Libur Tahun Baru Islam', 'type': 'holiday'},
    {'date': '2026-07-25', 'title': 'Promo Back to School', 'type': 'promo'},
    {'date': '2026-08-17', 'title': 'Libur Hari Kemerdekaan RI', 'type': 'holiday'},
    {'date': '2026-09-09', 'title': '9.9 Super Shopping Day', 'type': 'promo'},
    {'date': '2026-10-10', 'title': '10.10 Brand Festival', 'type': 'promo'},
    {'date': '2026-11-11', 'title': '11.11 Global Shopping Festival', 'type': 'promo'},
    {'date': '2026-12-12', 'title': 'Harbolnas 12.12 Mega Sale', 'type': 'promo'},
    {'date': '2026-12-25', 'title': 'Libur Hari Raya Natal', 'type': 'holiday'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _peopleSearchController.dispose();
    _productsSearchController.dispose();
    _findProductNameController.dispose();
    _findProductMinPriceController.dispose();
    _findProductMaxPriceController.dispose();
    _findProductDescController.dispose();
    _findProductMinStockController.dispose();
    _findProductMaxStockController.dispose();
    _promoSearchQueryController.dispose();
    super.dispose();
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
          if (name.isNotEmpty) {
            _adminName = name;
            _userInitials = name[0].toUpperCase();
          }
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

  Widget _buildProfileAvatar(Color accentColor, double radius) {
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: accentColor,
        backgroundImage: NetworkImage(_userPhotoUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: accentColor,
      child: Text(
        _userInitials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius - 2,
        ),
      ),
    );
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const String cloudName = "daiw6umes";
    const String uploadPreset = "smartdrop_preset";

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonDecoded = jsonDecode(responseData);
      return jsonDecoded['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed. Status Code: ${response.statusCode}');
    }
  }

  void _showProductForm({Product? product}) {
    final titleController = TextEditingController(text: product?.title ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final oldPriceController = TextEditingController(text: product?.oldPrice?.toString() ?? '');
    final discountController = TextEditingController(text: product?.discount?.toString() ?? '');
    final initialLocation = (product?.location != null && product!.location!.isNotEmpty)
        ? product.location!
        : (_adminLocation.isNotEmpty ? _adminLocation : 'Official Store');
    final locationController = TextEditingController(text: initialLocation);
    final stockController = TextEditingController(text: product?.stock.toString() ?? '10');

    File? pickedImageFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                product == null ? 'Add Product' : 'Edit Product',
                style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker & Preview area
                    GestureDetector(
                      onTap: isUploading
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (pickedFile != null) {
                                setDialogState(() {
                                  pickedImageFile = File(pickedFile.path);
                                });
                              }
                            },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: pickedImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  pickedImageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : (product?.imageUrl != null && product!.imageUrl.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pilih Gambar Produk',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isUploading) ...[
                      const LinearProgressIndicator(color: Color(0xFF27AE60)),
                      const SizedBox(height: 8),
                      const Text(
                        'Mengunggah gambar ke Cloudinary...',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', hintText: 'Nama Produk'),
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description', hintText: 'Deskripsi singkat produk'),
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price', hintText: 'Harga (Rp)'),
                      keyboardType: TextInputType.number,
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: oldPriceController,
                      decoration: const InputDecoration(labelText: 'Old Price (Optional)'),
                      keyboardType: TextInputType.number,
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: discountController,
                      decoration: const InputDecoration(labelText: 'Discount (Optional)'),
                      keyboardType: TextInputType.number,
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location (e.g. Jakarta)'),
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      enabled: !isUploading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          final priceText = priceController.text.trim();
                          final stockText = stockController.text.trim();

                          if (title.isEmpty || desc.isEmpty || priceText.isEmpty || stockText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan lengkapi Title, Description, Price, dan Stock!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final price = double.tryParse(priceText) ?? 0.0;
                          final stock = int.tryParse(stockText) ?? 0;

                          setDialogState(() {
                            isUploading = true;
                          });

                          String finalImageUrl = product?.imageUrl ?? '';
                          try {
                            if (pickedImageFile != null) {
                              final url = await _uploadImageToCloudinary(pickedImageFile!);
                              if (url != null) {
                                finalImageUrl = url;
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              isUploading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal unggah ke Cloudinary: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }

                          final newProduct = Product(
                            id: product?.id,
                            title: title,
                            description: desc,
                            price: price,
                            oldPrice: double.tryParse(oldPriceController.text),
                            discount: double.tryParse(discountController.text),
                            imageUrl: finalImageUrl,
                            location: locationController.text,
                            rating: product?.rating ?? 0.0,
                            reviews: product?.reviews ?? 0,
                            stock: stock,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dashboard Overview Tab (Figma Redesign)
  Widget _buildDashboardOverviewTab(AppTheme theme) {
    final subTextColor = theme.subTextColor;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Add widget green button (Figma #27AE60)
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add, color: Colors.white, size: 16),
            label: const Text(
              'Add widget',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Montserrat',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Combined Widget: Analisis & Statistik
        _buildWidgetCard(
          title: 'Analisis & Statistik',
          subtitle: _analyticsTab == 0
              ? 'Kategori Produk Terunggah'
              : 'Analisis Pengguna & Statistik Laporan',
          subTextColor: subTextColor,
          child: Column(
            children: [
              // Segmented Tab Selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _analyticsTab = 0;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _analyticsTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _analyticsTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Text(
                            'Produk',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _analyticsTab == 0 ? Colors.black : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _analyticsTab = 1;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _analyticsTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _analyticsTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Text(
                            'Pengguna & Laporan',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _analyticsTab == 1 ? Colors.black : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chart Container
              _analyticsTab == 0
                  ? _buildDynamicProductChart(subTextColor)
                  : _buildCombinedUserReportView(subTextColor),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Widget 3: Laporan Pengguna (User Reports)
        _buildWidgetCard(
          title: 'Laporan Pengguna',
          subtitle: 'Aduan & Masalah Aktif',
          subTextColor: subTextColor,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Gagal memuat aduan pengguna', style: TextStyle(color: Colors.redAccent)));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    'Tidak ada aduan / laporan aktif.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: subTextColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Column(
                children: docs.take(5).map((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final reporter = data['reporter'] ?? 'Anonim';
                  final target = data['target'] ?? '-';
                  final titleText = data['title'] ?? 'Laporan';
                  final issue = data['issue'] ?? '';
                  final status = data['status'] ?? 'Pending';
                  
                  // Calculate time / date string
                  final timestamp = data['timestamp'] as Timestamp?;
                  String timeStr = 'Baru saja';
                  if (timestamp != null) {
                    final diff = DateTime.now().difference(timestamp.toDate());
                    if (diff.inMinutes < 60) {
                      timeStr = '${diff.inMinutes} menit yang lalu';
                    } else if (diff.inHours < 24) {
                      timeStr = '${diff.inHours} jam yang lalu';
                    } else {
                      timeStr = '${diff.inDays} hari yang lalu';
                    }
                  }

                  Color statusColor = const Color(0xFFEB5757);
                  Color bgColor = const Color(0xFFFDE8E8);
                  if (status == 'Investigating') {
                    statusColor = const Color(0xFFF2C94C);
                    bgColor = const Color(0xFFFEF9E7);
                  } else if (status == 'Resolved') {
                    statusColor = const Color(0xFF27AE60);
                    bgColor = const Color(0xFFE8F8F5);
                  }

                  final isLast = docs.take(5).last.id == doc.id;

                  return Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showReportAdminOptions(doc.id, status),
                        child: _buildReportTile(
                          reporter: reporter,
                          target: 'Target: $target ($titleText)',
                          issue: issue,
                          time: timeStr,
                          status: status,
                          statusColor: statusColor,
                          bgColor: bgColor,
                        ),
                      ),
                      if (!isLast) const Divider(height: 16, thickness: 0.5),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Widget 4: Aktivitas & Log Aplikasi (App Events)
        _buildWidgetCard(
          title: 'Aktivitas & Log Aplikasi',
          subtitle: 'Log Transaksi & Aktivitas Terbaru',
          subTextColor: subTextColor,
          child: Column(
            children: [
              _buildEventLogTile(
                icon: Icons.handshake,
                iconColor: const Color(0xFF27AE60),
                title: 'Transaksi COD Berhasil',
                desc: 'COD antara Pembeli rudi@mail.com & Penjual Store_B selesai di Safe Zone Sudirman',
                time: '5 menit yang lalu',
              ),
              const Divider(height: 16, thickness: 0.5),
              _buildEventLogTile(
                icon: Icons.location_on,
                iconColor: const Color(0xFF2F80ED),
                title: 'Safe Zone Geofence Triggered',
                desc: 'Pembeli melani@mail.com memasuki radius Safe Zone Pos Polisi Thamrin',
                time: '15 menit yang lalu',
              ),
              const Divider(height: 16, thickness: 0.5),
              _buildEventLogTile(
                icon: Icons.person_add,
                iconColor: const Color(0xFFBB6BD9),
                title: 'Pengguna Baru Terdaftar',
                desc: 'budi.santoso@mail.com telah mendaftar sebagai Penjual baru',
                time: '45 menit yang lalu',
              ),
              const Divider(height: 16, thickness: 0.5),
              _buildEventLogTile(
                icon: Icons.add_shopping_cart,
                iconColor: const Color(0xFFF2994A),
                title: 'Produk Baru Diunggah',
                desc: 'Produk "Jaket Parka Anti Air" berhasil ditambahkan oleh Seller Store_C',
                time: '1 jam yang lalu',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWidgetCard({
    required String title,
    required String? subtitle,
    required Color subTextColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: subTextColor.withValues(alpha: 0.7),
                fontFamily: 'Roboto',
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4F4F4F),
            fontFamily: 'Roboto',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildReportTile({
    required String reporter,
    required String target,
    required String issue,
    required String time,
    required String status,
    required Color statusColor,
    required Color bgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pelapor: $reporter',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            target,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLogTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportAdminOptions(String reportId, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Status Laporan', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pending_actions, color: Color(0xFFEB5757)),
                title: const Text('Pending'),
                trailing: currentStatus == 'Pending' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'Pending'});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: Color(0xFFF2C94C)),
                title: const Text('Investigating'),
                trailing: currentStatus == 'Investigating' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'Investigating'});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF27AE60)),
                title: const Text('Resolved'),
                trailing: currentStatus == 'Resolved' ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'Resolved'});
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicProductChart(Color subTextColor) {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final products = snapshot.data ?? [];
        
        int pak = 0;
        int sep = 0;
        int aks = 0;
        if (products.isEmpty) {
          pak = 15;
          sep = 10;
          aks = 5;
        } else {
          for (var p in products) {
            final title = p.title.toLowerCase();
            final desc = p.description.toLowerCase();
            if (title.contains('pakaian') || title.contains('baju') || title.contains('kaos') || 
                title.contains('jaket') || title.contains('kemeja') || title.contains('celana') || 
                title.contains('dress') || title.contains('hijab') || desc.contains('pakaian') || 
                desc.contains('baju')) {
              pak++;
            } else if (title.contains('sepatu') || title.contains('sandal') || title.contains('heels') || 
                       title.contains('sneakers') || title.contains('boots') || desc.contains('sepatu') || 
                       desc.contains('sandal')) {
              sep++;
            } else {
              aks++;
            }
          }
        }

        double maxScale = [pak, sep, aks].reduce((a, b) => a > b ? a : b).toDouble();
        if (maxScale < 10) maxScale = 10;

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: ProductStatisticsPainter(
                  pakaianCount: pak.toDouble(),
                  sepatuCount: sep.toDouble(),
                  aksesorisCount: aks.toDouble(),
                  maxScale: maxScale,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFFF2994A), 'Pakaian ($pak)'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFF00B2A9), 'Sepatu ($sep)'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFFBB6BD9), 'Aksesoris ($aks)'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCombinedUserReportView(Color subTextColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    const Text(
                      'Tipe Pengguna',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDynamicUserChartContent(subTextColor, isCompact: true),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 240,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    const Text(
                      'Grafik Laporan Masalah',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDynamicReportChartContent(subTextColor, isCompact: true),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              const Text(
                'Tipe Pengguna',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildDynamicUserChartContent(subTextColor, isCompact: false),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              const Text(
                'Grafik Laporan Masalah',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildDynamicReportChartContent(subTextColor, isCompact: false),
            ],
          );
        }
      },
    );
  }

  Widget _buildDynamicUserChartContent(Color subTextColor, {required bool isCompact}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: isCompact ? 140 : 180,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        
        int buyers = 0;
        int sellers = 0;
        int admins = 0;
        if (docs.isEmpty) {
          buyers = 60;
          sellers = 35;
          admins = 5;
        } else {
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final role = (data['role'] as String? ?? 'buyer').toLowerCase();
            if (role == 'admin') {
              admins++;
            } else if (role == 'seller') {
              sellers++;
            } else {
              buyers++;
            }
          }
        }

        int total = buyers + sellers + admins;
        double buyPct = total > 0 ? (buyers / total * 100) : 60.0;
        double sellPct = total > 0 ? (sellers / total * 100) : 35.0;
        double admPct = total > 0 ? (admins / total * 100) : 5.0;

        return Column(
          children: [
            SizedBox(
              height: isCompact ? 140 : 180,
              width: isCompact ? 140 : 180,
              child: CustomPaint(
                size: Size(isCompact ? 140 : 180, isCompact ? 140 : 180),
                painter: UserAnalysisDonutPainter(
                  buyers: buyPct,
                  sellers: sellPct,
                  admins: admPct,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFFBB6BD9), 'Pembeli: $buyers (${buyPct.toStringAsFixed(0)}%)'),
                _buildLegendItem(const Color(0xFF27AE60), 'Penjual: $sellers (${sellPct.toStringAsFixed(0)}%)'),
                _buildLegendItem(const Color(0xFFEB5757), 'Admin: $admins (${admPct.toStringAsFixed(0)}%)'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDynamicReportChartContent(Color subTextColor, {required bool isCompact}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: isCompact ? 140 : 180,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        
        final Map<String, int> dateCounts = {};
        final List<String> sortedDates = [];
        
        final today = DateTime.now();
        final formatter = (DateTime dt) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
          return '${dt.day} ${months[dt.month - 1]}';
        };

        for (int i = 4; i >= 0; i--) {
          final dt = today.subtract(Duration(days: i));
          final dateStr = formatter(dt);
          dateCounts[dateStr] = 0;
          sortedDates.add(dateStr);
        }

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final dateStr = formatter(timestamp.toDate());
            if (dateCounts.containsKey(dateStr)) {
              dateCounts[dateStr] = (dateCounts[dateStr] ?? 0) + 1;
            }
          }
        }

        double maxScale = dateCounts.values.isEmpty ? 5 : dateCounts.values.reduce((a, b) => a > b ? a : b).toDouble();
        if (maxScale < 5) maxScale = 5;

        int totalAduan = dateCounts.values.isEmpty ? 0 : dateCounts.values.reduce((a, b) => a + b);

        return Column(
          children: [
            SizedBox(
              height: isCompact ? 140 : 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: ReportStatisticsPainter(
                  dateCounts: dateCounts,
                  sortedDates: sortedDates,
                  maxScale: maxScale,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFFEB5757), 'Jumlah Pelapor (Total: $totalAduan)'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 24),
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

        final allProducts = snapshot.data ?? [];

        // Category helper
        String getProductCategory(Product p) {
          final title = p.title.toLowerCase();
          final desc = p.description.toLowerCase();
          if (title.contains('pakaian') || title.contains('baju') || title.contains('kaos') || 
              title.contains('jaket') || title.contains('kemeja') || title.contains('celana') || 
              title.contains('dress') || title.contains('hijab') || desc.contains('pakaian') || 
              desc.contains('baju')) {
            return 'Pakaian';
          } else if (title.contains('sepatu') || title.contains('sandal') || title.contains('heels') || 
                     title.contains('sneakers') || title.contains('boots') || desc.contains('sepatu') || 
                     desc.contains('sandal')) {
            return 'Sepatu';
          } else {
            return 'Aksesoris';
          }
        }

        // Extract unique locations dynamically
        final allLocations = allProducts
            .map((p) => p.location?.trim() ?? 'Official Store')
            .where((loc) => loc.isNotEmpty)
            .toSet()
            .toList();
        if (allLocations.isEmpty) {
          allLocations.add('Official Store');
        }

        // Apply filters
        final query = _productsSearchController.text.toLowerCase().trim();
        var filteredProducts = allProducts.where((p) {
          final title = p.title.toLowerCase();
          final desc = p.description.toLowerCase();
          final category = getProductCategory(p);
          final location = p.location ?? 'Official Store';
          final stock = p.stock;

          // Search query check
          final matchesSearch = title.contains(query) || desc.contains(query);
          if (!matchesSearch) return false;

          // Category checklist check
          if (_productsSelectedCategories.isNotEmpty) {
            if (!_productsSelectedCategories.contains(category)) return false;
          }

          // Location checklist check
          if (_productsSelectedLocations.isNotEmpty) {
            if (!_productsSelectedLocations.contains(location)) return false;
          }

          // Stock status checklist check
          if (_productsSelectedStockStatuses.isNotEmpty) {
            bool matchesStock = false;
            for (var status in _productsSelectedStockStatuses) {
              if (status == 'In Stock' && stock > 5) matchesStock = true;
              if (status == 'Low Stock' && stock >= 1 && stock <= 5) matchesStock = true;
              if (status == 'Out of Stock' && stock == 0) matchesStock = true;
            }
            if (!matchesStock) return false;
          }

          return true;
        }).toList();

        // If in advanced search mode (Find Product tab), we apply advanced search criteria
        if (_productSubTab == 0) {
          filteredProducts = allProducts.where((p) {
            final title = p.title.toLowerCase();
            final desc = p.description.toLowerCase();
            final category = getProductCategory(p);
            final location = p.location ?? 'Official Store';
            final stock = p.stock;
            final price = p.price;

            // Advanced filters
            if (_findProductNameController.text.isNotEmpty) {
              if (!title.contains(_findProductNameController.text.toLowerCase().trim())) return false;
            }
            if (_findProductDescController.text.isNotEmpty) {
              if (!desc.contains(_findProductDescController.text.toLowerCase().trim())) return false;
            }
            if (_findProductMinPriceController.text.isNotEmpty) {
              final min = double.tryParse(_findProductMinPriceController.text) ?? 0.0;
              if (price < min) return false;
            }
            if (_findProductMaxPriceController.text.isNotEmpty) {
              final max = double.tryParse(_findProductMaxPriceController.text) ?? double.infinity;
              if (price > max) return false;
            }
            if (_findProductMinStockController.text.isNotEmpty) {
              final min = int.tryParse(_findProductMinStockController.text) ?? 0;
              if (stock < min) return false;
            }
            if (_findProductMaxStockController.text.isNotEmpty) {
              final max = int.tryParse(_findProductMaxStockController.text) ?? 999999;
              if (stock > max) return false;
            }
            if (_findProductCategory != 'All') {
              if (category != _findProductCategory) return false;
            }
            if (_findProductLocation != 'All') {
              if (location != _findProductLocation) return false;
            }
            if (_findProductOnlyDiscount) {
              if (p.discount == null || p.discount! <= 0) return false;
            }

            return true;
          }).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tab Selector (Find Product vs All Products)
                  _buildSubTabHeader(),
                  const SizedBox(height: 20),

                  // 2. Tab Content
                  if (_productSubTab == 0)
                    _buildFindProductTab(allLocations)
                  else
                    _buildAllProductsTab(allProducts, filteredProducts, allLocations, isWide),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubTabHeader() {
    return Row(
      children: [
        // Find Product Tab Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _productSubTab = 0;
              });
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: _productSubTab == 0 ? const Color(0xFF2F80ED) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _productSubTab == 0
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2F80ED).withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 26,
                    child: Icon(
                      Icons.search,
                      size: 40,
                      color: _productSubTab == 0 ? Colors.white : const Color(0xFF2F80ED),
                    ),
                  ),
                  Positioned(
                    left: 76,
                    top: 36,
                    child: Text(
                      'Find product',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: _productSubTab == 0 ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // All Products Tab Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _productSubTab = 1;
              });
            },
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: _productSubTab == 1 ? const Color(0xFF2F80ED) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: _productSubTab == 1
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2F80ED).withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 26,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: _productSubTab == 1 ? Colors.white : const Color(0xFF2F80ED),
                    ),
                  ),
                  Positioned(
                    left: 76,
                    top: 36,
                    child: Text(
                      'All products',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: _productSubTab == 1 ? Colors.white : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFindProductTab(List<String> locations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Product Search',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isFormWide = constraints.maxWidth >= 600;
              
              Widget buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F4F4F), fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                );
              }

              Widget buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F4F4F), fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: value,
                          isExpanded: true,
                          items: items.map((val) {
                            return DropdownMenuItem<String>(
                              value: val,
                              child: Text(val, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (isFormWide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: buildTextField('Product Name', _findProductNameController, 'Enter product name...')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildDropdownField(
                            'Category',
                            _findProductCategory,
                            ['All', 'Pakaian', 'Sepatu', 'Aksesoris'],
                            (val) {
                              if (val != null) setState(() => _findProductCategory = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: buildTextField('Min Price (Rp)', _findProductMinPriceController, 'e.g. 50000', isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: buildTextField('Max Price (Rp)', _findProductMaxPriceController, 'e.g. 500000', isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: buildTextField('Description Keyword', _findProductDescController, 'e.g. bahan katun...')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: buildDropdownField(
                            'Location / Store Origin',
                            _findProductLocation,
                            ['All', ...locations],
                            (val) {
                              if (val != null) setState(() => _findProductLocation = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: buildTextField('Min Stock', _findProductMinStockController, 'e.g. 0', isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: buildTextField('Max Stock', _findProductMaxStockController, 'e.g. 100', isNumber: true)),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    buildTextField('Product Name', _findProductNameController, 'Enter product name...'),
                    const SizedBox(height: 16),
                    buildDropdownField(
                      'Category',
                      _findProductCategory,
                      ['All', 'Pakaian', 'Sepatu', 'Aksesoris'],
                      (val) {
                        if (val != null) setState(() => _findProductCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    buildTextField('Min Price (Rp)', _findProductMinPriceController, 'e.g. 50000', isNumber: true),
                    const SizedBox(height: 16),
                    buildTextField('Max Price (Rp)', _findProductMaxPriceController, 'e.g. 500000', isNumber: true),
                    const SizedBox(height: 16),
                    buildTextField('Description Keyword', _findProductDescController, 'e.g. bahan katun...'),
                    const SizedBox(height: 16),
                    buildDropdownField(
                      'Location / Store Origin',
                      _findProductLocation,
                      ['All', ...locations],
                      (val) {
                        if (val != null) setState(() => _findProductLocation = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    buildTextField('Min Stock', _findProductMinStockController, 'e.g. 0', isNumber: true),
                    const SizedBox(height: 16),
                    buildTextField('Max Stock', _findProductMaxStockController, 'e.g. 100', isNumber: true),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          // Checkbox row
          Row(
            children: [
              Checkbox(
                value: _findProductOnlyDiscount,
                onChanged: (val) {
                  if (val != null) setState(() => _findProductOnlyDiscount = val);
                },
                activeColor: const Color(0xFF2F80ED),
              ),
              const Expanded(
                child: Text(
                  'Only show discounted products (with promo/discounts)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4F4F4F), fontFamily: 'Roboto'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _findProductNameController.clear();
                    _findProductMinPriceController.clear();
                    _findProductMaxPriceController.clear();
                    _findProductDescController.clear();
                    _findProductMinStockController.clear();
                    _findProductMaxStockController.clear();
                    _findProductCategory = 'All';
                    _findProductLocation = 'All';
                    _findProductOnlyDiscount = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8E8E93)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Clear', style: TextStyle(color: Color(0xFF4F4F4F), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _productSubTab = 1; // Switch back to list view to show results
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsTab(List<Product> allProducts, List<Product> filteredProducts, List<String> locations, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats summary card
        _buildInventoryStatsCard(allProducts),
        const SizedBox(height: 20),

        // Split Layout (Filter Checklist + Table)
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Filter Card
              Expanded(
                flex: 3,
                child: _buildFilterCard(locations),
              ),
              const SizedBox(width: 16),
              // Right: Table
              Expanded(
                flex: 7,
                child: _buildProductsTableCard(filteredProducts),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterCard(locations),
              const SizedBox(height: 16),
              _buildProductsTableCard(filteredProducts),
            ],
          ),
      ],
    );
  }

  Widget _buildInventoryStatsCard(List<Product> allProducts) {
    // Stats calculation
    int pak = 0;
    int sep = 0;
    int aks = 0;
    int readyStock = 0;
    int lowStock = 0;
    int outOfStock = 0;
    int discounted = 0;
    int newArrival = 0;
    int totalStock = 0;

    for (var p in allProducts) {
      final stock = p.stock;
      totalStock += stock;

      // Category scanner logic
      final title = p.title.toLowerCase();
      final desc = p.description.toLowerCase();
      if (title.contains('pakaian') || title.contains('baju') || title.contains('kaos') || 
          title.contains('jaket') || title.contains('kemeja') || title.contains('celana') || 
          title.contains('dress') || title.contains('hijab') || desc.contains('pakaian') || 
          desc.contains('baju')) {
        pak++;
      } else if (title.contains('sepatu') || title.contains('sandal') || title.contains('heels') || 
                 title.contains('sneakers') || title.contains('boots') || desc.contains('sepatu') || 
                 desc.contains('sandal')) {
        sep++;
      } else {
        aks++;
      }

      // Stock status
      if (stock > 5) {
        readyStock++;
      } else if (stock >= 1) {
        lowStock++;
      } else {
        outOfStock++;
      }

      // Promo / discount
      if (p.discount != null && p.discount! > 0) {
        discounted++;
      }
      if (p.isNewArrival) {
        newArrival++;
      }
    }

    Widget buildStatCol(String title, int count) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Roboto'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isNarrow = constraints.maxWidth < 480;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'List of active products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exporting products to Excel...')),
                        );
                      },
                      icon: const Icon(Icons.download, color: Color(0xFF2F80ED), size: 16),
                      label: const Text('Export to Excel', style: TextStyle(color: Color(0xFF2F80ED), fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2F80ED), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'List of active products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exporting products to Excel...')),
                      );
                    },
                    icon: const Icon(Icons.download, color: Color(0xFF2F80ED), size: 16),
                    label: const Text('Export to Excel', style: TextStyle(color: Color(0xFF2F80ED), fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2F80ED), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Scrollable statistics horizontal list
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildStatCol('Pakaian', pak),
                _buildStatDivider(),
                buildStatCol('Sepatu', sep),
                _buildStatDivider(),
                buildStatCol('Aksesoris', aks),
                _buildStatDivider(),
                buildStatCol('Ready Stock', readyStock),
                _buildStatDivider(),
                buildStatCol('Low Stock', lowStock),
                _buildStatDivider(),
                buildStatCol('Out of Stock', outOfStock),
                _buildStatDivider(),
                buildStatCol('Promo Diskon', discounted),
                _buildStatDivider(),
                buildStatCol('New Arrival', newArrival),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          // Summary text at the bottom right
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Total Stock: $totalStock',
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
              ),
              Text(
                'Out of Stock: $outOfStock',
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
              ),
              Text(
                'Total: ${allProducts.length}',
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildFilterCard(List<String> locations) {
    Widget buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Roboto'),
        ),
      );
    }

    Widget buildCheckboxTile(String label, List<String> targetList, VoidCallback onChanged) {
      final bool isChecked = targetList.contains(label);
      return GestureDetector(
        onTap: () {
          if (isChecked) {
            targetList.remove(label);
          } else {
            targetList.add(label);
          }
          onChanged();
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFF2F80ED) : Colors.white,
                  border: Border.all(color: isChecked ? Colors.transparent : Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4F4F4F), fontFamily: 'Roboto'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          buildSectionTitle('Categories'),
          ...['Pakaian', 'Sepatu', 'Aksesoris'].map((cat) {
            return buildCheckboxTile(cat, _productsSelectedCategories, () => setState(() {}));
          }),
          buildSectionTitle('Locations / Stores'),
          ...locations.map((loc) {
            return buildCheckboxTile(loc, _productsSelectedLocations, () => setState(() {}));
          }),
          buildSectionTitle('Stock Status'),
          ...['In Stock', 'Low Stock', 'Out of Stock'].map((status) {
            return buildCheckboxTile(status, _productsSelectedStockStatuses, () => setState(() {}));
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _productsSelectedCategories.clear();
                  _productsSelectedLocations.clear();
                  _productsSelectedStockStatuses.clear();
                  _productsSearchController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8E8E93)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Clear All Filters',
                style: TextStyle(color: Color(0xFF4F4F4F), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Roboto'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTableCard(List<Product> products) {
    final int totalItems = products.length;
    final int itemsPerPage = 8;
    final int totalPages = (totalItems / itemsPerPage).ceil();
    final int maxPagesToShow = totalPages == 0 ? 1 : totalPages;

    if (_productsCurrentPage > maxPagesToShow) {
      _productsCurrentPage = maxPagesToShow;
    }
    if (_productsCurrentPage < 1) {
      _productsCurrentPage = 1;
    }

    final int startIndex = (_productsCurrentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > totalItems) {
      endIndex = totalItems;
    }

    final List<Product> pageProducts = totalItems == 0 ? [] : products.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, boxConstraints) {
              final bool isNarrow = boxConstraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found: $totalItems',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: TextField(
                        controller: _productsSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search within results...',
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93), size: 16),
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.black, fontSize: 12),
                        onChanged: (_) => setState(() {
                          _productsCurrentPage = 1;
                        }),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found: $totalItems',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    height: 36,
                    child: TextField(
                      controller: _productsSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search within results...',
                        hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93), size: 16),
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                      onChanged: (_) => setState(() {
                        _productsCurrentPage = 1;
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: pageProducts.isEmpty
                      ? [
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                'Tidak ada produk ditemukan.',
                                style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Roboto'),
                              ),
                            ),
                          )
                        ]
                      : pageProducts.map((p) => _buildProductMobileCard(p)).toList(),
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text('Product / Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87, fontFamily: 'Roboto')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87, fontFamily: 'Roboto')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Harga / Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87, fontFamily: 'Roboto')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Asal Toko / Seller', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87, fontFamily: 'Roboto')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87, fontFamily: 'Roboto')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pageProducts.isEmpty)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'Tidak ada produk ditemukan.',
                          style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Roboto'),
                        ),
                      ),
                    )
                  else
                    ...pageProducts.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value;
                      final bool isEven = idx % 2 == 0;
                      return _buildProductTableRow(p, isEven);
                    }),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (totalPages > 0) _buildPaginationBar(totalPages),
        ],
      ),
    );
  }

  Widget _buildProductTableRow(Product product, bool isEven) {
    final bool isNetworkImage = product.imageUrl.startsWith('http://') || product.imageUrl.startsWith('https://');
    final bool isAssetImage = product.imageUrl.startsWith('assets/');

    Widget thumbnailWidget;
    if (isNetworkImage) {
      thumbnailWidget = Image.network(
        product.imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    } else if (isAssetImage) {
      thumbnailWidget = Image.asset(
        product.imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    } else {
      thumbnailWidget = _buildPlaceholderImage();
    }

    String category = 'Aksesoris';
    final title = product.title.toLowerCase();
    final desc = product.description.toLowerCase();
    if (title.contains('pakaian') || title.contains('baju') || title.contains('kaos') || 
        title.contains('jaket') || title.contains('kemeja') || title.contains('celana') || 
        title.contains('dress') || title.contains('hijab') || desc.contains('pakaian') || 
        desc.contains('baju')) {
      category = 'Pakaian';
    } else if (title.contains('sepatu') || title.contains('sandal') || title.contains('heels') || 
               title.contains('sneakers') || title.contains('boots') || desc.contains('sepatu') || 
               desc.contains('sandal')) {
      category = 'Sepatu';
    }

    Color catColor = const Color(0xFFBB6BD9);
    Color catBg = const Color(0xFFF9EBFD);
    if (category == 'Pakaian') {
      catColor = const Color(0xFFF2994A);
      catBg = const Color(0xFFFEF4E9);
    } else if (category == 'Sepatu') {
      catColor = const Color(0xFF00B2A9);
      catBg = const Color(0xFFE6F7F7);
    }

    final int stock = product.stock;
    Color stockTextColor = Colors.black87;
    FontWeight stockFontWeight = FontWeight.normal;
    if (stock == 0) {
      stockTextColor = const Color(0xFFEB5757);
      stockFontWeight = FontWeight.bold;
    } else if (stock <= 5) {
      stockTextColor = const Color(0xFFF2C94C);
      stockFontWeight = FontWeight.bold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: thumbnailWidget,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, fontFamily: 'Roboto'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.description,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Roboto'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 8, fontFamily: 'Roboto'),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rp ${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok: $stock',
                  style: TextStyle(fontSize: 10, color: stockTextColor, fontWeight: stockFontWeight, fontFamily: 'Roboto'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.location ?? 'Official Store',
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500, fontFamily: 'Roboto'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.sellerName ?? 'Seller',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Roboto'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _showProductForm(product: product),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.transparent,
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF2F80ED), size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDeleteProduct(product),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.transparent,
                    child: const Icon(Icons.delete_outline, color: Color(0xFFEB5757), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Produk', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin menghapus produk "${product.title}" dari katalog?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.deleteProduct(product.id!);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Produk "${product.title}" berhasil dihapus.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEB5757)),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductMobileCard(Product product) {
    final bool isNetworkImage = product.imageUrl.startsWith('http://') || product.imageUrl.startsWith('https://');
    final bool isAssetImage = product.imageUrl.startsWith('assets/');

    Widget thumbnailWidget;
    if (isNetworkImage) {
      thumbnailWidget = Image.network(
        product.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    } else if (isAssetImage) {
      thumbnailWidget = Image.asset(
        product.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    } else {
      thumbnailWidget = _buildPlaceholderImage();
    }

    String category = 'Aksesoris';
    final title = product.title.toLowerCase();
    final desc = product.description.toLowerCase();
    if (title.contains('pakaian') || title.contains('baju') || title.contains('kaos') || 
        title.contains('jaket') || title.contains('kemeja') || title.contains('celana') || 
        title.contains('dress') || title.contains('hijab') || desc.contains('pakaian') || 
        desc.contains('baju')) {
      category = 'Pakaian';
    } else if (title.contains('sepatu') || title.contains('sandal') || title.contains('heels') || 
               title.contains('sneakers') || title.contains('boots') || desc.contains('sepatu') || 
               desc.contains('sandal')) {
      category = 'Sepatu';
    }

    Color catColor = const Color(0xFFBB6BD9);
    Color catBg = const Color(0xFFF9EBFD);
    if (category == 'Pakaian') {
      catColor = const Color(0xFFF2994A);
      catBg = const Color(0xFFFEF4E9);
    } else if (category == 'Sepatu') {
      catColor = const Color(0xFF00B2A9);
      catBg = const Color(0xFFE6F7F7);
    }

    final int stock = product.stock;
    Color stockTextColor = Colors.black87;
    if (stock == 0) {
      stockTextColor = const Color(0xFFEB5757);
    } else if (stock <= 5) {
      stockTextColor = const Color(0xFFF2C94C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: thumbnailWidget,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, fontFamily: 'Roboto'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: catBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 7, fontFamily: 'Roboto'),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Rp ${product.price.toStringAsFixed(0)} | Stok: $stock',
              style: TextStyle(fontSize: 11, color: stockTextColor, fontWeight: stock == 0 || stock <= 5 ? FontWeight.bold : FontWeight.w500, fontFamily: 'Roboto'),
            ),
            Text(
              'Toko: ${product.location ?? "Official Store"} | ${product.sellerName ?? "Seller"}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Roboto'),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showProductForm(product: product),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2F80ED), size: 16),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDeleteProduct(product),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Color(0xFFEB5757), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar(int totalPages) {
    final bool canPrev = _productsCurrentPage > 1;
    final bool canNext = _productsCurrentPage < totalPages;

    List<Widget> pageItems = [];
    
    for (int i = 1; i <= totalPages; i++) {
      if (totalPages > 6) {
        if (i == 1 || i == totalPages || (i >= _productsCurrentPage - 1 && i <= _productsCurrentPage + 1)) {
          pageItems.add(_buildPageNumberBtn(i));
        } else if (i == 2 && _productsCurrentPage > 3) {
          pageItems.add(const Text('...', style: TextStyle(color: Colors.grey)));
        } else if (i == totalPages - 1 && _productsCurrentPage < totalPages - 2) {
          pageItems.add(const Text('...', style: TextStyle(color: Colors.grey)));
        }
      } else {
        pageItems.add(_buildPageNumberBtn(i));
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: canPrev
                ? () {
                    setState(() {
                      _productsCurrentPage--;
                    });
                  }
                : null,
            child: Row(
              children: [
                Icon(Icons.chevron_left, color: canPrev ? const Color(0xFF2F80ED) : Colors.grey.shade400, size: 20),
                Text(
                  'Previous',
                  style: TextStyle(
                    color: canPrev ? const Color(0xFF2F80ED) : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ...pageItems,
          const SizedBox(width: 16),
          GestureDetector(
            onTap: canNext
                ? () {
                    setState(() {
                      _productsCurrentPage++;
                    });
                  }
                : null,
            child: Row(
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: canNext ? const Color(0xFF2F80ED) : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                ),
                Icon(Icons.chevron_right, color: canNext ? const Color(0xFF2F80ED) : Colors.grey.shade400, size: 20),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _productsCurrentPage = 1;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Showing first page of products.')),
              );
            },
            child: const Text(
              'Show all',
              style: TextStyle(
                color: Color(0xFF2F80ED),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumberBtn(int pageNum) {
    final bool isSelected = _productsCurrentPage == pageNum;
    return GestureDetector(
      onTap: () {
        setState(() {
          _productsCurrentPage = pageNum;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          pageNum.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF333333),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }

  Widget _buildMarketingTab() {
    return StreamBuilder<List<Product>>(
      stream: _firestoreService.getProducts(),
      builder: (context, productSnapshot) {
        final allProducts = productSnapshot.data ?? [];
        final allLocations = allProducts
            .map((p) => p.location?.trim() ?? 'Official Store')
            .where((loc) => loc.isNotEmpty)
            .toSet()
            .toList();
        if (allLocations.isEmpty) {
          allLocations.add('Official Store');
        }

        return StreamBuilder<List<BannerModel>>(
          stream: _firestoreService.getBanners(),
          builder: (context, bannerSnapshot) {
            final allBanners = bannerSnapshot.data ?? [];
            return _buildMarketingContent(allBanners, allLocations);
          },
        );
      },
    );
  }

  Widget _buildMarketingContent(List<BannerModel> allBanners, List<String> locations) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1. Horizontal Scrollable Sub-Tab Cards
        _buildMarketingSubTabHeader(),
        const SizedBox(height: 20),

        // 2. Active Tab Content
        if (_marketingSubTab == 0)
          _buildPromoTimetableTab(allBanners)
        else if (_marketingSubTab == 1) ...[
          _buildFindPromoTab(locations),
          const SizedBox(height: 20),
          _buildFindPromoResultsCard(allBanners),
        ] else if (_marketingSubTab == 2)
          _buildCustomerFeedbackTab()
        else if (_marketingSubTab == 3)
          _buildMarketingQuizzesTab()
        else if (_marketingSubTab == 4)
          _buildPromoRegistrationTab(),
      ],
    );
  }

  Widget _buildMarketingSubTabHeader() {
    Widget buildSubTabCard(int index, IconData icon, String title) {
      final bool isSelected = _marketingSubTab == index;
      return GestureDetector(
        onTap: () => setState(() => _marketingSubTab = index),
        child: Container(
          width: 170,
          height: 110,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2F80ED) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2F80ED).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF2F80ED),
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildSubTabCard(0, Icons.calendar_view_week, 'Promo Timetable'),
          buildSubTabCard(1, Icons.search, 'Find Promo'),
          buildSubTabCard(2, Icons.feedback_outlined, 'Customer Feedback'),
          buildSubTabCard(3, Icons.quiz_outlined, 'Marketing Quizzes'),
          buildSubTabCard(4, Icons.assignment_turned_in_outlined, 'Promo Registration'),
        ],
      ),
    );
  }

  Widget _buildFindPromoTab(List<String> locations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 700;
              
              Widget buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54, fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: value,
                          isExpanded: true,
                          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontFamily: 'Roboto')))).toList(),
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  ],
                );
              }

              Widget buildDateField(String label, DateTime? date, VoidCallback onTap) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54, fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              date == null ? 'Select' : '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: date == null ? Colors.grey : Colors.black87,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8E8E93)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (isWide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildDropdownField(
                            'Promo Type (Field of knowledge)',
                            _filterPromoType,
                            ['All', 'Discounts', 'Deals of the Day', 'Special Offers', 'Trending', 'Sponsored'],
                            (val) {
                              if (val != null) setState(() => _filterPromoType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildDropdownField(
                            'Target Category (Training)',
                            _filterPromoCategory,
                            ['All', 'Pakaian', 'Sepatu', 'Aksesoris'],
                            (val) {
                              if (val != null) setState(() => _filterPromoCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildDropdownField(
                            'Store / Location (Instructors)',
                            _filterPromoSeller,
                            ['All', ...locations],
                            (val) {
                              if (val != null) setState(() => _filterPromoSeller = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: buildDropdownField(
                            'Period',
                            _filterPromoPeriod,
                            ['All', 'Today', 'This Week', 'This Month', 'Custom'],
                            (val) {
                              if (val != null) setState(() => _filterPromoPeriod = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildDateField(
                            'Start date:',
                            _filterPromoStartDate,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _filterPromoStartDate = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildDateField(
                            'Finish date:',
                            _filterPromoEndDate,
                            () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _filterPromoEndDate = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    buildDropdownField(
                      'Promo Type (Field of knowledge)',
                      _filterPromoType,
                      ['All', 'Discounts', 'Deals of the Day', 'Special Offers', 'Trending', 'Sponsored'],
                      (val) {
                        if (val != null) setState(() => _filterPromoType = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    buildDropdownField(
                      'Target Category (Training)',
                      _filterPromoCategory,
                      ['All', 'Pakaian', 'Sepatu', 'Aksesoris'],
                      (val) {
                        if (val != null) setState(() => _filterPromoCategory = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    buildDropdownField(
                      'Store / Location (Instructors)',
                      _filterPromoSeller,
                      ['All', ...locations],
                      (val) {
                        if (val != null) setState(() => _filterPromoSeller = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    buildDropdownField(
                      'Period',
                      _filterPromoPeriod,
                      ['All', 'Today', 'This Week', 'This Month', 'Custom'],
                      (val) {
                        if (val != null) setState(() => _filterPromoPeriod = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    buildDateField(
                      'Start date:',
                      _filterPromoStartDate,
                      () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _filterPromoStartDate = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    buildDateField(
                      'Finish date:',
                      _filterPromoEndDate,
                      () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _filterPromoEndDate = picked);
                      },
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          // Radios actual/planned
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: _filterPromoActual,
                onChanged: (val) {
                  if (val != null) setState(() => _filterPromoActual = val);
                },
                activeColor: const Color(0xFF2F80ED),
              ),
              const Text('actual dates', style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
              const SizedBox(width: 24),
              Radio<bool>(
                value: false,
                groupValue: _filterPromoActual,
                onChanged: (val) {
                  if (val != null) setState(() => _filterPromoActual = val);
                },
                activeColor: const Color(0xFF2F80ED),
              ),
              const Text('planned', style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
            ],
          ),
          const SizedBox(height: 10),
          // Checkbox Show inactive promotions
          Row(
            children: [
              Checkbox(
                value: _filterShowInactive,
                onChanged: (val) {
                  if (val != null) setState(() => _filterShowInactive = val);
                },
                activeColor: const Color(0xFF2F80ED),
              ),
              const Text('Show inactive promotions', style: TextStyle(fontSize: 12, fontFamily: 'Roboto')),
            ],
          ),
          const SizedBox(height: 20),
          // Actions: Search & Clear
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _filterPromoType = 'All';
                    _filterPromoCategory = 'All';
                    _filterPromoSeller = 'All';
                    _filterPromoPeriod = 'All';
                    _filterPromoStartDate = null;
                    _filterPromoEndDate = null;
                    _filterPromoActual = true;
                    _filterShowInactive = false;
                    _promoSearchQueryController.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8E8E93)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Clear', style: TextStyle(color: Color(0xFF4F4F4F), fontWeight: FontWeight.w600, fontFamily: 'Roboto', fontSize: 13)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Roboto', fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFindPromoResultsCard(List<BannerModel> banners) {
    var filtered = banners.where((b) {
      final query = _promoSearchQueryController.text.toLowerCase().trim();
      if (query.isNotEmpty) {
        final title = b.title.toLowerCase();
        final subtitle = b.subtitle.toLowerCase();
        if (!title.contains(query) && !subtitle.contains(query)) return false;
      }

      if (_filterPromoType != 'All') {
        final type = b.type.toLowerCase();
        if (_filterPromoType == 'Discounts' && type != 'promo' && type != 'summer_sale') return false;
        if (_filterPromoType == 'Deals of the Day' && type != 'deals_of_days' && type != 'deal') return false;
        if (_filterPromoType == 'Special Offers' && type != 'special_offer' && type != 'flat_heels') return false;
        if (_filterPromoType == 'Trending' && type != 'trending') return false;
        if (_filterPromoType == 'Sponsored' && type != 'sponsored') return false;
      }

      if (_filterPromoSeller != 'All') {
        final mockLocIndex = b.id.hashCode % 3;
        final mockLoc = mockLocIndex == 0 ? 'Official Store' : (mockLocIndex == 1 ? 'Jakarta' : 'Bandung');
        if (mockLoc != _filterPromoSeller) return false;
      }

      if (_filterPromoStartDate != null) {
        final mockStart = DateTime.now().subtract(const Duration(days: 2));
        if (mockStart.isBefore(_filterPromoStartDate!)) return false;
      }
      if (_filterPromoEndDate != null) {
        final mockEnd = DateTime.now().add(const Duration(days: 5));
        if (mockEnd.isAfter(_filterPromoEndDate!)) return false;
      }

      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isNarrow = constraints.maxWidth < 450;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Found Promotions: ${filtered.length}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Montserrat'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showBannerForm(),
                          icon: const Icon(Icons.add, color: Colors.white, size: 12),
                          label: const Text('Add Promo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: TextField(
                        controller: _promoSearchQueryController,
                        decoration: InputDecoration(
                          hintText: 'Search results...',
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93), size: 16),
                          filled: true,
                          fillColor: const Color(0xFFF1F1F1),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        style: const TextStyle(color: Colors.black, fontSize: 12),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found Promotions: ${filtered.length}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Montserrat'),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showBannerForm(),
                        icon: const Icon(Icons.add, color: Colors.white, size: 14),
                        label: const Text('Add Promo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        height: 36,
                        child: TextField(
                          controller: _promoSearchQueryController,
                          decoration: InputDecoration(
                            hintText: 'Search results...',
                            hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93), size: 16),
                            filled: true,
                            fillColor: const Color(0xFFF1F1F1),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          style: const TextStyle(color: Colors.black, fontSize: 12),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Text('No promotions found matching filters.', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Roboto')),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final b = filtered[index];
                
                Color badgeColor = Colors.grey;
                Color badgeBg = Colors.grey.shade100;
                String typeLabel = b.type.toUpperCase();
                if (b.type == 'promo' || b.type == 'summer_sale') {
                  badgeColor = const Color(0xFFF2994A);
                  badgeBg = const Color(0xFFFEF4E9);
                  typeLabel = 'DISCOUNT';
                } else if (b.type == 'special_offer' || b.type == 'flat_heels') {
                  badgeColor = const Color(0xFFEB5757);
                  badgeBg = const Color(0xFFFDE8E8);
                  typeLabel = 'SPECIAL OFFER';
                } else if (b.type == 'sponsored') {
                  badgeColor = const Color(0xFF27AE60);
                  badgeBg = const Color(0xFFE8F8F5);
                  typeLabel = 'SPONSORED';
                } else if (b.type == 'deals_of_days' || b.type == 'deal') {
                  badgeColor = const Color(0xFF2F80ED);
                  badgeBg = const Color(0xFFE8F0FE);
                  typeLabel = 'DEAL OF DAY';
                } else if (b.type == 'trending') {
                  badgeColor = const Color(0xFFBB6BD9);
                  badgeBg = const Color(0xFFF9EBFD);
                  typeLabel = 'TRENDING';
                }

                final bool isNetworkImage = b.imageUrl.startsWith('http://') || b.imageUrl.startsWith('https://');
                final bool isAssetImage = b.imageUrl.startsWith('assets/');

                Widget imgWidget;
                if (isNetworkImage) {
                  imgWidget = Image.network(
                    b.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 30, color: Colors.grey),
                  );
                } else if (isAssetImage) {
                  imgWidget = Image.asset(
                    b.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 30, color: Colors.grey),
                  );
                } else {
                  imgWidget = const Icon(Icons.image, size: 30, color: Colors.grey);
                }

                final mockLocIndex = b.id.hashCode % 3;
                final mockSeller = mockLocIndex == 0 ? 'Official Store' : (mockLocIndex == 1 ? 'Maju Jaya Store' : 'Bintang Fashion');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  color: index % 2 == 0 ? Colors.white : const Color(0xFFF9F9F9),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(width: 44, height: 44, color: Colors.grey.shade100, child: imgWidget),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b.title.isNotEmpty ? b.title : 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, fontFamily: 'Roboto'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(b.subtitle.isNotEmpty ? b.subtitle : 'No Subtitle', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Roboto'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                                    child: Text(typeLabel, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 8, fontFamily: 'Roboto')),
                                  ),
                                  Text('$mockSeller (Priority: ${b.order})', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Roboto')),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showBannerForm(banner: b),
                                        child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.edit_outlined, color: Color(0xFF2F80ED), size: 16)),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _confirmDeleteBanner(b),
                                        child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.delete_outline, color: Color(0xFFEB5757), size: 16)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(width: 50, height: 50, color: Colors.grey.shade100, child: imgWidget),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.title.isNotEmpty ? b.title : 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, fontFamily: 'Roboto'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(b.subtitle.isNotEmpty ? b.subtitle : 'No Description', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Roboto'), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                              child: Text(typeLabel, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 8, fontFamily: 'Roboto')),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mockSeller, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87, fontFamily: 'Roboto')),
                                Text('Priority: ${b.order}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Roboto')),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showBannerForm(banner: b),
                                  child: Container(padding: const EdgeInsets.all(6), child: const Icon(Icons.edit_outlined, color: Color(0xFF2F80ED), size: 18)),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _confirmDeleteBanner(b),
                                  child: Container(padding: const EdgeInsets.all(6), child: const Icon(Icons.delete_outline, color: Color(0xFFEB5757), size: 18)),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPromoTimetableTab(List<BannerModel> banners) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Promo Timetable',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          ),
          const SizedBox(height: 16),
          if (banners.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(child: Text('No active promotions to schedule.')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final b = banners[index];
                final start = DateTime.now().subtract(Duration(days: index * 2));
                final end = start.add(Duration(days: 4 + index));
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_on, color: Color(0xFF2F80ED)),
                  title: Text(b.title.isNotEmpty ? b.title : 'Promo Event', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Duration: ${start.day}/${start.month} - ${end.day}/${end.month} | Priority: ${b.order}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF27AE60), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerFeedbackTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Feedback & Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: Text('No feedback / reviews submitted.')),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>? ?? {};
                  final reporter = data['reporter'] ?? 'Buyer';
                  final title = data['title'] ?? 'Feedback';
                  final issue = data['issue'] ?? 'No comment';
                  final status = data['status'] ?? 'Pending';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF1F1F1),
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('By: $reporter\nComment: "$issue"', style: const TextStyle(fontSize: 11)),
                      trailing: Chip(
                        label: Text(status, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: status == 'Resolved' ? Colors.green : (status == 'Investigating' ? Colors.orange : Colors.red),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingQuizzesTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marketing Quizzes & Surveys',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create and analyze interactive quizzes/surveys to collect buyer preferences.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildQuizItem('Customer Satisfaction Survey 2026', 'Responses: 1,248', 'Status: RUNNING', const Color(0xFF27AE60)),
          _buildQuizItem('Product Preference Poll (Pakaian vs Sepatu)', 'Responses: 532', 'Status: RUNNING', const Color(0xFF27AE60)),
          _buildQuizItem('Safe Zone Meeting Feedback Quiz', 'Responses: 219', 'Status: COMPLETED', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildQuizItem(String title, String responses, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const Icon(Icons.quiz, color: Color(0xFF2F80ED)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(responses),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoRegistrationTab() {
    final titleRegController = TextEditingController();
    final subtitleRegController = TextEditingController();
    final imageUrlRegController = TextEditingController();
    final orderRegController = TextEditingController(text: '1');
    String selectedRegType = 'promo';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Promotion Registration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleRegController,
            decoration: const InputDecoration(labelText: 'Promotion Title', hintText: 'e.g. Summer Sale Banner'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: subtitleRegController,
            decoration: const InputDecoration(labelText: 'Subtitle Description', hintText: 'e.g. Up to 50% discount on clothing'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: imageUrlRegController,
            decoration: const InputDecoration(labelText: 'Image Asset URL', hintText: 'e.g. assets/public/summer_banner.png'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: orderRegController,
            decoration: const InputDecoration(labelText: 'Display Priority Order'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedRegType,
            decoration: const InputDecoration(labelText: 'Promotion Type'),
            items: const [
              DropdownMenuItem(value: 'promo', child: Text('Promo Banner (Discount)')),
              DropdownMenuItem(value: 'summer_sale', child: Text('Summer Sale Banner')),
              DropdownMenuItem(value: 'special_offer', child: Text('Special Offer Banner')),
              DropdownMenuItem(value: 'sponsored', child: Text('Sponsored Banner')),
              DropdownMenuItem(value: 'trending', child: Text('Trending Banner')),
              DropdownMenuItem(value: 'deals_of_days', child: Text('Deals of the Day')),
            ],
            onChanged: (val) {
              if (val != null) selectedRegType = val;
            },
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final title = titleRegController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill out the Promotion Title!')),
                    );
                    return;
                  }

                  final newBanner = BannerModel(
                    id: '',
                    title: title,
                    subtitle: subtitleRegController.text.trim(),
                    imageUrl: imageUrlRegController.text.trim().isNotEmpty
                        ? imageUrlRegController.text.trim()
                        : 'assets/public/mock_banner.png',
                    type: selectedRegType,
                    order: int.tryParse(orderRegController.text) ?? 1,
                  );

                  await _firestoreService.addBanner(newBanner);

                  setState(() {
                    _marketingSubTab = 1; // Switch back to Find Promo
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Promo "${newBanner.title}" registered successfully!')),
                    );
                  }
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Register Promo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBannerForm({BannerModel? banner}) {
    final titleController = TextEditingController(text: banner?.title ?? '');
    final subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    final imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    final orderController = TextEditingController(text: banner?.order.toString() ?? '1');
    String selectedType = banner?.type ?? 'promo';

    File? pickedImageFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isNetworkImage = (banner?.imageUrl.startsWith('http://') ?? false) || (banner?.imageUrl.startsWith('https://') ?? false);
            final bool isAssetImage = banner?.imageUrl.startsWith('assets/') ?? false;

            Widget previewWidget;
            if (pickedImageFile != null) {
              previewWidget = ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  pickedImageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            } else if (banner != null && banner.imageUrl.isNotEmpty) {
              if (isNetworkImage) {
                previewWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                );
              } else if (isAssetImage) {
                previewWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                );
              } else {
                previewWidget = const Icon(Icons.image, size: 40, color: Colors.grey);
              }
            } else {
              previewWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih Gambar Promosi',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                banner == null ? 'Add Promotion Banner' : 'Edit Promotion Banner',
                style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker & Preview area
                    GestureDetector(
                      onTap: isUploading
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (pickedFile != null) {
                                setDialogState(() {
                                  pickedImageFile = File(pickedFile.path);
                                });
                              }
                            },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: previewWidget,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isUploading) ...[
                      const LinearProgressIndicator(color: Color(0xFF27AE60)),
                      const SizedBox(height: 8),
                      const Text(
                        'Mengunggah gambar ke Cloudinary...',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle (Description)'),
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (Optional if image chosen)',
                        hintText: 'or uploads from gallery above',
                      ),
                      enabled: !isUploading,
                    ),
                    TextField(
                      controller: orderController,
                      decoration: const InputDecoration(labelText: 'Display Order'),
                      keyboardType: TextInputType.number,
                      enabled: !isUploading,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Promo Type'),
                      items: const [
                        DropdownMenuItem(value: 'promo', child: Text('Promo Banner (Discount)')),
                        DropdownMenuItem(value: 'summer_sale', child: Text('Summer Sale Banner')),
                        DropdownMenuItem(value: 'special_offer', child: Text('Special Offer Banner')),
                        DropdownMenuItem(value: 'sponsored', child: Text('Sponsored Banner')),
                        DropdownMenuItem(value: 'trending', child: Text('Trending Banner')),
                        DropdownMenuItem(value: 'deals_of_days', child: Text('Deals of the Day')),
                      ],
                      onChanged: isUploading
                          ? null
                          : (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedType = val;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan lengkapi Title Promosi!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                          });

                          String finalImageUrl = imageUrlController.text.trim();
                          try {
                            if (pickedImageFile != null) {
                              final url = await _uploadImageToCloudinary(pickedImageFile!);
                              if (url != null) {
                                finalImageUrl = url;
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              isUploading = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal unggah ke Cloudinary: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }

                          if (finalImageUrl.isEmpty) {
                            finalImageUrl = 'assets/public/mock_banner.png';
                          }

                          final newBanner = BannerModel(
                            id: banner?.id ?? '',
                            title: title,
                            subtitle: subtitleController.text.trim(),
                            imageUrl: finalImageUrl,
                            type: selectedType,
                            order: int.tryParse(orderController.text) ?? 1,
                          );

                          if (banner == null) {
                            await _firestoreService.addBanner(newBanner);
                          } else {
                            await _firestoreService.updateBanner(newBanner);
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Banner "${newBanner.title}" berhasil disimpan.')),
                            );
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBanner(BannerModel banner) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Promosi', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin menghapus promosi "${banner.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.deleteBanner(banner.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Promosi "${banner.title}" berhasil dihapus.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEB5757)),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(String userId, String currentName, String currentEmail, String currentRole) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final TextEditingController emailController = TextEditingController(text: currentEmail);
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Edit Informasi Pengguna',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        prefixIcon: const Icon(Icons.person, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email pengguna',
                        prefixIcon: const Icon(Icons.email, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Peran Pengguna',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['buyer', 'seller', 'admin'].map((roleVal) {
                        final isSel = selectedRole == roleVal;
                        Color chipColor = const Color(0xFF2F80ED);
                        String displayLabel = 'Pembeli';
                        if (roleVal == 'admin') {
                          chipColor = const Color(0xFFEB5757);
                          displayLabel = 'Admin';
                        } else if (roleVal == 'seller') {
                          chipColor = const Color(0xFF27AE60);
                          displayLabel = 'Penjual';
                        }
                        return ChoiceChip(
                          label: Text(displayLabel),
                          selected: isSel,
                          selectedColor: chipColor,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setStateDialog(() {
                                selectedRole = roleVal;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newEmail = emailController.text.trim();
                    if (userId.startsWith('mock_')) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Simulasi edit pengguna berhasil disimpan!')),
                      );
                    } else {
                      await FirebaseFirestore.instance.collection('users').doc(userId).update({
                        'accountHolder': newName,
                        'email': newEmail,
                        'role': selectedRole,
                      });
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Data pengguna berhasil diperbarui.')),
                        );
                      }
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUserConfirm(String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Hapus Pengguna',
            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          ),
          content: Text('Apakah Anda yakin ingin menghapus akun $userName dari sistem SmartDrop?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (userId.startsWith('mock_')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Akun simulasi $userName berhasil dihapus')),
                  );
                } else {
                  await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Akun $userName berhasil dihapus')),
                    );
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEB5757)),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeopleTab(AppTheme theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users'));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final bool useMock = allDocs.isEmpty;

        final List<Map<String, dynamic>> userList = [];
        if (useMock) {
          userList.addAll([
            {'id': 'mock_admin', 'accountHolder': 'Dominique Ch.', 'email': 'dominique@smartdrop.com', 'role': 'admin'},
            {'id': 'mock_buyer_1', 'accountHolder': 'Alice Smith', 'email': 'alice.smith@gmail.com', 'role': 'buyer'},
            {'id': 'mock_seller_1', 'accountHolder': 'John Doe', 'email': 'john.doe@seller.com', 'role': 'seller'},
            {'id': 'mock_buyer_2', 'accountHolder': 'Rudi Hermawan', 'email': 'rudi@mail.com', 'role': 'buyer'},
            {'id': 'mock_buyer_3', 'accountHolder': 'Melani Putri', 'email': 'melani@mail.com', 'role': 'buyer'},
            {'id': 'mock_seller_2', 'accountHolder': 'Budi Santoso', 'email': 'budi.santoso@mail.com', 'role': 'seller'},
          ]);
        } else {
          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            userList.add({
              'id': doc.id,
              'accountHolder': data['accountHolder'] as String? ?? '',
              'email': data['email'] as String? ?? '',
              'role': data['role'] as String? ?? 'buyer',
            });
          }
        }

        // Filter and Search Logic
        final query = _peopleSearchController.text.toLowerCase().trim();
        final filteredUsers = userList.where((u) {
          final email = (u['email'] as String? ?? '').toLowerCase();
          final name = (u['accountHolder'] as String? ?? '').toLowerCase();
          final role = (u['role'] as String? ?? 'buyer').toLowerCase();

          final matchesSearch = email.contains(query) || name.contains(query);
          
          if (_peopleFilterRole == 'All') {
            return matchesSearch;
          } else {
            return matchesSearch && role == _peopleFilterRole.toLowerCase();
          }
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title & Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'People (${filteredUsers.length})',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    useMock ? 'Mode Simulasi (Firestore kosong)' : 'Total: ${allDocs.length}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar Field
              TextField(
                controller: _peopleSearchController,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2F80ED)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Filter Chips Role Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Admin', 'Seller', 'Buyer'].map((role) {
                    final isSelected = _peopleFilterRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(role),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _peopleFilterRole = role;
                            });
                          }
                        },
                        selectedColor: const Color(0xFF2F80ED),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Responsive Table Headers (only on wider screens)
              if (MediaQuery.of(context).size.width >= 600) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('User / Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, fontFamily: 'Roboto')),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, fontFamily: 'Roboto')),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, fontFamily: 'Roboto')),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, fontFamily: 'Roboto')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Users List Table Rows
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada pengguna ditemukan.',
                              style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Roboto'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final u = filteredUsers[index];
                          final id = u['id'] as String;
                          final email = u['email'] as String;
                          final role = u['role'] as String;
                          final name = u['accountHolder'] as String;
                          
                          // Mock active status based on ID hash
                          final bool isActive = id.hashCode % 3 != 0; 
                          final String statusText = isActive ? 'Active' : 'Offline';
                          final Color statusColor = isActive ? const Color(0xFF27AE60) : Colors.grey;

                          Color roleColor = const Color(0xFF2F80ED); // Buyer
                          Color roleBg = const Color(0xFFE8F1FD);
                          if (role == 'admin') {
                            roleColor = const Color(0xFFEB5757);
                            roleBg = const Color(0xFFFDE8E8);
                          } else if (role == 'seller') {
                            roleColor = const Color(0xFF27AE60);
                            roleBg = const Color(0xFFE8F8F5);
                          }

                          final bool isMobile = MediaQuery.of(context).size.width < 600;

                          if (isMobile) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: roleColor.withValues(alpha: 0.15),
                                      radius: 18,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name.isNotEmpty ? name : (email.isNotEmpty ? email.split('@')[0] : 'Anonim'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  email.isNotEmpty ? email : '-',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showEditUserDialog(id, name, email, role),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.manage_accounts, color: Colors.grey, size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _deleteUserConfirm(id, name),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // Name & Avatar Column
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: roleColor.withValues(alpha: 0.15),
                                            radius: 18,
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isNotEmpty ? name : (email.isNotEmpty ? email.split('@')[0] : 'Anonim'),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              email.isNotEmpty ? email : '-',
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Role Column
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: roleBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 8),
                                      ),
                                    ),
                                  ),
                                ),

                                // Status Column
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        statusText,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions Column
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Edit Role button
                                      GestureDetector(
                                        onTap: () => _showEditUserDialog(id, name, email, role),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          color: Colors.transparent,
                                          child: const Icon(Icons.manage_accounts, color: Colors.grey, size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Delete button
                                      GestureDetector(
                                        onTap: () => _deleteUserConfirm(id, name),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          color: Colors.transparent,
                                          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder simple widget
  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Under internal management development.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const days = [31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  Map<String, int> _getMonthStats(int year, int month) {
    int working = 0;
    int nonWorking = 0;
    int days = _getDaysInMonth(year, month);
    for (int day = 1; day <= days; day++) {
      int wd = DateTime(year, month, day).weekday;
      if (wd == 6 || wd == 7) {
        nonWorking++;
      } else {
        working++;
      }
    }
    return {'working': working, 'nonWorking': nonWorking};
  }

  Map<String, int> _getYearlyStats(int year) {
    int working = 0;
    int nonWorking = 0;
    for (int month = 1; month <= 12; month++) {
      var stats = _getMonthStats(year, month);
      working += stats['working']!;
      nonWorking += stats['nonWorking']!;
    }
    return {'working': working, 'nonWorking': nonWorking};
  }

  String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  Widget _buildYearChanger() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
            onPressed: () {
              setState(() {
                _calendarSelectedYear--;
              });
            },
          ),
          const SizedBox(width: 8),
          Text(
            '$_calendarSelectedYear',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onPressed: () {
              setState(() {
                _calendarSelectedYear++;
              });
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF2F80ED)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(_calendarSelectedYear, DateTime.now().month, DateTime.now().day),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setState(() {
                  _calendarSelectedYear = picked.year;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(AppTheme theme, bool isWide, int totalWorking, int totalNonWorking) {
    final titleWidget = const Text(
      'Time management',
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.black,
      ),
    );

    final branchDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _calendarSelectedBranch,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Branches', style: TextStyle(fontSize: 12, fontFamily: 'Roboto'))),
            DropdownMenuItem(value: 'HQ', child: Text('Jakarta HQ', style: TextStyle(fontSize: 12, fontFamily: 'Roboto'))),
            DropdownMenuItem(value: 'Bandung', child: Text('Bandung Store', style: TextStyle(fontSize: 12, fontFamily: 'Roboto'))),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _calendarSelectedBranch = val;
              });
            }
          },
        ),
      ),
    );

    final statsCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Working Days
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.work_outline, color: Color(0xFF27AE60), size: 14),
                  SizedBox(width: 6),
                  Text('Working Days', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Roboto')),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$totalWorking days',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27AE60),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 32, color: Colors.grey.shade300),
          const SizedBox(width: 16),
          // Non-working Days
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.beach_access_outlined, color: Color(0xFFEB5757), size: 14),
                  SizedBox(width: 6),
                  Text('Non-working Days', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Roboto')),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$totalNonWorking days',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEB5757),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              titleWidget,
              const SizedBox(width: 16),
              branchDropdown,
              const SizedBox(width: 12),
              _buildYearChanger(),
            ],
          ),
          statsCard,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              branchDropdown,
              _buildYearChanger(),
            ],
          ),
          const SizedBox(height: 12),
          statsCard,
        ],
      );
    }
  }

  Widget _buildMonthDayGrid(int month) {
    final List<Widget> dayCells = [];
    
    // Weekdays header
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var dayLabel in weekdays) {
      dayCells.add(
        Center(
          child: Text(
            dayLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      );
    }
    
    // Offset cells
    int firstWeekday = DateTime(_calendarSelectedYear, month, 1).weekday;
    int offset = firstWeekday - 1;
    for (int i = 0; i < offset; i++) {
      dayCells.add(const SizedBox());
    }
    
    // Month days
    int daysInMonth = _getDaysInMonth(_calendarSelectedYear, month);
    final today = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_calendarSelectedYear, month, day);
      final bool isWeekend = date.weekday == 6 || date.weekday == 7;
      final bool isToday = today.year == _calendarSelectedYear && today.month == month && today.day == day;
      
      Color dayTextColor = isWeekend ? const Color(0xFFEB5757) : Colors.black87;
      BoxDecoration? decoration;
      Color? textColorOverride;
      
      if (isToday) {
        decoration = const BoxDecoration(
          color: Color(0xFF2F80ED),
          shape: BoxShape.circle,
        );
        textColorOverride = Colors.white;
      }
      
      final events = _getEventsForDay(_calendarSelectedYear, month, day);

      dayCells.add(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: decoration,
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.bold : (isWeekend ? FontWeight.w500 : FontWeight.normal),
                    color: textColorOverride ?? dayTextColor,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              if (events.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.map((e) {
                    final isHoliday = e['type'] == 'holiday';
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: isHoliday ? const Color(0xFFEB5757) : const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ] else
                const SizedBox(height: 6),
            ],
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: dayCells,
    );
  }

  Widget _buildMonthStats(int month) {
    final stats = _getMonthStats(_calendarSelectedYear, month);
    final int workingDays = stats['working']!;
    final int nonWorkingDays = stats['nonWorking']!;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF27AE60),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Work: $workingDays d',
                style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Roboto'),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB5757),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Non-work: $nonWorkingDays d',
                style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Roboto'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyCalendarGrid(AppTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double parentWidth = constraints.maxWidth;
        int columns = 4;
        if (parentWidth < 600) {
          columns = 1;
        } else if (parentWidth < 900) {
          columns = 2;
        } else if (parentWidth < 1200) {
          columns = 3;
        }
        
        final double spacing = 16.0;
        final double cardWidth = (parentWidth - (spacing * (columns - 1))) / columns;
        
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(12, (index) {
            final int month = index + 1;
            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Header
                  Text(
                    _getMonthName(month),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  
                  // Day grid
                  _buildMonthDayGrid(month),
                  
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  
                  // Month Stats
                  _buildMonthStats(month),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(int year, int month, int day) {
    final String dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return _calendarEventsList.where((e) => e['date'] == dateStr).toList();
  }

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    DateTime selectedDate = DateTime(_calendarSelectedYear, DateTime.now().month, DateTime.now().day);
    String selectedType = 'promo';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final String dateDisplay = '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}';
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Tambah Agenda Kegiatan',
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Kegiatan / Event',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Harbolnas Mega Sale',
                        prefixIcon: const Icon(Icons.edit, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Tanggal',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateDisplay,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const Icon(Icons.calendar_month, color: Color(0xFF2F80ED), size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tipe Kegiatan',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ChoiceChip(
                          label: const Text('Promosi'),
                          selected: selectedType == 'promo',
                          selectedColor: const Color(0xFF27AE60),
                          labelStyle: TextStyle(
                            color: selectedType == 'promo' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setStateDialog(() {
                                selectedType = 'promo';
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Hari Libur'),
                          selected: selectedType == 'holiday',
                          selectedColor: const Color(0xFFEB5757),
                          labelStyle: TextStyle(
                            color: selectedType == 'holiday' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setStateDialog(() {
                                selectedType = 'holiday';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Nama kegiatan tidak boleh kosong')),
                      );
                      return;
                    }
                    
                    final String formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    
                    setState(() {
                      _calendarEventsList.add({
                        'date': formattedDate,
                        'title': title,
                        'type': selectedType,
                      });
                    });

                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Kegiatan "$title" berhasil ditambahkan.')),
                    );

                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tambah', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEventsListPanel(AppTheme theme) {
    final yearEvents = _calendarEventsList.where((e) {
      final dateParts = (e['date'] as String).split('-');
      return dateParts[0] == '$_calendarSelectedYear';
    }).toList();

    yearEvents.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Kegiatan',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2F80ED), size: 20),
                onPressed: () => _showAddEventDialog(),
                tooltip: 'Tambah Event Baru',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tahun $_calendarSelectedYear (${yearEvents.length} kegiatan)',
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Roboto'),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          if (yearEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Tidak ada kegiatan untuk tahun ini.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Roboto'),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: yearEvents.length,
              itemBuilder: (context, index) {
                final event = yearEvents[index];
                final dateStr = event['date'] as String;
                final title = event['title'] as String;
                final type = event['type'] as String;

                final parts = dateStr.split('-');
                final int d = int.parse(parts[2]);
                final int m = int.parse(parts[1]);
                final String monthName = _getMonthName(m).substring(0, 3);
                final String displayDate = '$d $monthName';

                final isHoliday = type == 'holiday';
                final badgeColor = isHoliday ? const Color(0xFFEB5757) : const Color(0xFF27AE60);
                final badgeBg = isHoliday ? const Color(0xFFFDE8E8) : const Color(0xFFE8F8F5);
                final labelText = isHoliday ? 'Libur' : 'Promo';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F80ED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayDate,
                          style: const TextStyle(
                            color: Color(0xFF2F80ED),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            fontFamily: 'Roboto',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.black87,
                                fontFamily: 'Roboto',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                labelText.toUpperCase(),
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _calendarEventsList.remove(event);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kegiatan "$title" berhasil dihapus.')),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager.currentTheme,
      builder: (context, theme, _) {
        final yearlyStats = _getYearlyStats(_calendarSelectedYear);
        final int totalWorking = yearlyStats['working']!;
        final int totalNonWorking = yearlyStats['nonWorking']!;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendarHeader(theme, isWide, totalWorking, totalNonWorking),
                  const SizedBox(height: 20),
                  
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildYearlyCalendarGrid(theme),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildEventsListPanel(theme),
                        ),
                      ],
                    )
                  else ...[
                    _buildYearlyCalendarGrid(theme),
                    const SizedBox(height: 20),
                    _buildEventsListPanel(theme),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Sidebar Menu Drawer Builder
  Widget _buildSidebarDrawer(AppTheme theme, Color accentColor, Color textColor, Color subTextColor) {
    final double opacityVal = 0.10;

    Widget buildMenuItem(int tabIndex, IconData icon, String label) {
      final bool isSelected = _currentTab == tabIndex;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED).withValues(alpha: opacityVal) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? const Color(0xFF2F80ED) : textColor.withValues(alpha: 0.7),
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2F80ED) : textColor,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () {
            setState(() {
              _currentTab = tabIndex;
            });
            Navigator.pop(context); // Close drawer
          },
          dense: true,
        ),
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header matching Figma
          Container(
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildProfileAvatar(accentColor, 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _adminName,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                          if (_adminLocation.isNotEmpty)
                            Text(
                              _adminLocation,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Quick search',
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93), size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF1F1F1),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Menu List Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildMenuItem(0, Icons.dashboard, 'Dashboard'),
                buildMenuItem(3, Icons.people, 'People'),
                buildMenuItem(1, Icons.shopping_bag, 'Products'),
                buildMenuItem(4, Icons.calendar_today, 'Calendar'),
                buildMenuItem(2, Icons.campaign, 'Reports / Marketing'),
                buildMenuItem(5, Icons.admin_panel_settings, 'Administration'),
              ],
            ),
          ),

          // Footer CAMIOCA Version Card
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAMIOCA',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Version: 1.0.0.11',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: subTextColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        final subTextColor = theme.subTextColor;

        String getAppBarTitle() {
          switch (_currentTab) {
            case 0:
              return 'Admin Panel - Dashboard';
            case 1:
              return 'Admin Panel - Products';
            case 2:
              return 'Admin Panel - Marketing';
            case 3:
              return 'Admin Panel - People';
            case 4:
              return 'Admin Panel - Calendar';
            case 5:
              return 'Admin Panel - Administration';
            default:
              return 'Admin Panel';
          }
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF1F1F1), // Grey background from Figma
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(
              getAppBarTitle(),
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: Colors.black.withValues(alpha: 0.08), height: 1),
            ),
            actions: [
              // Search icon
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black87),
                onPressed: () {},
              ),
              // Notifications icon with Figma styling
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black87),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEB5757), // Notification red badge
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              // Profile circle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                      );
                      _loadAdminData();
                    },
                    child: _buildProfileAvatar(accentColor, 16),
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildSidebarDrawer(theme, accentColor, textColor, subTextColor),
          body: IndexedStack(
            index: _currentTab < 6 ? _currentTab : 0,
            children: [
              _buildDashboardOverviewTab(theme), // Tab 0: Dashboard
              _buildProductsTab(),               // Tab 1: Products CRUD
              _buildMarketingTab(),              // Tab 2: Marketing Managers
              _buildPeopleTab(theme),            // Tab 3: People Management
              _buildCalendarTab(),               // Tab 4: Calendar Redesign
              _buildPlaceholderTab('Administration'), // Tab 5: Administration
            ],
          ),
          floatingActionButton: _currentTab == 1
              ? FloatingActionButton(
                  backgroundColor: accentColor,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showProductForm(),
                )
              : null,
        );
      },
    );
  }
}

// Custom Painter for Widget 1: Statistik Produk Line/Area Chart
class ProductStatisticsPainter extends CustomPainter {
  final double pakaianCount;
  final double sepatuCount;
  final double aksesorisCount;
  final double maxScale;

  ProductStatisticsPainter({
    required this.pakaianCount,
    required this.sepatuCount,
    required this.aksesorisCount,
    required this.maxScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double gridHeight = size.height - 30; // bottom space for X labels
    final double gridWidth = size.width - 50;  // right space for Y labels

    // 1. Draw horizontal grid lines
    final paintGrid = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      double y = (gridHeight / 3) * i + 10;
      canvas.drawLine(Offset(0, y), Offset(gridWidth, y), paintGrid);
    }

    // 2. Draw Y labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final yLabels = [
      maxScale.toInt().toString(),
      (maxScale * 0.6).toInt().toString(),
      (maxScale * 0.3).toInt().toString(),
      '0'
    ];
    for (int i = 0; i < 4; i++) {
      double y = (gridHeight / 3) * i + 10;
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontFamily: 'Roboto'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(gridWidth + 8, y - 6));
    }

    // Draw Y axis header "Total"
    textPainter.text = const TextSpan(
      text: 'Total',
      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(gridWidth + 8, 10 - 16));

    // 3. Draw X labels (Q1, Q2, Q3, Q4)
    final xLabels = ['Q1', 'Q2', 'Q3', 'Q4'];
    for (int i = 0; i < 4; i++) {
      double x = (gridWidth / 3) * i;
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(color: Color(0xFF4F4F4F), fontSize: 11, fontFamily: 'Roboto'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, gridHeight + 10));
    }

    // 4. Draw filled line areas (Pakaian, Sepatu, Aksesoris)
    double normalizeY(double val) {
      return gridHeight + 10 - (val / maxScale) * gridHeight;
    }

    final pakaianY = [pakaianCount * 0.5, pakaianCount * 0.7, pakaianCount * 0.9, pakaianCount].map(normalizeY).toList();
    final sepatuY = [sepatuCount * 0.4, sepatuCount * 0.6, sepatuCount * 0.8, sepatuCount].map(normalizeY).toList();
    final aksesorisY = [aksesorisCount * 0.3, aksesorisCount * 0.5, aksesorisCount * 0.7, aksesorisCount].map(normalizeY).toList();

    void drawArea(List<double> yValues, Color fillColor, Color strokeColor) {
      final path = Path();
      path.moveTo(0, gridHeight + 10);
      for (int i = 0; i < 4; i++) {
        double x = (gridWidth / 3) * i;
        path.lineTo(x, yValues[i]);
      }
      path.lineTo(gridWidth, gridHeight + 10);
      path.close();

      final paintArea = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paintArea);

      final paintStroke = Paint()
        ..color = strokeColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final strokePath = Path();
      strokePath.moveTo(0, yValues[0]);
      for (int i = 1; i < 4; i++) {
        double x = (gridWidth / 3) * i;
        strokePath.lineTo(x, yValues[i]);
      }
      canvas.drawPath(strokePath, paintStroke);
    }

    // Draw from largest to smallest to support layer blending
    drawArea(pakaianY, const Color(0xFFF2994A).withValues(alpha: 0.25), const Color(0xFFF2994A));
    drawArea(sepatuY, const Color(0xFF00B2A9).withValues(alpha: 0.25), const Color(0xFF00B2A9));
    drawArea(aksesorisY, const Color(0xFFBB6BD9).withValues(alpha: 0.25), const Color(0xFFBB6BD9));
  }

  @override
  bool shouldRepaint(covariant ProductStatisticsPainter oldDelegate) {
    return oldDelegate.pakaianCount != pakaianCount ||
        oldDelegate.sepatuCount != sepatuCount ||
        oldDelegate.aksesorisCount != aksesorisCount ||
        oldDelegate.maxScale != maxScale;
  }
}

// Custom Painter for Widget 2: User Analysis Donut Chart
class UserAnalysisDonutPainter extends CustomPainter {
  final double buyers;
  final double sellers;
  final double admins;

  UserAnalysisDonutPainter({
    required this.buyers,
    required this.sellers,
    required this.admins,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final double strokeWidth = size.width < 150 ? 16.0 : 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final segments = [
      {'val': buyers, 'color': const Color(0xFFBB6BD9)},
      {'val': sellers, 'color': const Color(0xFF27AE60)},
      {'val': admins, 'color': const Color(0xFFEB5757)},
    ];

    double total = segments.map((e) => e['val'] as double).reduce((a, b) => a + b);
    if (total == 0) total = 100; // prevent division by zero
    double startAngle = -3.14159 / 2; // Start at 12 o'clock

    final paintArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (var seg in segments) {
      double sweepAngle = ((seg['val'] as double) / total) * 2 * 3.14159;
      paintArc.color = seg['color'] as Color;
      // Draw with minor gap (0.04)
      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paintArc);
      startAngle += sweepAngle;
    }

    // Inner Text "Tipe Pengguna"
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: "Tipe\nPengguna",
      style: TextStyle(
        color: Colors.black,
        fontSize: size.width < 150 ? 10 : 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
    );
    textPainter.layout(maxWidth: size.width - 2 * strokeWidth - 10);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant UserAnalysisDonutPainter oldDelegate) {
    return oldDelegate.buyers != buyers ||
        oldDelegate.sellers != sellers ||
        oldDelegate.admins != admins;
  }
}

// Custom Painter for Widget 3: Report Statistics Line Chart
class ReportStatisticsPainter extends CustomPainter {
  final Map<String, int> dateCounts;
  final List<String> sortedDates;
  final double maxScale;

  ReportStatisticsPainter({
    required this.dateCounts,
    required this.sortedDates,
    required this.maxScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double gridHeight = size.height - 30; // bottom space for X labels
    final double gridWidth = size.width - 50;  // right space for Y labels

    // 1. Draw horizontal grid lines
    final paintGrid = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      double y = (gridHeight / 3) * i + 10;
      canvas.drawLine(Offset(0, y), Offset(gridWidth, y), paintGrid);
    }

    // 2. Draw Y labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final yLabels = [
      maxScale.toInt().toString(),
      (maxScale * 0.6).toInt().toString(),
      (maxScale * 0.3).toInt().toString(),
      '0'
    ];
    for (int i = 0; i < 4; i++) {
      double y = (gridHeight / 3) * i + 10;
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontFamily: 'Roboto'),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(gridWidth + 8, y - 6));
    }

    // Draw Y axis header "Pelapor"
    textPainter.text = const TextSpan(
      text: 'Pelapor',
      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(gridWidth + 8, 10 - 16));

    // 3. Draw X labels (Dates)
    final numPoints = sortedDates.length;
    if (numPoints > 1) {
      for (int i = 0; i < numPoints; i++) {
        double x = (gridWidth / (numPoints - 1)) * i;
        textPainter.text = TextSpan(
          text: sortedDates[i],
          style: const TextStyle(color: Color(0xFF4F4F4F), fontSize: 10, fontFamily: 'Roboto'),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, gridHeight + 10));
      }
    }

    // 4. Draw filled line area or bars for report counts
    if (numPoints > 1) {
      double normalizeY(double val) {
        return gridHeight + 10 - (val / maxScale) * gridHeight;
      }

      final yValues = sortedDates.map((date) => (dateCounts[date] ?? 0).toDouble()).toList();
      final normYValues = yValues.map(normalizeY).toList();

      final path = Path();
      path.moveTo(0, gridHeight + 10);
      for (int i = 0; i < numPoints; i++) {
        double x = (gridWidth / (numPoints - 1)) * i;
        path.lineTo(x, normYValues[i]);
      }
      path.lineTo(gridWidth, gridHeight + 10);
      path.close();

      // Red/Orange themed area for reports
      final paintArea = Paint()
        ..color = const Color(0xFFEB5757).withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paintArea);

      final paintStroke = Paint()
        ..color = const Color(0xFFEB5757)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final strokePath = Path();
      strokePath.moveTo(0, normYValues[0]);
      for (int i = 1; i < numPoints; i++) {
        double x = (gridWidth / (numPoints - 1)) * i;
        strokePath.lineTo(x, normYValues[i]);
      }
      canvas.drawPath(strokePath, paintStroke);

      // Draw dots on each node
      final paintDot = Paint()
        ..color = const Color(0xFFEB5757)
        ..style = PaintingStyle.fill;
      final paintDotOuter = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < numPoints; i++) {
        double x = (gridWidth / (numPoints - 1)) * i;
        canvas.drawCircle(Offset(x, normYValues[i]), 5, paintDot);
        canvas.drawCircle(Offset(x, normYValues[i]), 5, paintDotOuter);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ReportStatisticsPainter oldDelegate) {
    return oldDelegate.maxScale != maxScale ||
        oldDelegate.dateCounts != dateCounts ||
        oldDelegate.sortedDates != sortedDates;
  }
}
