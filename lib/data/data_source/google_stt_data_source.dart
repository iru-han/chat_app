import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';

class GoogleSTTDataSource {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  final StreamController<bool> _listeningStateController = StreamController<bool>.broadcast();
  Stream<bool> get listeningStateStream => _listeningStateController.stream;

  GoogleSTTDataSource() {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        _listeningStateController.add(_speechToText.isListening);
        print('STT Status: $status');
      },
      onError: (errorNotification) {
        print('STT Error: ${errorNotification.errorMsg}');
        _listeningStateController.add(false);
      },
    );
    _listeningStateController.add(_speechEnabled && _speechToText.isListening);
    print('Speech enabled: $_speechEnabled');
  }

  /// Each time to start a speech recognition session
  Future<String?> startListening() async {
    if (_speechEnabled) {
      _lastWords = ''; // Clear previous words
      _transcriptionController.add(''); // Clear previous transcription
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // Max duration to listen
        pauseFor: const Duration(seconds: 5), // Pause duration
        localeId: 'ko_KR', // Korean locale
      );
      _listeningStateController.add(true);
      // Wait for a short period to get the initial transcription
      await Future.delayed(const Duration(milliseconds: 500));
      return null; // The result will be streamed via _transcriptionController
    } else {
      print('Speech recognition not enabled');
      return null;
    }
  }

  void stopListening() {
    _speechToText.stop();
    _listeningStateController.add(false);
  }

  /// This is the callback that the SpeechToText
  /// plugin calls when the platform returns a SpeechRecognitionResult.
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _transcriptionController.add(_lastWords);
    print('Recognized: $_lastWords');
  }

  void dispose() {
    _speechToText.cancel();
    _transcriptionController.close();
    _listeningStateController.close();
  }
}