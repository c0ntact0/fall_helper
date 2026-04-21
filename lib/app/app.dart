import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class FallHelperApp extends StatelessWidget {

  const FallHelperApp({super.key});
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fall Helper',
      theme: appTheme,
      initialRoute: AppRoutes.home,
      routes: appRoutes,

    );

  }
   


}