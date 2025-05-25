import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/emergency_image.dart';

class BluetoothService {
  static const serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const characteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

  Future<void> shareImage(EmergencyImage image) async {
    try {
      if (!await FlutterBluePlus.isAvailable) return;

      // 1. Verificar e ligar Bluetooth
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
      }

      // 2. Procurar dispositivos
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      // 3. Conectar e enviar para cada dispositivo
      await for (var scanResult in FlutterBluePlus.scanResults) {
        for (var result in scanResult) {
          if (result.advertisementData.connectable) {
            try {
              await result.device.connect(autoConnect: false);

              // Enviar dados (implementação simplificada)
              final services = await result.device.discoverServices();
              for (var service in services) {
                if (service.serviceUuid.toString().toUpperCase() == serviceUuid) {
                  for (var characteristic in service.characteristics) {
                    if (characteristic.characteristicUuid.toString().toUpperCase() == characteristicUuid) {
                      await characteristic.write([1, 2, 3]); // Dados de exemplo
                    }
                  }
                }
              }

              await result.device.disconnect();
            } catch (e) {
              continue;
            }
          }
        }
      }

      await FlutterBluePlus.stopScan();
    } catch (e) {
      rethrow;
    }
  }
}