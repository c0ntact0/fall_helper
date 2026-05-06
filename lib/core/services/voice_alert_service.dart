import 'package:flutter_tts/flutter_tts.dart';

class VoiceAlertService {
  VoiceAlertService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _init() async {
    if (_isInitialized) return;

    await _tts.setLanguage('pt-PT');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);

    _isInitialized = true;
  }

  Future<void> speak(String message) async {
    await _init();
    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> speakFlashlightOn() async {
    await speak('Lanterna ligada');
  }

  Future<void> speakFlashlightOff() async {
    await speak('Lanterna desligada');
  }

  Future<void> speakAlertSentToCaregiver() async {
    await speak('Alerta enviado para o cuidador');
  }

  Future<void> speakCallingCaregiver() async {
    await speak('A fazer chamada para o cuidador');
  }

  Future<void> speakCallingCaregiverFailed() async {
    await speak('Não consegui fazer chamada para o cuidador');
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
