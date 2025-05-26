import 'dart:io';
import 'package:flutter/material.dart';
import '../modals/image_modal.dart';
import '../models/emergency_image.dart';

class ImageList extends StatelessWidget {
  final List<EmergencyImage> images;

  const ImageList({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
        child: Text('Nenhuma emergência registrada ainda'),
      );
    }

    return ListView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () => _showImageModal(context, image),
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(image.imagePath),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text('Enviado em: ${_formatDate(image.timestamp)}'),
              subtitle: Text('Status: ${image.synced ? "Enviado" : "Pendente"}'),
              trailing: const Icon(Icons.zoom_in),
            ),
          ),
        );
      },
    );
  }

  void _showImageModal(BuildContext context, EmergencyImage image) {
    showDialog(
      context: context,
      builder: (context) => ImageModal(image: image),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}