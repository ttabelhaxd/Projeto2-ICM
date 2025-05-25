import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';
import '../widgets/image_card.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = context.watch<HiveService>();
    final images = hiveService.getAllImages();

    return images.isEmpty
        ? const Center(
      child: Text('Nenhuma imagem de emergência compartilhada ainda.'),
    )
        : ListView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ImageCard(image: images[index]);
      },
    );
  }
}