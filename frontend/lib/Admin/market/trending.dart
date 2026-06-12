import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Models/product.dart';
import '../../Services/firestore_service.dart';

class TrendingManager extends StatefulWidget {
  const TrendingManager({super.key});

  @override
  State<TrendingManager> createState() => _TrendingManagerState();
}

class _TrendingManagerState extends State<TrendingManager> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _lastDateController = TextEditingController();

  @override
  void dispose() {
    _lastDateController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings(String value) async {
    await _firestoreService.updateSettings('trending', {
      'lastDate': value,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trending last date updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Trending & New Arrivals'),
      ),
      body: Column(
        children: [
          // ─── Settings Config Section ───
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestoreService.getSettings('trending'),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final text = data?['lastDate'] as String? ?? '';
                    if (_lastDateController.text.isEmpty && text.isNotEmpty) {
                      _lastDateController.text = text;
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trending Banner Last Date/Text',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lastDateController,
                              decoration: const InputDecoration(
                                hintText: 'e.g., Ends in 02h 15m or 15/06/2026',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _saveSettings(_lastDateController.text),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Divider(),
          // ─── Products Toggles ───
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Products Features',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
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
                  return const Center(child: Text('No products available. Add products first.'));
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            ListTile(
                              leading: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                                    )
                                  : const Icon(Icons.image),
                              title: Text(product.title),
                              subtitle: Text('Price: Rp ${product.price}'),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Trending:'),
                                      Switch(
                                        value: product.isTrending,
                                        onChanged: (val) async {
                                          await _firestoreService.toggleProductFlag(
                                            product.id!,
                                            'isTrending',
                                            val,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text('New Arrival:'),
                                      Switch(
                                        value: product.isNewArrival,
                                        onChanged: (val) async {
                                          await _firestoreService.toggleProductFlag(
                                            product.id!,
                                            'isNewArrival',
                                            val,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
