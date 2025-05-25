import 'dart:io';

import 'package:flutter/material.dart';
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
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Image.file(File(image.imagePath)),
            title: Text('Enviado em: ${image.timestamp.toString()}'),
            subtitle: Text('Status: ${image.synced ? "Enviado" : "Pendente"}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
            },
          ),
        );
      },
    );
  }
}