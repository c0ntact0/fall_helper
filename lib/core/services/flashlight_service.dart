import 'package:torch_light/torch_light.dart';

class FlashlightService {
  Future<bool> isTorchAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<void> enable() async {
    await TorchLight.enableTorch();
  }

  Future<void> disable() async {
    await TorchLight.disableTorch();
  }
}
