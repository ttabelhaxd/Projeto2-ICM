import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _askUsername();
    _initBluetooth();
  }

  Future<void> _askUsername() async {
    await Future.delayed(Duration.zero);
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Insere o teu nome'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () {
                username = controller.text.trim().isEmpty
                    ? 'Utilizador'
                    : controller.text.trim();
                Navigator.of(context).pop();
              },
              child: const Text('OK')),
        ],
      ),
    );
    setState(() {});
  }

  void _initBluetooth() async {
    FlutterBluetoothSerial.instance.requestEnable();
  }

  Future<void> _tirarFoto() async {
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      final bytes = await foto.readAsBytes();
      final uuid = const Uuid().v4();
      await Hive.box('fotos').put(uuid, bytes);
      _enviarPorBluetooth(uuid, bytes);
      setState(() {});
    }
  }

  void _enviarPorBluetooth(String id, Uint8List data) async {
    final bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    for (var device in bondedDevices) {
      try {
        var connection =
            await BluetoothConnection.toAddress(device.address);
        connection.output.add(Uint8List.fromList('$id|'.codeUnits + data));
        await connection.output.allSent;
        connection.finish();
      } catch (_) {}
    }
  }

  Widget _buildGaleria() {
    final fotos = Hive.box('fotos');
    return ListView.builder(
      itemCount: fotos.length,
      itemBuilder: (context, i) {
        final key = fotos.keyAt(i);
        final bytes = fotos.get(key);
        return Card(
          child: ListTile(
            title: Text('Foto $key'),
            leading: Image.memory(bytes, width: 50, height: 50, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bem-vindo, $username')),
      body: _buildGaleria(),
      floatingActionButton: FloatingActionButton(
        onPressed: _tirarFoto,
        child: const Icon(Icons.camera),
      ),
    );
  }
}
