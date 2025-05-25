import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    final hiveService = Provider.of<HiveService>(context, listen: false);
    _usernameController = TextEditingController(text: hiveService.getUsername());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hiveService = Provider.of<HiveService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nome de Usuário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Digite seu nome de usuário',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await hiveService.setUsername(_usernameController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome salvo com sucesso!')),
                  );
                }
              },
              child: const Text('Salvar Configurações'),
            ),
          ],
        ),
      ),
    );
  }
}