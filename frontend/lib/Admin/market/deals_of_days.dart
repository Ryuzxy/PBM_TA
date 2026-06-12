import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Models/product.dart';
import '../../Services/firestore_service.dart';

class DealsOfDaysManager extends StatefulWidget {
  const DealsOfDaysManager({super.key});

  @override
  State<DealsOfDaysManager> createState() => _DealsOfDaysManagerState();
}

class _DealsOfDaysManagerState extends State<DealsOfDaysManager> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _timerController = TextEditingController();

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _saveTimer(String value) async {
    await _firestoreService.updateSettings('deals_of_days', {
      'remainingText': value,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Countdown text updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Deals of the Day'),
      ),
      body: Column(
        children: [
          // ─── Timer Config Section ───
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestoreService.getSettings('deals_of_days'),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final text = data?['remainingText'] as String? ?? '';
                    if (_timerController.text.isEmpty && text.isNotEmpty) {
                      _timerController.text = text;
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deal Countdown Timer Text',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _timerController,
                              decoration: const InputDecoration(
                                hintText: 'e.g., 22h 55m 20s remaining',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _saveTimer(_timerController.text),
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
                'Select Products for Deal of the Day',
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: SwitchListTile(
                        value: product.isDealOfTheDay,
                        secondary: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image),
                              )
                            : const Icon(Icons.image),
                        title: Text(product.title),
                        subtitle: Text('Price: Rp ${product.price}'),
                        onChanged: (val) async {
                          await _firestoreService.toggleProductFlag(
                            product.id!,
                            'isDealOfTheDay',
                            val,
                          );
                        },
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
