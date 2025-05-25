import 'dart:io';

import 'package:flutter/material.dart';
import '../models/emergency_image.dart';

class ImageCard extends StatelessWidget {
  final EmergencyImage image;

  const ImageCard({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.file(File(image.imagePath)), // Fixed File usage
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('De: ${image.username}'),
                Text('Em: ${image.timestamp.toString()}'),
                if (image.location != null) Text('Local: ${image.location}'),
                Row(
                  children: [
                    Icon(
                      image.synced ? Icons.cloud_done : Icons.cloud_off,
                      color: image.synced ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(image.synced ? 'Sincronizado' : 'Pendente'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}