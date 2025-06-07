import 'package:panicnet/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  // get the brightness of the device from the platform
  var brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  // by default we will use light theme
  ThemeData _theme = lightMode;

  // change theme based on the brightness of the device
  ThemeProvider() {
    _theme = brightness == Brightness.dark ? darkMode : lightMode;
  }

  ThemeData get theme => _theme;

  bool get isDarkMode => _theme == darkMode;

  set themeData(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }
  
  // toggle between dark and light mode
  void toggleTheme() {
    _theme = isDarkMode ? lightMode : darkMode;
    notifyListeners();
  }
}
