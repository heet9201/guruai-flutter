import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';

class SpeechService {
  final ApiClient _apiClient;

  SpeechService(this._apiClient);

  Future<SpeechToTextResponse> speechToText({
    required String audioData,
    required String language,
    String encoding = 'WEBM_OPUS',
  }) async {
    final request = SpeechToTextRequest(
      audioData: audioData,
      language: language,
      encoding: encoding,
    );

    final response = await _apiClient.post<SpeechToTextResponse>(
      ApiConstants.speechToText,
      data: request.toJson(),
      fromJson: (json) => SpeechToTextResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to convert speech to text');
    }
  }

  Future<TextToSpeechResponse> textToSpeech({
    required String text,
    required String language,
    required String voice,
    double? speed,
    double? pitch,
  }) async {
    final request = TextToSpeechRequest(
      text: text,
      language: language,
      voice: voice,
      speed: speed,
      pitch: pitch,
    );

    final response = await _apiClient.post<TextToSpeechResponse>(
      ApiConstants.textToSpeech,
      data: request.toJson(),
      fromJson: (json) => TextToSpeechResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to convert text to speech');
    }
  }

  Future<String> uploadAudioFile({
    required String filePath,
    String? language,
  }) async {
    final response = await _apiClient.uploadFile(
      ApiConstants.uploadAudio,
      filePath,
      description: 'Audio file for transcription',
      tags: ['audio', 'transcription', language ?? 'en-US'],
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.id;
    } else {
      throw ApiError(message: response.error ?? 'Failed to upload audio file');
    }
  }

  Future<List<SpeechToTextResponse>> batchTranscribe({
    required List<String> audioFileIds,
    String? language,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.batchTranscribe,
      data: {
        'file_ids': audioFileIds,
        'language': language ?? 'en-US',
      },
    );

    if (response.isSuccess && response.data != null) {
      final transcriptionsList = response.data['transcriptions'] as List;
      return transcriptionsList
          .map((json) => SpeechToTextResponse.fromJson(json))
          .toList();
    } else {
      throw ApiError(message: response.error ?? 'Failed to batch transcribe');
    }
  }

  Future<Map<String, dynamic>> getSpeechStatus() async {
    final response = await _apiClient.get(ApiConstants.speechStatus);

    if (response.isSuccess && response.data != null) {
      return response.data;
    } else {
      throw ApiError(message: response.error ?? 'Failed to get speech status');
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    final response = await _apiClient.get(ApiConstants.supportedLanguages);

    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data['languages']);
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get supported languages');
    }
  }

  // Utility methods
  List<Map<String, String>> getDefaultVoices() {
    return [
      {
        'language': 'en-US',
        'voice': 'en-US-Standard-A',
        'name': 'English (US) - Female'
      },
      {
        'language': 'en-US',
        'voice': 'en-US-Standard-B',
        'name': 'English (US) - Male'
      },
      {
        'language': 'en-IN',
        'voice': 'en-IN-Standard-A',
        'name': 'English (India) - Female'
      },
      {
        'language': 'en-IN',
        'voice': 'en-IN-Standard-B',
        'name': 'English (India) - Male'
      },
      {
        'language': 'hi-IN',
        'voice': 'hi-IN-Standard-A',
        'name': 'Hindi - Female'
      },
      {
        'language': 'hi-IN',
        'voice': 'hi-IN-Standard-B',
        'name': 'Hindi - Male'
      },
    ];
  }

  String getLanguageCode(String languageName) {
    final languageMap = {
      'English': 'en-US',
      'Hindi': 'hi-IN',
      'Spanish': 'es-ES',
      'French': 'fr-FR',
      'German': 'de-DE',
      'Chinese': 'zh-CN',
    };
    return languageMap[languageName] ?? 'en-US';
  }
}
