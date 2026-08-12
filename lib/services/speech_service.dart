import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around the `speech_to_text` plugin.
class SpeechService {
  SpeechService._() : _speech = SpeechToText();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech;
  Future<void>? _initialization;
  bool _initialized = false;
  bool _operationInProgress = false;
  bool _stopRequested = false;

  final ValueNotifier<bool> available = ValueNotifier<bool>(false);
  final ValueNotifier<bool> listening = ValueNotifier<bool>(false);
  final ValueNotifier<String> lastWords = ValueNotifier<String>('');
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  Future<void> init() {
    if (_initialized) return Future<void>.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final ok = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          lastError.value = error.errorMsg;
          listening.value = false;
        },
        onStatus: (String status) {
          listening.value = status == 'listening';
        },
      );
      available.value = ok;
      _initialized = ok;
    } catch (error) {
      available.value = false;
      lastError.value = error.toString();
      rethrow;
    } finally {
      _initialization = null;
    }
  }

  /// Start listening. Recognized text streams into [lastWords].
  Future<void> startListening({String localeId = 'en_US'}) async {
    if (_operationInProgress || listening.value) return;
    _operationInProgress = true;
    _stopRequested = false;
    lastError.value = null;
    lastWords.value = '';
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          lastWords.value = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          localeId: localeId,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      if (_stopRequested) {
        await _speech.stop();
        listening.value = false;
      } else {
        listening.value = true;
      }
    } catch (error) {
      listening.value = false;
      lastError.value = error.toString();
      rethrow;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> stopListening() async {
    if (_operationInProgress && !listening.value) {
      _stopRequested = true;
      return;
    }
    try {
      await _speech.stop();
    } catch (error) {
      lastError.value = error.toString();
    } finally {
      listening.value = false;
    }
  }
}
