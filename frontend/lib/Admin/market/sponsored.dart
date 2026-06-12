import 'package:flutter/material.dart';
import '../../Models/banner_model.dart';
import '../../Services/firestore_service.dart';

class SponsoredManager extends StatefulWidget {
  const SponsoredManager({super.key});

  @override
  State<SponsoredManager> createState() => _SponsoredManagerState();
}

class _SponsoredManagerState extends State<SponsoredManager> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showForm({BannerModel? banner}) {
    final titleController = TextEditingController(text: banner?.title ?? '');
    final subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    final imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    final orderController = TextEditingController(text: banner?.order.toString() ?? '1');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(banner == null ? 'Add Sponsored Banner' : 'Edit Sponsored Banner'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle'),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: orderController,
                  decoration: const InputDecoration(labelText: 'Display Order'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBanner = BannerModel(
                  id: banner?.id ?? '',
                  title: titleController.text,
                  subtitle: subtitleController.text,
                  imageUrl: imageUrlController.text,
                  type: 'sponsored',
                  order: int.tryParse(orderController.text) ?? 1,
                );

                if (banner == null) {
                  await _firestoreService.addBanner(newBanner);
                } else {
                  await _firestoreService.updateBanner(newBanner);
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
        title: const Text('Manage Sponsored Banners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: StreamBuilder<List<BannerModel>>(
        stream: _firestoreService.getBanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading banners'));
          }

          // Filter only sponsored
          final banners = (snapshot.data ?? [])
              .where((b) => b.type == 'sponsored')
              .toList();

          if (banners.isEmpty) {
            return const Center(
              child: Text('No sponsored banners found. Tap + to add.'),
            );
          }

          return ListView.builder(
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: banner.imageUrl.isNotEmpty
                      ? Image.network(
                          banner.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50),
                        )
                      : const Icon(Icons.image, size: 50),
                  title: Text(banner.title.isNotEmpty ? banner.title : 'No Title'),
                  subtitle: Text('Type: ${banner.type} | Order: ${banner.order}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showForm(banner: banner),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _firestoreService.deleteBanner(banner.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
