import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:panicnet/pages/home_page.dart';
import 'package:panicnet/pages/login_page.dart';
import 'package:panicnet/pages/gallery_page.dart';
import 'package:panicnet/pages/settings_page.dart';
import 'package:panicnet/providers/gesture_provider.dart';
import 'package:panicnet/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('panicnet');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => GestureProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('panicnet');
    final isLoggedIn = box.containsKey('user');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PanicNet',
      theme: Provider.of<ThemeProvider>(context).theme,
      themeMode: ThemeMode.system,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/gallery': (context) => const GalleryPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}