import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/theme_manager.dart';
import 'product/dashboard.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  // Simulation states
  Timer? _simulationTimer;
  String? _activeSimulatingOrderId;
  int _simulationStep = 0;
  List<LatLng> _simRoutePoints = [];

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startDeliverySimulation(String orderId, LatLng start, LatLng end, String? buyerId) async {
    setState(() {
      _activeSimulatingOrderId = orderId;
      _simulationStep = 0;
      _simRoutePoints = [];
    });

    // 1. Fetch OSRM road path for maximum realism
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
          _simRoutePoints = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching simulation route: $e');
    }

    // Straight line fallback if OSRM is offline
    if (_simRoutePoints.isEmpty) {
      _simRoutePoints = List.generate(15, (i) {
        double t = i / 14.0;
        double lat = start.latitude + (end.latitude - start.latitude) * t;
        double lng = start.longitude + (end.longitude - start.longitude) * t;
        return LatLng(lat, lng);
      });
    }

    // Update state to In Transit (2)
    await FirebaseFirestore.instance.collection('tracking').doc(orderId).update({
      'status': 2,
    });
    if (buyerId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 2,
      });
    }

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _activeSimulatingOrderId != orderId) {
        timer.cancel();
        return;
      }

      if (_simulationStep >= _simRoutePoints.length) {
        timer.cancel();
        // Update state to Delivered / Arrived (3) at destination
        await FirebaseFirestore.instance.collection('tracking').doc(orderId).update({
          'status': 3,
        });
        if (buyerId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(buyerId)
              .collection('orders')
              .doc(orderId)
              .update({
            'status': 3,
          });
        }
        if (mounted) {
          setState(() {
            _activeSimulatingOrderId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Simulation finished. Courier arrived!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      final currentPt = _simRoutePoints[_simulationStep];
      await FirebaseFirestore.instance.collection('tracking').doc(orderId).update({
        'sellerLatitude': currentPt.latitude,
        'sellerLongitude': currentPt.longitude,
      });

      if (mounted) {
        setState(() {
          _simulationStep++;
        });
      }
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _activeSimulatingOrderId = null;
    });
  }

  Future<void> _updateOrderStatus(String orderId, int status, String? buyerId) async {
    await FirebaseFirestore.instance.collection('tracking').doc(orderId).update({
      'status': status,
    });
    if (buyerId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status,
      });
    }
  }

  Future<void> _updateCourierLocation(String orderId, LatLng pos) async {
    await FirebaseFirestore.instance.collection('tracking').doc(orderId).update({
      'sellerLatitude': pos.latitude,
      'sellerLongitude': pos.longitude,
    });
  }

  void _showOrderControlSheet(BuildContext context, Map<String, dynamic> data, AppTheme theme) {
    final orderId = data['orderId'] ?? 'ORD';
    final buyerName = data['buyerName'] ?? 'Customer';
    final buyerAddress = data['buyerAddress'] ?? 'Address';
    final double amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final items = data['items'] as List<dynamic>? ?? [];

    final MapController mapController = MapController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('tracking').doc(orderId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    height: 200,
                    color: theme.cardColor,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final trackingData = snapshot.data!.data() as Map<String, dynamic>;
                final String? buyerId = trackingData['buyerId'] as String?;
                final double sellerLat = (trackingData['sellerLatitude'] as num?)?.toDouble() ?? -6.2088;
                final double sellerLng = (trackingData['sellerLongitude'] as num?)?.toDouble() ?? 106.8456;
                final double buyerLat = (trackingData['buyerLatitude'] as num?)?.toDouble() ?? -6.2188;
                final double buyerLng = (trackingData['buyerLongitude'] as num?)?.toDouble() ?? 106.8456;
                final double storeLat = (trackingData['storeLatitude'] as num?)?.toDouble() ?? sellerLat;
                final double storeLng = (trackingData['storeLongitude'] as num?)?.toDouble() ?? sellerLng;
                final int currentStatus = (trackingData['status'] as num?)?.toInt() ?? 2;

                final isSimulating = _activeSimulatingOrderId == orderId;

                return Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Pull Handler
                      const SizedBox(height: 12),
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.textColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Control #$orderId',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Recipient: $buyerName',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    color: theme.subTextColor,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: theme.textColor),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Live Map Panel
                      Expanded(
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                initialCenter: LatLng(sellerLat, sellerLng),
                                initialZoom: 14.0,
                                onTap: (tapPosition, point) async {
                                  if (isSimulating) return; // disable tap during running simulation
                                  await _updateCourierLocation(orderId, point);
                                  setModalState(() {});
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: theme.bgColor.computeLuminance() < 0.5
                                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.example.frontend',
                                ),
                                 PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: [
                                        LatLng(storeLat, storeLng),
                                        LatLng(buyerLat, buyerLng),
                                      ],
                                      color: theme.accentColor,
                                      strokeWidth: 3.5,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    // 1. Storefront (Seller Start Position)
                                    Marker(
                                      point: LatLng(storeLat, storeLng),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.orange,
                                          child: Icon(Icons.storefront, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                    // 2. Courier (Moving Position)
                                    Marker(
                                      point: LatLng(sellerLat, sellerLng),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: CircleAvatar(
                                          backgroundColor: theme.accentColor,
                                          child: const Icon(Icons.delivery_dining, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                    // 3. Buyer (End Position)
                                    Marker(
                                      point: LatLng(buyerLat, buyerLng),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: Icon(Icons.home, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Map Help Badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.bgColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isSimulating ? '🔒 Auto-Simulating Route...' : '👉 Tap map to manually place Courier',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Control Panel Area
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Status Controller Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Status:',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.textColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _statusButton(
                                      label: 'In Transit',
                                      isActive: currentStatus == 2,
                                      color: Colors.orange,
                                      onTap: () async {
                                        await _updateOrderStatus(orderId, 2, buyerId);
                                        setModalState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _statusButton(
                                      label: 'Arrived',
                                      isActive: currentStatus == 3,
                                      color: Colors.green,
                                      onTap: () async {
                                        await _updateOrderStatus(orderId, 3, buyerId);
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Simulation Controller Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (isSimulating) {
                                    _stopSimulation();
                                  } else {
                                    final start = LatLng(storeLat, storeLng);
                                    final end = LatLng(buyerLat, buyerLng);
                                    
                                    // Start async process
                                    _startDeliverySimulation(orderId, start, end, buyerId);
                                  }
                                  setModalState(() {});
                                },
                                icon: Icon(
                                  isSimulating ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isSimulating 
                                      ? 'Stop Route Simulation ($_simulationStep/${_simRoutePoints.length})' 
                                      : 'Simulate Road Delivery Run',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSimulating ? Colors.redAccent : theme.accentColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) => _stopSimulation());
  }

  Widget _statusButton({required String label, required bool isActive, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? color : Colors.grey.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey,
          ),
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
              'Seller Panel',
              style: TextStyle(
                color: textColor,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.inventory_2_outlined, color: textColor),
                tooltip: 'Manage Products',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductDashboard(),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: textColor.withOpacity(0.08), height: 1),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tracking')
                .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: accentColor));
              }

              final rawDocs = snapshot.data?.docs ?? [];
              final docs = List<QueryDocumentSnapshot>.from(rawDocs);
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>? ?? {};
                final bData = b.data() as Map<String, dynamic>? ?? {};
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              // Calculate metrics
              final int totalOrders = docs.length;
              final int activeOrders = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 2).length;
              final int arrivedOrders = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 3).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics Banner
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        _buildMetricCard('Total Orders', totalOrders.toString(), Icons.shopping_bag_outlined, Colors.blue, cardColor, textColor, subTextColor),
                        const SizedBox(width: 10),
                        _buildMetricCard('Active GPS', activeOrders.toString(), Icons.delivery_dining, Colors.orange, cardColor, textColor, subTextColor),
                        const SizedBox(width: 10),
                        _buildMetricCard('Arrived', arrivedOrders.toString(), Icons.done_all_rounded, Colors.green, cardColor, textColor, subTextColor),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Text(
                      'Live Tracking Orders (${docs.length})',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Order List
                  Expanded(
                    child: docs.isEmpty
                        ? _buildEmptyState(textColor, subTextColor, accentColor)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final orderId = data['orderId'] ?? 'ORD';
                              final buyerName = data['buyerName'] ?? 'Customer';
                              final double amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
                              final int status = (data['status'] as num?)?.toInt() ?? 2;
                              final items = data['items'] as List<dynamic>? ?? [];

                              final isSimulating = _activeSimulatingOrderId == orderId;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: cardColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSimulating ? accentColor : textColor.withOpacity(0.06),
                                    width: isSimulating ? 1.5 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showOrderControlSheet(context, data, currentTheme),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Package badge / icon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (status == 3 ? Colors.green : accentColor).withOpacity(0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            status == 3 ? Icons.check_circle_outline_rounded : Icons.delivery_dining,
                                            color: status == 3 ? Colors.green : accentColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Order summary details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '#$orderId',
                                                    style: TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rp ${amount.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: accentColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Buyer: $buyerName',
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 11,
                                                  color: subTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Items: ${items.length} product(s)',
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 11,
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Chevron arrow
                                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, Color cardColor, Color textColor, Color subTextColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_outlined, size: 48, color: accentColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Shipments',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders created during successful checkouts will show up here for live tracking simulation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: subTextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
