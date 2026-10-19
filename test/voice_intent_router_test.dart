import 'package:flutter_test/flutter_test.dart';
import 'package:carebridge/services/voice_intent_router.dart';
import 'package:carebridge/services/voice_service.dart';

void main() {
  group('Speech recognition locale matching', () {
    test('recognizes Malayalam locale ids with or without a region', () {
      expect(VoiceService.isMalayalamLocaleId('ml'), isTrue);
      expect(VoiceService.isMalayalamLocaleId('ml_IN'), isTrue);
      expect(VoiceService.isMalayalamLocaleId('ml-IN'), isTrue);
      expect(VoiceService.isMalayalamLocaleId('ML-in'), isTrue);
      expect(VoiceService.isMalayalamLocaleId('en_IN'), isFalse);
    });
  });

  group('Wake phrase recognition', () {
    test('Hello Mac wake word activates and extracts command', () {
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Hello Mac, ഇന്നത്തെ മരുന്ന്',
          assistantName: 'Mac',
        ),
        'ഇന്നത്തെ മരുന്ന്',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'ഹലോ മാക്, ഡോക്ടറെ കാണാൻ സമയമായോ',
          assistantName: 'മാക്',
        ),
        'ഡോക്ടറെ കാണാൻ സമയമായോ',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Hey Mac, what is my schedule?',
          assistantName: 'Mac',
        ),
        'what is my schedule?',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'ഹലോ മാക്ക്, വെള്ളം കുടിക്കണം',
          assistantName: 'മാക്ക്',
        ),
        'വെള്ളം കുടിക്കണം',
      );
    });

    test('Hello Mac wake word by itself prompts for user command', () {
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Hello Mac',
          assistantName: 'Mac',
        ),
        '',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord('Mac', assistantName: 'Mac'),
        '',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'ഹലോ മാക്',
          assistantName: 'മാക്',
        ),
        '',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord('മാക്', assistantName: 'മാക്'),
        '',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'ഹലോ മാക്ക്',
          assistantName: 'മാക്ക്',
        ),
        '',
      );
    });

    test('only the configured wake name activates', () {
      expect(VoiceIntentRouter.commandAfterWakeWord('Care'), '');
      expect(VoiceIntentRouter.commandAfterWakeWord('കെയർ'), isNull);
      expect(VoiceIntentRouter.commandAfterWakeWord('Caroo'), isNull);
      expect(VoiceIntentRouter.commandAfterWakeWord('Karo'), isNull);
      expect(
        VoiceIntentRouter.commandAfterWakeWord('CareBridge, മരുന്ന്'),
        isNull,
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Care, ഇന്നത്തെ മരുന്ന്',
          assistantName: 'Amma',
        ),
        isNull,
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Please call Amma, show my medicines',
          assistantName: 'Amma',
        ),
        isNull,
      );
    });

    test('ambient speech without wake word does not activate', () {
      expect(
        VoiceIntentRouter.commandAfterWakeWord('ഇന്നത്തെ മരുന്ന്'),
        isNull,
      );
      expect(VoiceIntentRouter.commandAfterWakeWord('നല്ല കാലാവസ്ഥ'), isNull);
    });

    test('user-chosen English and Malayalam names activate', () {
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Sara, I have a headache',
          assistantName: 'Sara',
        ),
        'I have a headache',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Hey Amma, show my appointments',
          assistantName: 'Amma',
        ),
        'show my appointments',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'ഹലോ അമ്മേ വെള്ളം കുടിക്കേണ്ട സമയം',
          assistantName: 'അമ്മേ',
        ),
        'വെള്ളം കുടിക്കേണ്ട സമയം',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Tell me about my appointments',
          assistantName: 'Amma',
        ),
        isNull,
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Siri, help me',
          assistantName: 'Siri',
        ),
        'help me',
      );
      expect(
        VoiceIntentRouter.commandAfterWakeWord(
          'Meena, help me',
          assistantName: 'Siri',
        ),
        isNull,
      );
    });
  });

  group('Care Emergency SOS', () {
    test('Hello Mac & Care Emergency commands are detected accurately', () {
      expect(
        VoiceIntentRouter.isCareEmergencyCommand('Hello Mac Emergency'),
        isTrue,
      );
      expect(VoiceIntentRouter.isCareEmergencyCommand('Mac Emergency'), isTrue);
      expect(
        VoiceIntentRouter.isCareEmergencyCommand('ഹലോ മാക് എമർജൻസി'),
        isTrue,
      );
      expect(
        VoiceIntentRouter.isCareEmergencyCommand('Care Emergency'),
        isTrue,
      );
      expect(VoiceIntentRouter.isCareEmergencyCommand('കെയർ എമർജൻസി'), isTrue);
      expect(
        VoiceIntentRouter.isCareEmergencyCommand('care emergency!'),
        isTrue,
      );
      expect(
        VoiceIntentRouter.detect('Hello Mac Emergency'),
        VoiceIntentType.emergency,
      );
      expect(
        VoiceIntentRouter.detect('ഹലോ മാക് എമർജൻസി'),
        VoiceIntentType.emergency,
      );
      expect(
        VoiceIntentRouter.detect('Care Emergency'),
        VoiceIntentType.emergency,
      );
      expect(
        VoiceIntentRouter.detect('കെയർ എമർജൻസി'),
        VoiceIntentType.emergency,
      );
    });

    test('colloquial and distress emergency phrases trigger emergency', () {
      expect(VoiceIntentRouter.detect('രക്ഷിക്കണം'), VoiceIntentType.emergency);
      expect(VoiceIntentRouter.detect('സഹായിക്കൂ'), VoiceIntentType.emergency);
      expect(VoiceIntentRouter.detect('നെഞ്ചുവേദന'), VoiceIntentType.emergency);
      expect(
        VoiceIntentRouter.detect('താഴെ വീണുപോയി എഴുന്നേൽക്കാൻ വയ്യ'),
        VoiceIntentType.emergency,
      );
      expect(
        VoiceIntentRouter.detect('ശ്വാസം മുട്ടുന്നു ആംബുലൻസ് വിളിക്ക്'),
        VoiceIntentType.emergency,
      );
    });

    test('custom emergency phrase triggers emergency', () {
      expect(
        VoiceIntentRouter.detect(
          'അമ്മേ സഹായിക്കണേ',
          customEmergencyPhrases: ['അമ്മേ സഹായിക്കണേ'],
        ),
        VoiceIntentType.emergency,
      );
    });
  });

  group('Care plan intent detection', () {
    test(
      'Malayalam and colloquial medicine questions match medicineToday intent',
      () {
        expect(
          VoiceIntentRouter.detect('ഇന്നത്തെ മരുന്നിന്റെ ലിസ്റ്റ്'),
          VoiceIntentType.medicineToday,
        );
        expect(
          VoiceIntentRouter.detect('എന്റെ ഗുളിക എപ്പോഴാ കഴിക്കേണ്ടത്'),
          VoiceIntentType.medicineToday,
        );
        expect(
          VoiceIntentRouter.detect('Which medicine should I take now?'),
          VoiceIntentType.medicineToday,
        );
        expect(
          VoiceIntentRouter.detect('മരുന്ന് സമയം ആയോ'),
          VoiceIntentType.medicineToday,
        );
      },
    );

    test('appointment questions match appointmentToday intent', () {
      expect(
        VoiceIntentRouter.detect('ഇന്ന് ഡോക്ടറെ കാണിക്കാനുണ്ടോ'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('ആശുപത്രിയിൽ പോകാൻ appointment ഉണ്ടോ'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('When is my next doctor consultation?'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('Do I have a doctor appointment today?'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('When is my next doctor visit?'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('doctor appointment undo'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('ഡോക്ടറെ കാണണം'),
        VoiceIntentType.appointmentToday,
      );
      expect(
        VoiceIntentRouter.detect('I have a headache and spoke to my doctor'),
        VoiceIntentType.chat,
      );
    });

    test('meal and water questions match careReminders intent', () {
      expect(
        VoiceIntentRouter.detect('വെള്ളം കുടിക്കേണ്ട സമയം എപ്പോഴാണ്'),
        VoiceIntentType.careReminders,
      );
      expect(
        VoiceIntentRouter.detect('വിശക്കുന്നു ഭക്ഷണം കഴിക്കാൻ സമയമായോ'),
        VoiceIntentType.careReminders,
      );
      expect(
        VoiceIntentRouter.detect('ഉച്ചഭക്ഷണം എപ്പോഴാണ്'),
        VoiceIntentType.careReminders,
      );
      expect(
        VoiceIntentRouter.detect('കുടിവെള്ള ഓർമ്മപ്പെടുത്തൽ'),
        VoiceIntentType.careReminders,
      );
    });

    test('general questions fall through to chat', () {
      expect(
        VoiceIntentRouter.detect('ഇന്നത്തെ വിശേഷങ്ങൾ എന്തൊക്കെയാണ്'),
        VoiceIntentType.chat,
      );
      expect(VoiceIntentRouter.detect('സുഖമാണോ'), VoiceIntentType.chat);
    });
  });
}
