import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/shake_detector_service.dart';

class EmergencyButton extends StatelessWidget {
  final bool showManualOption;

  const EmergencyButton({
    super.key,
    this.showManualOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final shakeDetector = Provider.of<ShakeDetectorService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'MODO EMERGÊNCIA ATIVO',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                // Simula o abanar para desenvolvimento/teste
                shakeDetector.onShakeDetected();
              },
            ),
          ),
          if (showManualOption) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                shakeDetector.onShakeDetected();
              },
              child: const Text(
                'Ativar Emergência Manualmente',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Ou abane o telefone para ativar',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}