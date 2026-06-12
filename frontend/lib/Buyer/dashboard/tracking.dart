import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../Services/theme_manager.dart';

class TrackingScreen extends StatefulWidget {
  final double totalAmount;
  final String orderId;

  const TrackingScreen({
    super.key,
    this.totalAmount = 7030.0,
    this.orderId = 'ORD-89324-X',
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Real-time tracking db connection
  StreamSubscription<DocumentSnapshot>? _trackingSubscription;
  int _orderStatus = 2; // Default is In Transit
  List<dynamic> _items = [];

  // Map Controller and coordinates
  final MapController _mapController = MapController();
  
  double _storeLat = -6.2088;
  double _storeLng = 106.8456;
  double _sellerLat = -6.2088;
  double _sellerLng = 106.8456;
  double _buyerLat = -6.2188;
  double _buyerLng = 106.8456;

  // Real-time road route coordinates
  List<LatLng> _routePoints = [];
  DateTime? _lastRouteFetchTime;

  // Order Details from DB
  double _dbTotalAmount = 7030.0;
  bool _showOrderItems = false;
  String _buyerAddress = '';
  String _sellerAddress = '';

  bool _isLoadingTracking = true;
  double _distanceInKm = 0.0;
  bool _isSimulatingBuyer = false;
  Timer? _buyerSimTimer;
  StreamSubscription<Position>? _positionSubscription;

  // Countdown timer for ETA
  Timer? _etaTimer;
  int _etaMinutes = 12;

  // Quick Nudge click tracker
  int _nudgeCount = 0;
  bool _isNudging = false;

  // Chat conversation state
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'seller',
      'text': 'Hello! I am preparing your package and heading out soon.',
      'time': 'Just now',
    }
  ];
  final TextEditingController _chatInputController = TextEditingController();

  void _calculateDistance() {
    try {
      final double distanceInMeters = Geolocator.distanceBetween(
        _sellerLat,
        _sellerLng,
        _buyerLat,
        _buyerLng,
      );
      setState(() {
        _distanceInKm = distanceInMeters / 1000.0;
        if (_orderStatus != 3) {
          // Average courier speed 30 km/h -> 0.5 km/minute
          _etaMinutes = (_distanceInKm / 0.5).round();
          if (_etaMinutes < 1) _etaMinutes = 1;
        } else {
          _etaMinutes = 0;
        }
      });
    } catch (e) {
      debugPrint('Error calculating distance: $e');
    }
  }

