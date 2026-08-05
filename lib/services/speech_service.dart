import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around the `speech_to_text` plugin.
///
/// Exposes a simple ValueNotifier-driven controller so the UI can react to
/// availability, listening state, and live partial recognition results. The
/// UI merges [lastWords] into whichever text field it wants — there is no
/// single shared callback, which keeps multiple screens (composer + editor)
/// from clobbering each other.
class SpeechService {
  SpeechService._() : _speech = SpeechToText();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech;

  /// Whether speech recognition is available on this device.
  final ValueNotifier<bool> available = ValueNotifier<bool>(false);

  /// Whether we are currently listening.
  final ValueNotifier<bool> listening = ValueNotifier<bool>(false);

  /// Latest recognized text (updates live as the user speaks).
  ///
  /// Resets to an empty string each time [startListening] is called.
  final ValueNotifier<String> lastWords = ValueNotifier<String>('');

  /// Latest error message, if any (cleared on next successful start).
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  Future<void> init() async {
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
  }

  /// Start listening. Recognized text streams into [lastWords].
  Future<void> startListening({String localeId = 'en_US'}) async {
    lastError.value = null;
    lastWords.value = '';
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
    listening.value = true;
  }

  Future<void> stopListening() async {
    await _speech.stop();
    listening.value = false;
  }
}
