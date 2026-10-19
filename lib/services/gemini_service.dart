import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Service connecting CareBridge to Gemini for grounded, multilingual
/// conversation about the app and the elder's care reminders.
class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  static const String _modelName = 'gemini-3.5-flash';
  String _activeModelName = _modelName;
  String _assistantName = 'Care';

  String get _systemPrompt =>
      '''
You are "$_assistantName", a caring, gentle, and respectful conversational helper inside the CareBridge app for an older adult in Kerala. You are not a doctor, nurse, or emergency service.

Key Guidelines:
1. Language & Natural Tone:
   - Match the language and style the user uses: Malayalam, English, or a Malayalam-English mix.
   - Understand colloquial Malayalam, including Malabar speech from Malappuram and Kasaragod, other Kerala regional expressions, and Malayalam written phonetically in English (Manglish).
   - Do not force one district's dialect onto the user. Reply naturally in the user's own style; if a regional word is genuinely unclear, ask a short, kind clarification instead of saying you cannot process the sentence.
   - Keep answers concise (1 to 3 short sentences), polite, and easy to understand when read aloud by Text-to-Speech (TTS).

2. Care Domain Responsibilities:
   - Explain how to use CareBridge and help the user understand their appointments, medicine, meal, and water reminders.
   - You may have a friendly conversation, but do not diagnose, prescribe, recommend changing a treatment, or present yourself as a healthcare professional.
   - For medical concerns, encourage the user to contact their doctor or family. For emergencies, direct them to the app's Emergency SOS button.
   - When the elder mentions a symptom such as a headache, respond with empathy. Do not guess the cause or recommend medicine. Ask one brief question about how severe it is or when it started, and encourage contacting their doctor or family if it persists or worries them.
   - When care plan records are provided in context, use ONLY those verified facts.
   - NEVER invent medicine names, dosages, frequencies, or appointment times. If information is not in the records, clearly and kindly say so in the user's language.

3. Emergency Awareness:
   - If the user reports sudden severe pain or headache, chest pain, difficulty breathing, fainting, signs of stroke, a serious fall, or cries for help, advise them to use Emergency SOS or ask someone nearby for urgent help. Never claim that help has been alerted unless the app confirms it.

4. Unclear Speech Handling:
   - If the user's speech is unclear or ambiguous, ask kindly to repeat: "ക്ഷമിക്കണം, എനിക്ക് വ്യക്തമായി കേൾക്കാൻ കഴിഞ്ഞില്ല. ഒന്നുകൂടി പറയാമോ?".
''';

  GeminiService() {
    _initModel();
  }

  void setAssistantName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized == _assistantName) return;
    _assistantName = normalized;
    _initModel();
  }

  void _initModel() {
    _activeModelName = _modelName;
    final ai = FirebaseAI.googleAI();
    _model = ai.generativeModel(
      model: _activeModelName,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(maxOutputTokens: 256),
    );
    _chatSession = _model!.startChat();
    debugPrint('GeminiService initialized with model: $_activeModelName');
  }

  /// Clears the multi-turn chat history.
  void resetChat() {
    _chatSession = _model?.startChat();
  }

  Future<GenerateContentResponse> _sendContent(Content content) async {
    final chatSession = _chatSession;
    if (chatSession == null) {
      return _model!.generateContent([content]);
    }

    try {
      return await chatSession.sendMessage(content);
    } catch (error) {
      debugPrint(
        'Gemini chat session error, retrying with generateContent: $error',
      );
      return _model!.generateContent([content]);
    }
  }

  /// Sends the user message to Gemini with conversation context and optional care-plan data.
  Future<String> askGemini(String message, {String? carePlanContext}) async {
    final query = message.trim();
    if (query.isEmpty) {
      return 'എന്താണ് ചോദിക്കാൻ ഉദ്ദേശിച്ചത്? ദയവായി പറയൂ.';
    }

    try {
      if (_model == null || _chatSession == null) {
        _initModel();
      }

      debugPrint('Sending voice chat request to Gemini ($_activeModelName).');

      final promptText = carePlanContext == null
          ? query
          : '''
Verified Care Records for this elder:
$carePlanContext

Elder's question: $query
Remember: Use only the verified records above for medicine/appointment/meal/water questions. Answer warmly and concisely in Malayalam.
''';

      final content = Content.text(promptText);

      // Attempt sending via continuous chat session for multi-turn conversational context
      final response = await _sendContent(content);
      final reply = response.text?.trim();
      if (reply != null && reply.isNotEmpty) {
        return reply;
      }

      return 'ക്ഷമിക്കണം, എനിക്ക് ഇപ്പോൾ വ്യക്തമായ ഉത്തരം നൽകാൻ കഴിഞ്ഞില്ല. ദയവായി ഒന്നുകൂടി ചോദിക്കാമോ?';
    } catch (e, stackTrace) {
      debugPrint('GEMINI ERROR: $e\n$stackTrace');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('offline')) {
        return 'ഇന്റർനെറ്റ് കണക്ഷനിൽ തടസ്സമുണ്ട്. ദയവായി അല്പം കഴിഞ്ഞ് വീണ്ടും ചോദിക്കൂ.';
      }
      if (errorStr.contains('quota') ||
          errorStr.contains('resource_exhausted')) {
        return 'ഇപ്പോൾ സേവനം തിരക്കിലാണ്. അല്പം കഴിഞ്ഞ് വീണ്ടും ചോദിക്കൂ.';
      }
      if (errorStr.contains('not found') || errorStr.contains('404')) {
        return 'സംഭാഷണ സേവനം ഇപ്പോൾ ലഭ്യമല്ല. ദയവായി CareBridge അപ്ഡേറ്റ് ചെയ്ത് കുടുംബാംഗത്തോട് അറിയിക്കൂ.';
      }
      if (errorStr.contains('permission_denied') ||
          errorStr.contains('api key') ||
          errorStr.contains('unauthenticated')) {
        return 'സംഭാഷണ സേവനത്തിന് അനുമതി ലഭിച്ചില്ല. ദയവായി കുടുംബാംഗത്തെയോ CareBridge സഹായത്തെയോ ബന്ധപ്പെടൂ.';
      }
      if (errorStr.contains('failed_precondition') ||
          errorStr.contains('not enabled')) {
        return 'സംഭാഷണ സേവനം സജ്ജീകരിക്കാനായില്ല. ദയവായി CareBridge സഹായത്തെയോ കുടുംബാംഗത്തെയോ ബന്ധപ്പെടൂ.';
      }

      return 'മറുപടി തയ്യാറാക്കുമ്പോൾ ഒരു തടസ്സം ഉണ്ടായി. നിങ്ങളുടെ ചോദ്യം വീണ്ടും പറയുകയോ ടൈപ്പ് ചെയ്യുകയോ ചെയ്യൂ.';
    }
  }
}