  void _startListeningToBuyerLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) async {
        if (mounted && !_isSimulatingBuyer) {
          setState(() {
            _buyerLat = position.latitude;
            _buyerLng = position.longitude;
          });
          
          try {
            await FirebaseFirestore.instance
                .collection('tracking')
                .doc(widget.orderId)
                .update({
              'buyerLatitude': position.latitude,
              'buyerLongitude': position.longitude,
            });
          } catch (e) {
            debugPrint('Error updating buyer location in Firestore: $e');
          }
          
          _calculateDistance();
          _updateCameraBounds();
          _fetchRoute();
        }
      });
    }
  }

  void _toggleBuyerSimulation() {
    if (_isSimulatingBuyer) {
      _buyerSimTimer?.cancel();
      setState(() {
        _isSimulatingBuyer = false;
      });
    } else {
      setState(() {
        _isSimulatingBuyer = true;
      });
      
      int step = 0;
      final int totalSteps = 25;
      final double startLat = _buyerLat;
      final double startLng = _buyerLng;
      
      _buyerSimTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted || !_isSimulatingBuyer) {
          timer.cancel();
          return;
        }
        
        step++;
        if (step >= totalSteps) {
          timer.cancel();
          setState(() {
            _isSimulatingBuyer = false;
            _buyerLat = _sellerLat;
            _buyerLng = _sellerLng;
          });
        } else {
          double t = step / totalSteps;
          double currentLat = startLat + (_sellerLat - startLat) * t;
          double currentLng = startLng + (_sellerLng - startLng) * t;
          
          setState(() {
            _buyerLat = currentLat;
            _buyerLng = currentLng;
          });
        }
        
        try {
          await FirebaseFirestore.instance
              .collection('tracking')
              .doc(widget.orderId)
              .update({
            'buyerLatitude': _buyerLat,
            'buyerLongitude': _buyerLng,
          });
        } catch (_) {}
        
        _calculateDistance();
        _updateCameraBounds();
        _fetchRoute();
      });
    }
  }

  Future<void> _fetchRoute() async {
    final now = DateTime.now();
    // Rate limit: don't call more than once every 8 seconds
    if (_lastRouteFetchTime != null && now.difference(_lastRouteFetchTime!) < const Duration(seconds: 8)) {
      return;
    }
    _lastRouteFetchTime = now;

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '$_sellerLng,$_sellerLat;$_buyerLng,$_buyerLat'
        '?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coords = geometry['coordinates'] as List<dynamic>;
          final List<LatLng> points = coords.map((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
          if (mounted) {
            setState(() {
              _routePoints = points;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching OSRM route: $e');
    }
    
    // Fallback to straight line if API fails
    if (mounted && _routePoints.isEmpty) {
      setState(() {
        _routePoints = [
          LatLng(_sellerLat, _sellerLng),
          LatLng(_buyerLat, _buyerLng),
        ];
      });
    }
  }

  void _updateCameraBounds() {
    try {
      if (!mounted) return;
      
      double minLat = math.min(math.min(_sellerLat, _buyerLat), _storeLat);
      double maxLat = math.max(math.max(_sellerLat, _buyerLat), _storeLat);
      double minLng = math.min(math.min(_sellerLng, _buyerLng), _storeLng);
      double maxLng = math.max(math.max(_sellerLng, _buyerLng), _storeLng);

      // Add a safe margin if coordinates are too close
      if ((maxLat - minLat).abs() < 0.001 && (maxLng - minLng).abs() < 0.001) {
        minLat -= 0.003;
        maxLat += 0.003;
        minLng -= 0.003;
        maxLng += 0.003;
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80.0),
        ),
      );
    } catch (e) {
      debugPrint('Error updating camera bounds: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _dbTotalAmount = widget.totalAmount;
    _routePoints = [
      LatLng(_storeLat, _storeLng),
      LatLng(_buyerLat, _buyerLng),
    ];

    // ETA Countdown tick
    _etaTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_etaMinutes > 1 && !_isSimulatingBuyer) {
        if (mounted) {
          setState(() {
            _etaMinutes--;
          });
        }
      }
    });

    // Real-time Firestore sync with root tracking collection
    _trackingSubscription = FirebaseFirestore.instance
        .collection('tracking')
        .doc(widget.orderId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        final status = (data['status'] as num?)?.toInt() ?? 2;
        final items = data['items'] as List<dynamic>? ?? [];
        final sellerLat = (data['sellerLatitude'] as num?)?.toDouble() ?? -6.2088;
        final sellerLng = (data['sellerLongitude'] as num?)?.toDouble() ?? 106.8456;
        final buyerLat = (data['buyerLatitude'] as num?)?.toDouble() ?? -6.2188;
        final buyerLng = (data['buyerLongitude'] as num?)?.toDouble() ?? 106.8456;
        final storeLat = (data['storeLatitude'] as num?)?.toDouble() ?? sellerLat;
        final storeLng = (data['storeLongitude'] as num?)?.toDouble() ?? sellerLng;
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? widget.totalAmount;
        final bAddress = data['buyerAddress'] as String? ?? '';
        final sAddress = data['sellerAddress'] as String? ?? '';
        
        if (mounted) {
          setState(() {
            _orderStatus = status;
            _items = items;
            _sellerLat = sellerLat;
            _sellerLng = sellerLng;
            if (!_isSimulatingBuyer) {
              _buyerLat = buyerLat;
              _buyerLng = buyerLng;
            }
            _storeLat = storeLat;
            _storeLng = storeLng;
            _dbTotalAmount = amount;
            _buyerAddress = bAddress;
            _sellerAddress = sAddress;
            _isLoadingTracking = false;
            if (status == 3) {
              // Delivered / Arrived
              _etaMinutes = 0;
            }
          });
          _calculateDistance();
          _updateCameraBounds();
          _fetchRoute();
        }
      }
    }, onError: (e) {
      debugPrint('Error listening to tracking document: $e');
    });

    _startListeningToBuyerLocation();
    _fetchRoute();
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    _buyerSimTimer?.cancel();
    _positionSubscription?.cancel();
    _chatInputController.dispose();
    _trackingSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _triggerQuickNudge() {
    if (_isNudging) return;
    setState(() {
      _isNudging = true;
      _nudgeCount++;
    });

    // Trigger feedback notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Quick Nudge sent! Seller pinged (${_nudgeCount}x)',
              style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF83758),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // Simulated auto-reply from seller after a nudge
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      String replyText = "Understood! I'm moving as fast as I can. Currently at traffic point.";
      if (_orderStatus == 3) {
        replyText = "Almost there! I am looking for your building.";
      }

      setState(() {
        _chatMessages.add({
          'sender': 'seller',
          'text': replyText,
          'time': 'Just now',
        });
      });
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isNudging = false;
        });
      }
    });
  }

  void _sendChatMessage() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({
        'sender': 'buyer',
        'text': text,
        'time': 'Just now',
      });
      _chatInputController.clear();
    });

    // Mock seller smart responses
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      String response = "Okay, noted! I will arrive shortly.";
      if (text.toLowerCase().contains('where') || text.toLowerCase().contains('lokasi')) {
        response = "I am on the road marked on your tracker. Check the live pin!";
      } else if (text.toLowerCase().contains('cash') || text.toLowerCase().contains('uang')) {
        response = "Yes, please prepare exactly ₹${_dbTotalAmount.toStringAsFixed(0)} cash.";
      }

      setState(() {
        _chatMessages.add({
          'sender': 'seller',
          'text': response,
          'time': 'Just now',
        });
      });
    });
  }

  void _showChatBottomSheet(Color cardColor, Color textColor, Color accentColor, Color subTextColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Pull handler line
                  const SizedBox(height: 12),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Chat Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor.withOpacity(0.1),
                          child: Icon(Icons.delivery_dining, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SmartDrop Courier',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              const Text(
                                'Online • Shipping your order',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Message List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        final isMe = msg['sender'] == 'buyer';
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe 
                                  ? accentColor 
                                  : (textColor.withOpacity(0.05)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                               Text(
                                  msg['text'],
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: isMe ? Colors.white : textColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    msg['time'],
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: isMe ? Colors.white70 : subTextColor,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Input Box
                  SafeArea(
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                        left: 16,
                        right: 16,
                        top: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: textColor.withOpacity(0.08)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatInputController,
                              style: TextStyle(color: textColor, fontFamily: 'Montserrat'),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _sendChatMessage();
                              setModalState(() {});
                              // Trigger UI update in parent screen too
                              setState(() {});
                            },
                            icon: Icon(Icons.send, color: accentColor),
                          ),
                        ],
                      ),
                    ),
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
      builder: (context, currentTheme, _) {
        final bgColor = currentTheme.bgColor;
        final textColor = currentTheme.textColor;
        final cardColor = currentTheme.cardColor;
        final accentColor = currentTheme.accentColor;
        final subTextColor = currentTheme.subTextColor;

        if (_isLoadingTracking) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading tracking data...',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // 1. FULL MAP VISUAL AREA (Bagian Tengah)
              Positioned.fill(
                child: ClipRect(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_sellerLat, _sellerLng),
                      initialZoom: 13.5,
                      onMapReady: () {
                        _updateCameraBounds();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: currentTheme.bgColor.computeLuminance() < 0.5
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.example.frontend',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints.isEmpty
                                ? [LatLng(_storeLat, _storeLng), LatLng(_buyerLat, _buyerLng)]
                                : _routePoints,
                            color: accentColor,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // 1. Seller Storefront (Start)
                          Marker(
                            point: LatLng(_storeLat, _storeLng),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  Icons.storefront,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // 2. Courier Rider (Current moving position)
                          Marker(
                            point: LatLng(_sellerLat, _sellerLng),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                backgroundColor: accentColor,
                                child: const Icon(
                                  Icons.delivery_dining,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // 3. Buyer Home (End)
                          Marker(
                            point: LatLng(_buyerLat, _buyerLng),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.home,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. BACK BUTTON & APP TITLE (Overlaid on Map)
              Positioned(
                top: 48,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: cardColor.withOpacity(0.9),
                  radius: 22,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // 2.1 WALK SIMULATION BUTTON
              Positioned(
                top: 104,
                left: 16,
                child: Tooltip(
                  message: _isSimulatingBuyer ? 'Stop Walk Simulation' : 'Simulate My Walk',
                  child: CircleAvatar(
                    backgroundColor: (_isSimulatingBuyer ? Colors.red : Colors.green).withOpacity(0.9),
                    radius: 22,
                    child: IconButton(
                      icon: Icon(
                        _isSimulatingBuyer ? Icons.stop : Icons.directions_walk,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _toggleBuyerSimulation,
                    ),
                  ),
                ),
              ),

              // 3. TOP INFO BOARD: ETA & Total Cash amount (Bagian Atas)
              Positioned(
                top: 48,
                left: 72,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ETA Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ESTIMATED ARRIVAL',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                letterSpacing: 0.5,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time_filled, color: accentColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$_etaMinutes mins (${_distanceInKm.toStringAsFixed(1)} km)',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Divider line
                      Container(
                        height: 28,
                        width: 1,
                        color: textColor.withOpacity(0.1),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      // Cash Amount Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CASH TO PREPARE',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: subTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.payments, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Rp ${_dbTotalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: textColor,
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

              // 4. BOTTOM COMMUNICATION BOARD: Chat & Quick Nudge (Bagian Bawah)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status card inside bottom board
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delivery_dining, color: accentColor, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _orderStatus == 3
                                      ? 'Courier Arrived!' 
                                      : 'On the Way to Safe Zone',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _orderStatus == 3
                                      ? 'Meet courier at your designated Safe Zone point.'
                                      : 'Courier is driving towards meeting point.',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_buyerAddress.isNotEmpty || _sellerAddress.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 10),
                        if (_sellerAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.storefront_outlined, size: 14, color: subTextColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Seller: $_sellerAddress',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      color: subTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_buyerAddress.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: accentColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Buyer: $_buyerAddress',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (_items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 0.5),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showOrderItems = !_showOrderItems;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Items (${_items.length})',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                              Icon(
                                _showOrderItems ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 18,
                                color: textColor,
                              ),
                            ],
                          ),
                        ),
                        if (_showOrderItems) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _items.length,
                              itemBuilder: (context, idx) {
                                final item = _items[idx] as Map<String, dynamic>;
                                final title = item['title'] ?? 'Product';
                                final qty = item['quantity'] ?? 1;
                                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                                final img = item['imageUrl'] ?? '';
                                
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: textColor.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: textColor.withOpacity(0.06)),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: img.isNotEmpty
                                            ? Image.network(img, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.shopping_bag, size: 20, color: subTextColor))
                                            : Icon(Icons.shopping_bag, size: 20, color: subTextColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rp ${price.toStringAsFixed(0)} x $qty',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 10,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 16),

                      // Communication buttons
                      Row(
                        children: [
                          // A. Chat Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showChatBottomSheet(cardColor, textColor, accentColor, subTextColor),
                              icon: Icon(Icons.chat_bubble_outline, size: 20, color: textColor),
                              label: Text(
                                'Chat',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: textColor.withOpacity(0.15)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // B. Quick Nudge ("Ping!") Emergency button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isNudging ? null : _triggerQuickNudge,
                              icon: const Icon(Icons.notifications_active, size: 20, color: Colors.white),
                              label: const Text(
                                'Ping!',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
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
      },
    );
  }
}
