import 'dart:io';
import 'package:flutter/material.dart';
import '../models/emergency_image.dart';

class ImageModal extends StatelessWidget {
  final EmergencyImage image;

  const ImageModal({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.file(
                File(image.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black54,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviado por: ${image.username}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Data: ${_formatDate(image.timestamp)}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (image.location != null)
                  Text(
                    'Local: ${image.location}',
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}