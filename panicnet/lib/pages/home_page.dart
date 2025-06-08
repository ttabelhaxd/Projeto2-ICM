import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:panicnet/pages/photoShare_page.dart';
import '../components/layout/Drawer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('panicnet');
  List<String> marksCoords = [];
  late String userName =
  box.get('user', defaultValue: '');
  late Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};
  Position? position;
  bool _isDiscovering = false;
  bool _isAdvertising = false;

  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<Position> _getCurrentPosition() async {
    return Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _askPermissions();
    _getCurrentPosition().then((value) {
      setState(() {
        position = value;
      });
    });
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _askPermissions() async {
    await Permission.location.isGranted;
    await Permission.location.request();

    bool granted = !(await Future.wait([
      Permission.bluetooth.isGranted,
      Permission.bluetoothAdvertise.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.bluetoothScan.isGranted,
      Permission.nearbyWifiDevices.isGranted,
      Permission.storage.isGranted,
    ]))
        .any((element) => false);
    [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.storage,
      Permission.notification,
    ].request();
  }

  Future<void> _startDiscovery() async {
    try {
      setState(() => _isDiscovering = true);
      bool a = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          showModalBottomSheet(
            context: context,
            builder: (builder) {
              return Center(
                child: Column(
                  children: <Widget>[
                    Text("id: $id"),
                    Text("Name: $name"),
                    Text("ServiceId: $serviceId"),
                    ElevatedButton(
                      child: const Text("Request Connection"),
                      onPressed: () {
                        Navigator.pop(context);
                        Nearby().requestConnection(
                          userName,
                          id,
                          onConnectionInitiated: (id, info) {
                            onConnectionInit(id, info);
                          },
                          onConnectionResult: (id, status) {},
                          onDisconnected: (id) {
                            setState(() {
                              endpointMap.remove(id);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        onEndpointLost: (id) {
          showSnackbar(
              "Lost discovered Endpoint: ${endpointMap[id]?.endpointName}, id $id");
        },
      );
      if (!a) {
        setState(() => _isDiscovering = false);
      }
    } catch (exception) {
      setState(() => _isDiscovering = false);
      if (await Permission.nearbyWifiDevices.isDenied) {
        Permission.nearbyWifiDevices.request();
      }
    }
  }

  Future<void> _stopDiscovery() async {
    try {
      await Nearby().stopDiscovery();
      setState(() => _isDiscovering = false);
    } catch (e) {
      showSnackbar("Error stopping discovery: $e");
    }
  }

  Future<void> _startAdvertising() async {
    try {
      setState(() => _isAdvertising = true);
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {},
        onDisconnected: (id) {
          showSnackbar(
              "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
      if (!a) {
        setState(() => _isAdvertising = false);
      }
    } catch (exception) {
      setState(() => _isAdvertising = false);
    }
  }

  Future<void> _stopAdvertising() async {
    try {
      await Nearby().stopAdvertising();
      setState(() => _isAdvertising = false);
    } catch (e) {
      showSnackbar("Error stopping advertising: $e");
    }
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                child: const Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);

                        if (str.contains(':')) {
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);
                        }
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                      }
                    },
                  );

                  String coordinates =
                      "${position!.latitude}:${position!.longitude}";
                  Nearby().sendBytesPayload(id, utf8.encode(coordinates));

                  _showNotification(
                    'Connection Accepted',
                    'Connected to ${info.endpointName}',
                  );
                },
              ),
              ElevatedButton(
                child: const Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    // showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          print("====================================");
          print('Received coordinates: $str');
          print("info: $info.endpointName");
          print("====================================");
          _addReceivedCoordinates("${info.endpointName}:$str");
        }
      },
      onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
        if (payloadTransferUpdate.status == PayloadStatus.IN_PROGRESS) {
          print(payloadTransferUpdate.bytesTransferred);
        } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
          print("failed");
        } else if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
        }
      },
    );
  }

  void _addReceivedCoordinates(String coordinates) {
    setState(() {
      marksCoords.add(coordinates);
      print("====================================");
      print('Received coordinates: $marksCoords');
      print("====================================");
      // Store the updated list in Hive
      box.put('marks', marksCoords);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PanicNet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 4,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  'Status da Rede',
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conectado como: $userName',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: _isDiscovering ? Icons.stop : Icons.search,
                  label: _isDiscovering ? 'Parar Busca' : 'Procurar Ajuda',
                  color: Theme.of(context).colorScheme.secondary,
                  onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
                  isActive: _isDiscovering,
                ),
                _buildActionButton(
                  context,
                  icon: _isAdvertising ? Icons.stop : Icons.local_hospital,
                  label: _isAdvertising ? 'Parar Oferecer' : 'Oferecer Ajuda',
                  color: Theme.of(context).colorScheme.tertiary,
                  onPressed: _isAdvertising ? _stopAdvertising : _startAdvertising,
                  isActive: _isAdvertising,
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Dispositivos Próximos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildDeviceList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green
                : color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.green : color).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 32),
            color: Theme.of(context).colorScheme.onSecondary,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    if (endpointMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.device_unknown,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dispositivo encontrado',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: endpointMap.length,
      itemBuilder: (context, index) {
        final key = endpointMap.keys.elementAt(index);
        final endpointName = endpointMap[key]!.endpointName;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(endpointName),
            subtitle: Text(
              'Toque para conectar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoSharePage(
                    device: endpointName,
                    endpointId: key,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}