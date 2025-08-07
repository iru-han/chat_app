import '../../domain/service/speech_to_text_service.dart';
import '../data_source/google_stt_data_source.dart';

class SpeechToTextServiceImpl implements SpeechToTextService {
  final GoogleSTTDataSource _sttDataSource;

  SpeechToTextServiceImpl({required GoogleSTTDataSource sttDataSource})
      : _sttDataSource = sttDataSource;

  @override
  Future<String?> listen() {
    return _sttDataSource.startListening();
  }

  @override
  void stopListening() {
    _sttDataSource.stopListening();
  }

  @override
  Stream<String> get transcriptionStream => _sttDataSource.transcriptionStream;

  @override
  Stream<bool> get listeningStateStream => _sttDataSource.listeningStateStream;

  void dispose() {
    _sttDataSource.dispose();
  }
}