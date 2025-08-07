abstract interface class SpeechToTextService {
  Future<String?> listen();
  void stopListening();
  Stream<String> get transcriptionStream;
  Stream<bool> get listeningStateStream;
}