import 'dart:async';

import 'package:light/light.dart';

class LightSensorService {
  final Light _light = Light();

  Future<void> requestAuthorization() async {
    await _light.requestAuthorization();
  }

  Stream<int> get lightStream => _light.lightSensorStream;
}
