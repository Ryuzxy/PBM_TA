import 'package:flutter/material.dart';
import '../Models/product.dart';
import '../Services/firestore_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showProductForm({Product? product}) {
    final titleController = TextEditingController(text: product?.title ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final oldPriceController = TextEditingController(text: product?.oldPrice?.toString() ?? '');
    final discountController = TextEditingController(text: product?.discount?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?.imageUrl ?? '');

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
                  rating: product?.rating ?? 0.0,
                  reviews: product?.reviews ?? 0,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
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
              return ListTile(
                leading: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 50),
                title: Text(product.title),
                subtitle: Text('₹${product.price}'),
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
              );
            },
          );
        },
      ),
    );
  }
}
