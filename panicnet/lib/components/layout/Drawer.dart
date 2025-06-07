import 'package:panicnet/components/layout/MenuItem.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('panicnet');
    final user = box.get('user', defaultValue: '');
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          DrawerHeader(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Image(
                  image: AssetImage('assets/images/logo.png'),
                  height: 90,
                ),
                Text(
                  "Welcome,\n$user",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                'H O M E',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: Icon(
                Icons.photo,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                'G A L L E R Y',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gallery');
              },
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                'S E T T I N G S',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ),
        ],
      ),
    );
  }
}
