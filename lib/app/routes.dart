import 'package:flutter/material.dart';
//import '../features/home/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/pin_login_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
//import '../features/panic/presentation/pages/panic_call_page.dart';

abstract class AppRoutes {
  //static const home = '/';
  static const pinLogin = '/pin-login';
  static const settings = '/settings';
  //static const panicCall = '/panic-call';
}

final Map<String, WidgetBuilder> appRoutes = {
  //AppRoutes.home: (_) => const HomePage(),
  AppRoutes.pinLogin: (_) => const PinLoginPage(),
  AppRoutes.settings: (_) => const SettingsPage(),
  //AppRoutes.panicCall: (_) => const PanicCallPage(),
};
