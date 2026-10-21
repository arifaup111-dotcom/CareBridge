import 'package:carebridge/services/voice_intent_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceIntentRouter.commandAfterWakePhrase', () {
    test('returns the spoken command after the Sara wake phrase', () {
      expect(
        VoiceIntentRouter.commandAfterWakePhrase('Sara, I had my medicine'),
        'i had my medicine',
      );
    });

    test('returns an empty command when only the wake phrase is spoken', () {
      expect(VoiceIntentRouter.commandAfterWakePhrase('Sara'), '');
    });

    test('accepts Android recognition transcribing Sara as Sarah', () {
      final command = VoiceIntentRouter.commandAfterWakePhrase(
        'Sarah, what are my medicines today?',
      );
      expect(command, 'what are my medicines today');
      expect(
        VoiceIntentRouter.classify(command!),
        VoiceIntent.medicineScheduleRequested,
      );
    });

    test('ignores speech that does not begin with the wake phrase', () {
      expect(
        VoiceIntentRouter.commandAfterWakePhrase('I had my medicine'),
        isNull,
      );
    });
  });

  group('VoiceIntentRouter.commandForConversation', () {
    test('accepts follow-up speech after the wake phrase starts a chat', () {
      expect(
        VoiceIntentRouter.commandForConversation(
          'I had food',
          conversationActive: true,
        ),
        'i had food',
      );
    });

    test('requires the wake phrase before a conversation is active', () {
      expect(
        VoiceIntentRouter.commandForConversation(
          'I had food',
          conversationActive: false,
        ),
        isNull,
      );
    });
  });

  group('VoiceIntentRouter.classify', () {
    test('recognizes medicine, food, and water check-ins', () {
      expect(
        VoiceIntentRouter.classify('I had my medicine'),
        VoiceIntent.medicineTaken,
      );
      expect(
        VoiceIntentRouter.classify('I had food'),
        VoiceIntent.mealCompleted,
      );
      expect(
        VoiceIntentRouter.classify('I drank water'),
        VoiceIntent.waterCompleted,
      );
    });

    test('recognizes questions asking for the medicine schedule', () {
      expect(
        VoiceIntentRouter.classify('What are the medicines today?'),
        VoiceIntent.medicineScheduleRequested,
      );
      expect(
        VoiceIntentRouter.classify('What time should I take my tablets?'),
        VoiceIntent.medicineScheduleRequested,
      );
      expect(
        VoiceIntentRouter.classify('I took my medicine today'),
        VoiceIntent.medicineTaken,
      );
      expect(
        VoiceIntentRouter.classify('my medicines today'),
        VoiceIntent.medicineScheduleRequested,
      );
    });

    test('recognizes questions asking about appointments', () {
      expect(
        VoiceIntentRouter.classify('What appointments do I have today?'),
        VoiceIntent.appointmentScheduleRequested,
      );
      expect(
        VoiceIntentRouter.classify('When is my next doctor appointment?'),
        VoiceIntent.appointmentScheduleRequested,
      );
    });

    test('recognizes category completions and generic acknowledgements', () {
      expect(
        VoiceIntentRouter.classify('I completed my exercise'),
        VoiceIntent.exerciseCompleted,
      );
      expect(
        VoiceIntentRouter.classify('I completed my food'),
        VoiceIntent.mealCompleted,
      );
      expect(
        VoiceIntentRouter.classify('I had breakfast'),
        VoiceIntent.breakfastCompleted,
      );
      expect(
        VoiceIntentRouter.classify('Lunch is completed'),
        VoiceIntent.lunchCompleted,
      );
      expect(
        VoiceIntentRouter.classify('I finished dinner'),
        VoiceIntent.dinnerCompleted,
      );
      expect(
        VoiceIntentRouter.classify('I had my 12 PM medicine'),
        VoiceIntent.medicineTaken,
      );
      expect(
        VoiceIntentRouter.classify('Medicine completed'),
        VoiceIntent.medicineTaken,
      );
      expect(
        VoiceIntentRouter.classify('I had it'),
        VoiceIntent.reminderCompleted,
      );
      expect(VoiceIntentRouter.classify('done'), VoiceIntent.reminderCompleted);
      expect(
        VoiceIntentRouter.classify('completed'),
        VoiceIntent.reminderCompleted,
      );
    });

    test('recognizes a request to stop', () {
      expect(VoiceIntentRouter.classify('stop listening'), VoiceIntent.stop);
    });
  });

  group('VoiceIntentRouter.isEmergencyPhrase', () {
    test(
      'matches built-in and configured phrases without substring matches',
      () {
        expect(
          VoiceIntentRouter.isEmergencyPhrase('Please call for help'),
          isTrue,
        );
        expect(
          VoiceIntentRouter.isEmergencyPhrase(
            'I need assistance now',
            customPhrase: 'I need assistance',
          ),
          isTrue,
        );
        expect(
          VoiceIntentRouter.isEmergencyPhrase('I need helpful advice'),
          isFalse,
        );
      },
    );
  });
}
