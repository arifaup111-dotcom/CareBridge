import 'package:cloud_functions/cloud_functions.dart';

class GeminiConversationService {
  GeminiConversationService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;
  final List<Map<String, String>> _history = [];

  Future<String> reply({
    required String userMessage,
    required String outcome,
  }) async {
    final text = userMessage.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(
        userMessage,
        'userMessage',
        'Must not be empty',
      );
    }

    final result = await _functions.httpsCallable('elderVoiceReply').call({
      'userMessage': text,
      'outcome': outcome,
      'history': _history,
    });
    if (result.data is! Map) {
      throw StateError('The voice assistant returned an invalid response.');
    }
    final reply = (result.data as Map)['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw StateError('The voice assistant returned an empty response.');
    }

    _history
      ..add({'role': 'user', 'text': text})
      ..add({'role': 'assistant', 'text': reply.trim()});
    if (_history.length > 8) {
      _history.removeRange(0, _history.length - 8);
    }
    return reply.trim();
  }

  void clearHistory() => _history.clear();
}
