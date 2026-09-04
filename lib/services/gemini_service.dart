import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final ai = FirebaseAI.googleAI();

    _model = ai.generativeModel(
      model: 'gemini-3.6-flash',
      systemInstruction: Content.system('''
You are CareBridge, a friendly voice assistant designed for elderly people.

Your job is to:
- Understand Malayalam and English.
- Respond naturally in Malayalam when the user speaks Malayalam.
- Respond in English when the user speaks English.
- Keep answers short, simple and easy for elderly people to understand.
- Help with medicines, appointments, reminders, family contacts and emergency assistance.
- Never give dangerous medical advice.
- If the user describes an emergency, advise them to use the Emergency SOS feature.

If the user speaks Malayalam, reply completely in Malayalam.
'''),
    );
  }

  Future<String> askGemini(String message) async {
    try {
      debugPrint("Sending to Gemini: $message");

      final response = await _model.generateContent([Content.text(message)]);

      debugPrint("Gemini raw response: ${response.text}");

      return response.text ??
          'ക്ഷമിക്കണം, എനിക്ക് ഇപ്പോൾ മറുപടി നൽകാൻ കഴിയുന്നില്ല.';
    } catch (e, stackTrace) {
      print("GEMINI ERROR: $e");
      print("GEMINI STACKTRACE: $stackTrace");

      return 'Gemini സേവനത്തിൽ ഒരു പ്രശ്നമുണ്ട്.';
    }
  }
}
