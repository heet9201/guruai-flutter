import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart'; // Temporarily disabled

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late FlutterTts _flutterTts;
  // late SpeechToText _speechToText; // Temporarily disabled
  bool _isTtsInitialized = false;
  // bool _isSttInitialized = false; // Temporarily disabled

  // Text-to-Speech
  Future<void> initializeTts() async {
    if (_isTtsInitialized) return;

    _flutterTts = FlutterTts();

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _isTtsInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isTtsInitialized) await initializeTts();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    if (!_isTtsInitialized) return;
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    if (!_isTtsInitialized) return;
    await _flutterTts.pause();
  }

  // Speech-to-Text (Temporarily disabled due to package compatibility issues)
  Future<bool> initializeStt() async {
    // if (_isSttInitialized) return true;
    // _speechToText = SpeechToText();
    // bool available = await _speechToText.initialize(
    //   onStatus: (status) => print('STT Status: $status'),
    //   onError: (error) => print('STT Error: $error'),
    // );
    // _isSttInitialized = available;
    // return available;
    print('Speech-to-text temporarily disabled');
    return false;
  }

  Future<void> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    // if (!_isSttInitialized) {
    //   bool initialized = await initializeStt();
    //   if (!initialized) return;
    // }
    // if (!_speechToText.isListening) {
    //   await _speechToText.listen(
    //     onResult: (result) => onResult(result.recognizedWords),
    //     localeId: localeId ?? 'en_US',
    //     listenMode: ListenMode.confirmation,
    //   );
    // }
    print('Speech-to-text temporarily disabled');
  }

  Future<void> stopListening() async {
    // if (!_isSttInitialized) return;
    // await _speechToText.stop();
    print('Speech-to-text temporarily disabled');
  }

  bool get isListening => false; // _speechToText.isListening;
  bool get isAvailable => false; // _speechToText.isAvailable;

  Future<List<String>> get availableLocales async =>
      []; // _speechToText.locales();

  void dispose() {
    _flutterTts.stop();
    // _speechToText.stop();
  }
}
