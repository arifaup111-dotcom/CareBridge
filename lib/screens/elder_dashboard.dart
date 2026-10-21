import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/care_alarm_service.dart';
import '../services/appointment_schedule_formatter.dart';
import '../services/emergency_call_service.dart';
import '../services/english_voice_service.dart';
import '../services/gemini_conversation_service.dart';
import '../services/firestore_service.dart';
import '../services/medicine_completion_matcher.dart';
import '../services/medicine_schedule_formatter.dart';
import '../services/permission_service.dart';
import '../services/emergency_location_bridge.dart';
import '../services/voice_intent_router.dart';
import 'medicines_screen.dart';
import 'appointments_screen.dart';
import 'reminders_screen.dart';
import 'care_reminder_settings_screen.dart';
import 'Profile_screen.dart';

class ElderDashboard extends StatefulWidget {
  const ElderDashboard({super.key});

  @override
  State<ElderDashboard> createState() => _ElderDashboardState();
}

class _ElderDashboardState extends State<ElderDashboard>
    with WidgetsBindingObserver {
  // ================================================================
  // NAVIGATION
  // ================================================================

  int selectedIndex = 0;

  // ================================================================
  // VOICE ASSISTANT
  // ================================================================
  Widget _buildEmergencyCard({bool readOnly = false}) {
    return Container(
      key: _emergencyCardKey,
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ==========================================================
          // TITLE
          // ==========================================================
          const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Colors.red, size: 28),

              SizedBox(width: 10),

              Text(
                "Emergency Help",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF243B53),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            "Get immediate help when you need it.",
            style: TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
          ),

          const SizedBox(height: 18),

          // ==========================================================
          // EMERGENCY CONTACT
          // ==========================================================
          if (!readOnly)
            GestureDetector(
              behavior: HitTestBehavior.opaque,

              onTap: () {
                _showEmergencyContactDialog();
              },

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Colors.red,
                      size: 25,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            "Emergency Contact",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF243B53),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            _emergencyContactPhone.isEmpty
                                ? "Tap here to add the number called during SOS"
                                : "$_emergencyContactName  •  $_emergencyContactPhone",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF718096),
                    ),
                  ],
                ),
              ),
            ),

          if (!readOnly) const SizedBox(height: 12),

          if (!readOnly)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showEmergencyPhraseDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: Colors.red,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency voice phrase',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF243B53),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Say "$_emergencyPhrase" while voice listening is on',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_rounded, color: Color(0xFF718096)),
                  ],
                ),
              ),
            ),

          if (!readOnly) const SizedBox(height: 12),

          // ==========================================================
          // EMERGENCY LOCATION
          // ==========================================================
          if (!readOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF28A76B),
                    size: 25,
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Emergency Location",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF243B53),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Share your current location with your family during an emergency.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location sharing ON/OFF switch.
                  Switch(
                    value: _locationSharingEnabled,

                    onChanged: (value) async {
                      setState(() => _locationSharingEnabled = value);
                      final elderId = _elderId ?? await _db.resolveElderId();
                      if (elderId != null) {
                        _elderId = elderId;
                        await _db.firestore
                            .collection('elders')
                            .doc(elderId)
                            .collection('settings')
                            .doc('emergency')
                            .set({
                              'locationSharingEnabled': value,
                            }, SetOptions(merge: true));
                      }
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ==========================================================
          // SOS BUTTON
          // ==========================================================
          SizedBox(
            width: double.infinity,
            height: 54,

            child: ElevatedButton.icon(
              onPressed: _showEmergencyDialog,

              icon: const Icon(Icons.call_rounded, size: 23),

              label: const Text(
                "EMERGENCY SOS",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              "Press SOS to contact your registered emergency contact.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMERGENCY CONTACT DIALOG
  // ================================================================

  void _showEmergencyContactDialog() {
    // Controller for the emergency contact name.
    final TextEditingController nameController = TextEditingController(
      text: _emergencyContactName,
    );

    // Controller for the emergency contact phone number.
    final TextEditingController phoneController = TextEditingController(
      text: _emergencyContactPhone,
    );

    showDialog(
      context: context,

      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: const Text(
            "Emergency Contact",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Contact name.
                TextField(
                  controller: nameController,

                  decoration: InputDecoration(
                    labelText: "Contact Name",
                    hintText: "Example: Daughter",

                    prefixIcon: const Icon(Icons.person_rounded),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Contact phone number.
                TextField(
                  controller: phoneController,

                  keyboardType: TextInputType.phone,

                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    hintText: "+91 XXXXX XXXXX",

                    prefixIcon: const Icon(Icons.phone_rounded),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            // Cancel.
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
              },

              child: const Text("Cancel"),
            ),

            // Save.
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text.trim();

                final String phone = phoneController.text.trim();

                // Check that both fields are filled.
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter both name and phone number."),
                    ),
                  );

                  return;
                }

                setState(() {
                  _emergencyContactName = name;
                  _emergencyContactPhone = phone;
                });

                Navigator.pop(dialogCtx);

                final elderId = _elderId ?? await _db.resolveElderId();
                if (elderId != null) {
                  _elderId = elderId;
                  await _db.saveEmergencyContact(
                    elderId: elderId,
                    contactName: name,
                    contactNumber: phone,
                  );
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Emergency contact saved.")),
                );
              },

              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // YOUR EXISTING CODE STARTS HERE

  final FirestoreService _db = FirestoreService();
  final EnglishVoiceService _voice = EnglishVoiceService();
  final GeminiConversationService _conversation = GeminiConversationService();

  String _emergencyContactName = "";
  String _emergencyContactPhone = "";
  String _emergencyPhrase = VoiceIntentRouter.defaultEmergencyPhrase;
  bool _locationSharingEnabled = true;
  bool _voiceEnabled = false;
  bool _voiceInitialized = false;
  bool _voiceStarting = false;
  bool _voiceProcessing = false;
  bool _awaitingWakeCommand = false;
  bool _awaitingMedicineName = false;
  bool _voiceSuspended = false;
  bool _voiceSpeaking = false;
  String _voiceStatus = 'Voice assistant is off.';
  String _recognizedSpeech = '';
  Timer? _voiceRestartTimer;
  String? _elderId;
  String? _lastCareAlarmSignature;
  String? _publicElderId;
  String? _publicElderIdError;
  bool _loadingPublicElderId = true;

  bool _emergencyCallWasLaunched = false;
  bool _liveLocationFailureShown = false;
  String? _activeEmergencyId;
  String? _activeEmergencyElderId;
  DateTime? _lastEmergencyCallTime;
  final GlobalKey _emergencyCardKey = GlobalKey();
  static const MethodChannel _reminderChannel = MethodChannel(
    'carebridge/reminder_announcements',
  );
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _careReminderSubscription;

  // ================================================================
  // INITIALIZATION
  // ================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EmergencyLocationBridge.initialize(
      onLocation: (elderId, emergencyId, latitude, longitude) {
        unawaited(
          _saveEmergencyLocationUpdate(
            elderId,
            emergencyId,
            latitude,
            longitude,
          ),
        );
      },
      onError: _showLiveLocationError,
    );
    _loadEmergencyData();
    unawaited(_loadVoicePreference());
    _loadPublicElderId();
    _listenForCareReminders();
  }

  Future<void> _loadVoicePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool('voice_assistant_enabled') ?? false;
    if (!mounted || !enabled) return;
    setState(() => _voiceEnabled = true);
    await _startVoiceInteraction();
  }

  Future<void> _setVoiceEnabled(bool enabled) async {
    if (_voiceEnabled == enabled) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('voice_assistant_enabled', enabled);
    if (!mounted) return;
    setState(() {
      _voiceEnabled = enabled;
      _voiceSuspended = false;
      _awaitingWakeCommand = false;
      _awaitingMedicineName = false;
      _voiceStatus = enabled
          ? 'Starting English voice assistant...'
          : 'Voice assistant is off.';
    });
    _voiceRestartTimer?.cancel();
    if (enabled) {
      await _startVoiceInteraction();
    } else {
      await _voice.stopListening();
      await _voice.stopSpeaking();
      _conversation.clearHistory();
    }
  }

  Future<void> _startVoiceInteraction() async {
    if (!mounted ||
        !_voiceEnabled ||
        _voiceSuspended ||
        _voiceStarting ||
        _voiceProcessing ||
        _voiceSpeaking ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive ||
        _voice.isListening) {
      return;
    }

    _voiceStarting = true;
    try {
      if (!_voiceInitialized && !await PermissionService.requestMicrophone()) {
        if (!mounted) return;
        setState(() {
          _voiceEnabled = false;
          _voiceStatus = 'Allow microphone access to use voice interaction.';
        });
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool('voice_assistant_enabled', false);
        return;
      }

      if (!_voiceInitialized) {
        final initialized = await _voice.initialize(
          onResult: _handleVoiceResult,
          onStatus: _handleVoiceStatus,
          onError: _handleVoiceError,
        );
        if (!initialized) {
          throw StateError('English speech recognition is unavailable.');
        }
        _voiceInitialized = true;
      }

      await _voice.listen(onResult: _handleVoiceResult);
      if (mounted && _voiceEnabled && !_voiceSuspended) {
        setState(() => _voiceStatus = 'Listening for “Sara”.');
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Could not start English voice interaction: $error\n$stackTrace',
      );
      if (mounted) {
        setState(
          () => _voiceStatus = 'Voice listening could not start: $error',
        );
      }
    } finally {
      _voiceStarting = false;
    }
  }

  void _handleVoiceStatus(String status) {
    if (!mounted) return;
    if (status == 'listening') {
      setState(() {
        _voiceStatus = _awaitingMedicineName
            ? 'Listening for the medicine name.'
            : _awaitingWakeCommand
            ? 'Listening for your care update.'
            : 'Listening for “Sara”.';
      });
    } else if ((status == 'notListening' || status == 'done') &&
        !_voiceProcessing &&
        !_voiceSpeaking) {
      _scheduleVoiceRestart();
    }
  }

  void _handleVoiceError(String message, bool isPermanent) {
    if (!mounted || !_voiceEnabled) return;
    setState(() => _voiceStatus = 'Speech recognition: $message');
    if (isPermanent) {
      _showVoiceMessage(
        'Voice listening stopped. Check microphone permission and speech recognition settings.',
      );
      return;
    }
    if (!_voiceProcessing && !_voiceSpeaking) _scheduleVoiceRestart();
  }

  void _scheduleVoiceRestart() {
    _voiceRestartTimer?.cancel();
    _voiceRestartTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(_startVoiceInteraction());
    });
  }

  void _handleVoiceResult(String text, bool isFinal) {
    if (!mounted || text.trim().isEmpty) return;
    setState(() => _recognizedSpeech = text.trim());
    if (isFinal) unawaited(_processVoiceCommand(text.trim()));
  }

  Future<void> _processVoiceCommand(String text) async {
    if (_voiceProcessing || !_voiceEnabled) return;
    _voiceProcessing = true;
    _voiceRestartTimer?.cancel();
    try {
      if (_voice.isAndroid) {
        await _voice.pauseListening();
      } else {
        await _voice.stopListening();
      }

      if (VoiceIntentRouter.isEmergencyPhrase(
        text,
        customPhrase: _emergencyPhrase,
      )) {
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          return;
        }
        await _voice.stopListening();
        _awaitingWakeCommand = false;
        _awaitingMedicineName = false;
        _voiceSuspended = true;
        await _handleEmergencyIntent(text);
        if (!_emergencyCallWasLaunched) _voiceSuspended = false;
        return;
      }

      if (_awaitingMedicineName) {
        await _markMedicineTaken(text);
        return;
      }

      final command = VoiceIntentRouter.commandForConversation(
        text,
        conversationActive: _awaitingWakeCommand,
      );
      if (command == null) return;
      _awaitingWakeCommand = true;
      if (command.isEmpty) {
        await _speakDirectVoiceReply(
          "Hello, I'm listening. You can ask me about today's medicines, "
          "today's appointments, or tell me when you have eaten or had water.",
        );
        return;
      }

      switch (VoiceIntentRouter.classify(command)) {
        case VoiceIntent.medicineScheduleRequested:
          await _speakTodaysMedicineSchedule();
        case VoiceIntent.appointmentScheduleRequested:
          await _speakTodaysAppointmentSchedule();
        case VoiceIntent.breakfastCompleted:
          await _markCareCategoryCompleted(category: 'breakfast');
        case VoiceIntent.lunchCompleted:
          await _markCareCategoryCompleted(category: 'lunch');
        case VoiceIntent.dinnerCompleted:
          await _markCareCategoryCompleted(category: 'dinner');
        case VoiceIntent.medicineTaken:
          await _markMedicineTaken(command);
        case VoiceIntent.mealCompleted:
          await _markCareCategoryCompleted(category: 'meal');
        case VoiceIntent.waterCompleted:
          await _markCareCategoryCompleted(category: 'water');
        case VoiceIntent.exerciseCompleted:
          await _markCareCategoryCompleted(category: 'exercise');
        case VoiceIntent.reminderCompleted:
          await _completeMostRecentReminder();
        case VoiceIntent.stop:
          _awaitingWakeCommand = false;
          await _speakVoiceResponse(
            'The elder asked to end the conversation. Confirm briefly that listening remains enabled and they can say Sara to start again.',
          );
        case VoiceIntent.emergency:
        case VoiceIntent.unknown:
          await _speakVoiceResponse(
            'No care update was saved. Respond naturally to what the elder said and ask one short clarifying question if needed. Do not claim an update was saved.',
          );
      }
    } catch (error, stackTrace) {
      debugPrint('Voice command processing failed: $error\n$stackTrace');
      if (mounted) {
        await _speakDirectVoiceReply(
          'I could not save that update. Please try again.',
        );
      }
    } finally {
      _voiceProcessing = false;
      if (_voiceEnabled && !_voiceSuspended && mounted) {
        if (_voice.isAndroid) {
          unawaited(_startVoiceInteraction());
        } else {
          _scheduleVoiceRestart();
        }
      }
    }
  }

  Future<void> _markCareCategoryCompleted({required String category}) async {
    final elderId = _elderId ?? await _db.resolveElderId();
    if (elderId == null) {
      throw StateError('Could not find the signed-in Elder account.');
    }
    _elderId = elderId;
    await _db.markCareReminderCompleted(elderId: elderId, category: category);
    await _clearRecentReminderForType(
      category == 'breakfast' || category == 'lunch' || category == 'dinner'
          ? 'meal'
          : category,
    );
    await _speakDirectVoiceReply(
      'Thank you. I marked your $category as completed and updated your family dashboard.',
    );
  }

  Future<void> _markMedicineTaken(String spokenText) async {
    final elderId = _elderId ?? await _db.resolveElderId();
    if (elderId == null) {
      throw StateError('Could not find the signed-in Elder account.');
    }
    _elderId = elderId;
    final medicines = await _db.getMedicinesOnce(elderId);
    final recentReminder = await _getRecentReminder();
    final namedMedicines = MedicineCompletionMatcher.findBySpokenName(
      medicines: medicines,
      spokenText: spokenText,
    );
    final timeMatchedMedicines = namedMedicines.isEmpty
        ? MedicineCompletionMatcher.findBySpokenTime(
            medicines: medicines,
            spokenText: spokenText,
          )
        : const <Map<String, dynamic>>[];
    Map<String, dynamic>? medicineFromReminder;
    if (namedMedicines.isEmpty &&
        timeMatchedMedicines.isEmpty &&
        recentReminder?['type'] == 'medicine') {
      for (final item in medicines) {
        if (item['id']?.toString() == recentReminder?['key']?.toString()) {
          medicineFromReminder = item;
          break;
        }
      }
    }

    Map<String, dynamic>? medicine;
    if (namedMedicines.length == 1) {
      medicine = namedMedicines.first;
    } else if (namedMedicines.length > 1) {
      medicine = null;
    } else if (timeMatchedMedicines.length == 1) {
      medicine = timeMatchedMedicines.single;
    } else if (timeMatchedMedicines.length > 1) {
      medicine = null;
    } else if (medicineFromReminder != null) {
      medicine = medicineFromReminder;
    } else {
      final notTaken = medicines
          .where((item) => !FirestoreService.isMedicineTakenToday(item))
          .toList();
      if (notTaken.length == 1) medicine = notTaken.first;
      if (notTaken.length > 1) {
        _awaitingMedicineName = true;
        await _speakDirectVoiceReply(
          'I have more than one medicine scheduled. Please tell me its name or scheduled time.',
        );
        return;
      }
    }

    if (medicine == null || medicine['id'] == null) {
      final needsClarification =
          namedMedicines.length > 1 ||
          timeMatchedMedicines.length > 1 ||
          (namedMedicines.isEmpty &&
              timeMatchedMedicines.isEmpty &&
              medicines.isNotEmpty);
      _awaitingMedicineName = needsClarification;
      await _speakDirectVoiceReply(
        medicines.isEmpty
            ? 'There are no medicines in your care plan. Please ask your family to add them if needed.'
            : needsClarification
            ? 'I found more than one possible medicine. Please say its name or the scheduled time, such as 12 PM.'
            : 'I could not match that medicine to your care plan. Nothing was marked. Please say its name or scheduled time again.',
      );
      return;
    }

    _awaitingMedicineName = false;
    final medicineName = (medicine['name'] ?? 'Medicine').toString();
    await _db.markMedicineTaken(
      elderId: elderId,
      medicineId: medicine['id'].toString(),
      taken: true,
    );
    await _clearRecentReminderForType('medicine');
    await _speakDirectVoiceReply(
      'Thank you. I marked $medicineName as taken and updated your family dashboard.',
    );
  }

  Future<Map<Object?, Object?>?> _getRecentReminder() async {
    if (!_voice.isAndroid || kIsWeb) return null;
    final reminder = await _reminderChannel.invokeMapMethod<Object?, Object?>(
      'getRecentReminder',
    );
    return reminder;
  }

  Future<void> _clearRecentReminderForType(String type) async {
    final reminder = await _getRecentReminder();
    if (reminder?['type'] != type || reminder?['id'] is! int) return;
    final cleared = await _reminderChannel.invokeMethod<bool>(
      'clearRecentReminder',
      {'id': reminder!['id']},
    );
    if (cleared != true) {
      debugPrint('The completed reminder context could not be cleared.');
    }
  }

  Future<void> _completeMostRecentReminder() async {
    final reminder = await _getRecentReminder();
    if (reminder == null) {
      await _speakDirectVoiceReply(
        'I heard you. Please tell me what you completed: food, water, exercise, or medicine.',
      );
      return;
    }

    final type = reminder['type']?.toString();
    if (type == 'meal' || type == 'water' || type == 'exercise') {
      await _markCareCategoryCompleted(category: type!);
      return;
    }
    if (type == 'medicine') {
      final elderId = _elderId ?? await _db.resolveElderId();
      if (elderId == null) {
        throw StateError('Could not find the signed-in Elder account.');
      }
      final medicineId = reminder['key']?.toString();
      final medicines = await _db.getMedicinesOnce(elderId);
      Map<String, dynamic>? medicine;
      for (final item in medicines) {
        if (item['id']?.toString() == medicineId) {
          medicine = item;
          break;
        }
      }
      if (medicine == null || medicine['id'] == null) {
        await _speakDirectVoiceReply(
          'I could not find that medicine in your care plan. Please ask your family to check it.',
        );
        return;
      }
      _elderId = elderId;
      final name = (medicine['name'] ?? 'medicine').toString();
      await _db.markMedicineTaken(
        elderId: elderId,
        medicineId: medicine['id'].toString(),
        taken: true,
      );
      await _clearRecentReminderForType('medicine');
      await _speakDirectVoiceReply(
        'Thank you. I marked $name as taken and updated your family dashboard.',
      );
      return;
    }

    await _speakDirectVoiceReply(
      'I heard you. Please tell me whether you completed food, water, exercise, or medicine.',
    );
  }

  Future<void> _speakTodaysMedicineSchedule() async {
    final elderId = _elderId ?? await _db.resolveElderId();
    if (elderId == null) {
      throw StateError('Could not find the signed-in Elder account.');
    }
    _elderId = elderId;
    final medicines = await _db.getMedicinesOnce(elderId);
    await _speakDirectVoiceReply(
      MedicineScheduleFormatter.formatDailySchedule(medicines),
    );
  }

  Future<void> _speakTodaysAppointmentSchedule() async {
    final elderId = _elderId ?? await _db.resolveElderId();
    if (elderId == null) {
      throw StateError('Could not find the signed-in Elder account.');
    }
    _elderId = elderId;
    final appointments = await _db.getAppointmentsOnce(elderId);
    await _speakDirectVoiceReply(
      AppointmentScheduleFormatter.formatTodaysAppointments(appointments),
    );
  }

  Future<void> _speakDirectVoiceReply(String reply) async {
    if (!mounted || !_voiceEnabled) return;
    setState(() {
      _voiceSpeaking = true;
      _voiceStatus = reply;
    });
    try {
      await _voice.speak(reply);
    } catch (error, stackTrace) {
      debugPrint('Could not speak the care schedule: $error\n$stackTrace');
      _showVoiceMessage('Could not play the spoken response: $error');
    } finally {
      _voiceSpeaking = false;
    }
  }

  Future<void> _speakVoiceResponse(String response) async {
    if (!mounted || !_voiceEnabled) return;
    setState(() {
      _voiceSpeaking = true;
      _voiceStatus = 'Preparing a reply...';
    });
    try {
      final reply = await _conversation.reply(
        userMessage: _recognizedSpeech,
        outcome: response,
      );
      if (mounted) setState(() => _voiceStatus = reply);
      await _voice.speak(reply);
    } catch (error, stackTrace) {
      debugPrint('Could not speak voice response: $error\n$stackTrace');
      _showVoiceMessage('Could not play the spoken response: $error');
      try {
        await _voice.speak(
          'I am having trouble connecting to my voice assistant right now. Please try again in a moment.',
        );
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint(
          'Could not speak voice service error: '
          '$fallbackError\n$fallbackStackTrace',
        );
      }
    } finally {
      _voiceSpeaking = false;
    }
  }

  void _showVoiceMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildVoiceInteractionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F8EF7), Color(0xFF6FA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'English voice assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _voiceEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.lightBlueAccent,
                onChanged: _setVoiceEnabled,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _voiceEnabled
                ? _voiceStatus
                : 'Turn on, then say “Sara” and your request. '
                      'Listening works only while this screen is open.',
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
          if (_recognizedSpeech.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Heard: “$_recognizedSpeech”',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
          if (_voiceEnabled) ...[
            const SizedBox(height: 8),
            const Text(
              'Try: “Sara, what medicines do I have today?”, '
              '“Sara, what appointments do I have today?”, “Sara, I had food”, '
              'or “Sara, I drank water”. After a reminder, you can say '
              '“done” or “I had it”. Emergency phrases work without the wake '
              'phrase while listening is on.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEmergencyPhraseDialog() async {
    final controller = TextEditingController(text: _emergencyPhrase);
    final phrase = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emergency voice phrase'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'For example: emergency help',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (phrase == null) return;
    if (phrase.isEmpty) {
      _showVoiceMessage('Enter an emergency phrase before saving.');
      return;
    }

    try {
      final elderId = _elderId ?? await _db.resolveElderId();
      if (elderId == null) {
        throw StateError('Could not find the signed-in Elder account.');
      }
      await _db.saveEmergencyPhrase(elderId: elderId, phrase: phrase);
      if (!mounted) return;
      setState(() => _emergencyPhrase = phrase);
      _showVoiceMessage('Emergency phrase saved.');
    } catch (error, stackTrace) {
      debugPrint('Could not save emergency phrase: $error\n$stackTrace');
      _showVoiceMessage('Could not save the emergency phrase: $error');
    }
  }

  Future<void> _loadPublicElderId() async {
    try {
      final elderId = await _db.getOrCreateElderPublicId();
      if (!mounted) return;
      setState(() {
        _publicElderId = elderId;
        _publicElderIdError = elderId == null
            ? 'Could not find the Elder account for this login.'
            : null;
        _loadingPublicElderId = false;
      });
    } catch (error) {
      debugPrint('ElderDashboard: public Elder ID load failed -> $error');
      if (!mounted) return;
      setState(() {
        _publicElderIdError =
            'Could not load your Elder ID. Check connection and retry.';
        _loadingPublicElderId = false;
      });
    }
  }

  Future<void> _copyPublicElderId() async {
    final elderId = _publicElderId;
    if (elderId == null) return;
    await Clipboard.setData(ClipboardData(text: elderId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Elder ID copied to clipboard.')),
    );
  }

  Future<void> _listenForCareReminders() async {
    try {
      final elderId = await _db.resolveElderId();
      if (elderId == null || !mounted) return;
      _careReminderSubscription = _db
          .streamCareReminderSettings(elderId)
          .listen(
            (snapshot) {
              final settings = snapshot.data() ?? {};
              final meals = (settings['mealTimes'] as List? ?? const [])
                  .map((time) => time.toString())
                  .toList();
              final water = (settings['waterTimes'] as List? ?? const [])
                  .map((time) => time.toString())
                  .toList();
              unawaited(
                _syncCareAlarms(
                  meals,
                  water,
                  wakeUpTime: settings['wakeUpTime']?.toString(),
                  exerciseTime: settings['exerciseTime']?.toString(),
                ),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Care alarm settings stream failed: $error');
            },
          );
    } catch (error) {
      debugPrint('Could not start care alarm settings stream: $error');
    }
  }

  Future<void> _syncCareAlarms(
    List<String> mealTimes,
    List<String> waterTimes, {
    String? wakeUpTime,
    String? exerciseTime,
  }) async {
    try {
      final id = _elderId ?? await _db.resolveElderId();
      if (id == null) {
        throw StateError('Could not find the signed-in Elder account.');
      }
      final medicines = await _db.getMedicinesOnce(id);
      final appointments = await _db.getAppointmentsOnce(id);
      final signature = jsonEncode({
        'mealTimes': mealTimes,
        'waterTimes': waterTimes,
        'wakeUpTime': wakeUpTime,
        'exerciseTime': exerciseTime,
        'medicines': medicines
            .map(
              (medicine) => [
                medicine['id'],
                medicine['name'],
                medicine['time'],
                medicine['dosage'],
                medicine['instruction'],
              ],
            )
            .toList(),
        'appointments': appointments
            .map(
              (appointment) => [
                appointment['id'],
                appointment['doctor'],
                appointment['specialization'],
                appointment['hospital'],
                appointment['date'],
                appointment['time'],
                appointment['status'],
                appointment['cancelled'],
                appointment['canceled'],
                appointment['isCancelled'],
                appointment['deleted'],
              ],
            )
            .toList(),
      });
      if (_lastCareAlarmSignature == signature) return;
      _lastCareAlarmSignature = signature;

      final notificationsAllowed =
          await PermissionService.requestNotifications();
      final exactAlarmsAllowed = await CareAlarmService.instance
          .requestExactAlarmPermission();
      await CareAlarmService.instance.scheduleAllReminders(
        mealTimes: mealTimes,
        waterTimes: waterTimes,
        wakeUpTime: wakeUpTime,
        exerciseTime: exerciseTime,
        medicines: medicines,
        appointments: appointments,
      );
      if (!notificationsAllowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are disabled. Turn them on in settings to see care reminders.',
            ),
          ),
        );
      } else if (!exactAlarmsAllowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Exact alarm access is off. Android may deliver care reminders later than scheduled.',
            ),
          ),
        );
      }
    } catch (error) {
      _lastCareAlarmSignature = null;
      debugPrint('Could not schedule care alarms: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not schedule care reminders.')),
        );
      }
    }
  }

  Future<void> _loadEmergencyData() async {
    try {
      final id = await _db.resolveElderId();
      if (id == null) return;
      final data = await _db.getEmergencySettings(id);
      if (!mounted) return;
      setState(() {
        _elderId = id;
        _emergencyContactName = (data?['contactName'] ?? '').toString().trim();
        _emergencyContactPhone = (data?['contactNumber'] ?? '')
            .toString()
            .trim();
        _emergencyPhrase =
            (data?['emergencyPhrase'] ??
                    VoiceIntentRouter.defaultEmergencyPhrase)
                .toString()
                .trim();
        _locationSharingEnabled = data?['locationSharingEnabled'] != false;
      });
    } catch (e) {
      debugPrint('ElderDashboard: emergency data load failed -> $e');
    }
  }

  Future<void> _handleEmergencyIntent(String triggerPhrase) async {
    // Debounce calls within 15 seconds to prevent accidental duplicate dialing
    if (_lastEmergencyCallTime != null &&
        DateTime.now().difference(_lastEmergencyCallTime!).inSeconds < 15) {
      _showEmergencyMessage(
        'അടിയന്തര കോൾ ഇതിനകം ആരംഭിച്ചിട്ടുണ്ട്. ദയവായി അല്പം കാത്തിരിക്കൂ.',
      );
      return;
    }
    _lastEmergencyCallTime = DateTime.now();

    if (_elderId == null) await _loadEmergencyData();
    final phone = _emergencyContactPhone.trim();

    var locationPermissionGranted = false;
    Position? emergencyPosition;
    if (_locationSharingEnabled) {
      try {
        locationPermissionGranted = await PermissionService.requestLocation();
        if (locationPermissionGranted) {
          emergencyPosition = await Geolocator.getLastKnownPosition();
          emergencyPosition ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('Could not get the initial emergency location: $e');
      }
    }

    var eventRecorded = false;
    String? emergencyId;
    final elderId = _elderId ?? await _db.resolveElderId();
    if (elderId != null) {
      try {
        emergencyId = await _db.recordEmergency(
          elderId: elderId,
          triggerPhrase: triggerPhrase,
          latitude: emergencyPosition?.latitude,
          longitude: emergencyPosition?.longitude,
        );
        eventRecorded = true;
      } catch (e) {
        debugPrint('Emergency record failed: $e');
        _showLiveLocationError(
          'Could not save the emergency location to your CareBridge family.',
        );
      }
    }

    if (phone.isEmpty) {
      _showEmergencyMessage(
        eventRecorded
            ? 'അടിയന്തര സംഭവം രേഖപ്പെടുത്തി. അടിയന്തര കോൺടാക്ട് നമ്പർ സജ്ജീകരിച്ചിട്ടില്ല; SOS സഹായം ലഭ്യമാക്കാൻ Emergency Settings തുറന്ന് നമ്പർ ചേർക്കുക.'
            : 'അടിയന്തര കോൺടാക്ട് നമ്പർ സജ്ജീകരിച്ചിട്ടില്ല, സംഭവവും രേഖപ്പെടുത്താനായില്ല. സഹായത്തിനായി സമീപത്തുള്ള ഒരാളോട് പറയുക.',
      );
      return;
    }

    var emergencySmsSent = false;
    var emergencySmsStatus = 'No GPS fix; emergency location SMS was not sent.';
    if (emergencyPosition != null) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          await PermissionService.requestSms()) {
        emergencySmsSent = await EmergencyCallService.sendEmergencyLocationSms(
          phoneNumber: phone,
          latitude: emergencyPosition.latitude,
          longitude: emergencyPosition.longitude,
        );
        emergencySmsStatus = emergencySmsSent
            ? 'Emergency location SMS queued to the Help contact.'
            : 'Emergency location SMS could not be sent. Check SIM/service.';
      } else {
        emergencySmsStatus =
            'SMS permission was denied; emergency location SMS was not sent.';
      }
    }

    _showEmergencyMessage(
      _emergencyContactName.isEmpty
          ? 'അടിയന്തര സഹായത്തിനായി കോൾ ആരംഭിക്കുന്നു.'
          : '$_emergencyContactName നെ വിളിക്കുന്നു.',
    );

    if (!await PermissionService.requestPhone()) {
      _showEmergencyMessage(
        eventRecorded
            ? 'അടിയന്തര സംഭവം രേഖപ്പെടുത്തി, പക്ഷേ ഫോൺ കോളിന് അനുമതി ലഭിച്ചില്ല. Phone permission അനുവദിക്കുക.'
            : 'അടിയന്തര സംഭവം രേഖപ്പെടുത്താനായില്ല, ഫോൺ കോളിനും അനുമതി ലഭിച്ചില്ല. സമീപത്തുള്ള ഒരാളോട് സഹായം ചോദിക്കുക.',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emergencySmsStatus)));
      }
      return;
    }

    var liveLocationStarted = false;
    if (_locationSharingEnabled &&
        locationPermissionGranted &&
        eventRecorded &&
        emergencyId != null &&
        defaultTargetPlatform == TargetPlatform.android) {
      liveLocationStarted = await EmergencyLocationBridge.start(
        elderId: elderId!,
        emergencyId: emergencyId,
      );
      if (liveLocationStarted) {
        _activeEmergencyElderId = elderId;
        _activeEmergencyId = emergencyId;
        _liveLocationFailureShown = false;
      } else {
        _showLiveLocationError(
          'Could not start live location sharing. Your emergency call will still continue.',
        );
      }
    }

    _emergencyCallWasLaunched = true;
    final called = await EmergencyCallService.call(phone);
    if (called) {
      _showEmergencyMessage(
        eventRecorded
            ? '${_emergencyContactName.isEmpty ? 'അടിയന്തര കോൾ ആരംഭിച്ചു.' : '$_emergencyContactName നെ വിളിക്കാൻ കോൾ ആരംഭിച്ചു.'} '
                  '${liveLocationStarted ? 'കുടുംബത്തിനായി തത്സമയ ലൊക്കേഷൻ പങ്കിടൽ ആരംഭിക്കുന്നു.' : 'തത്സമയ ലൊക്കേഷൻ ലഭ്യമല്ല.'} '
                  '$emergencySmsStatus'
            : 'കോൾ ആരംഭിച്ചു, പക്ഷേ അടിയന്തര സംഭവം രേഖപ്പെടുത്താനായില്ല.',
      );
    } else {
      _emergencyCallWasLaunched = false;
      if (liveLocationStarted) await _stopLiveEmergencyLocation();
      _showEmergencyMessage(
        eventRecorded
            ? 'അടിയന്തര സംഭവം രേഖപ്പെടുത്തി, പക്ഷേ കോൾ ആരംഭിക്കാൻ കഴിഞ്ഞില്ല. സമീപത്തുള്ള ഒരാളോട് സഹായം ചോദിക്കുക.'
            : 'അടിയന്തര സംഭവം രേഖപ്പെടുത്താനോ കോൾ ആരംഭിക്കാനോ കഴിഞ്ഞില്ല. സമീപത്തുള്ള ഒരാളോട് സഹായം ചോദിക്കുക.',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emergencySmsStatus)));
      }
    }
  }

  void _showEmergencyMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveEmergencyLocationUpdate(
    String elderId,
    String emergencyId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _db.updateEmergencyLocation(
        elderId: elderId,
        emergencyId: emergencyId,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (error, stackTrace) {
      debugPrint('Live emergency location update failed: $error\n$stackTrace');
      _showLiveLocationError(
        'A live location update could not be shared with your family.',
      );
    }
  }

  void _showLiveLocationError(String message) {
    debugPrint('Emergency live location: $message');
    if (_liveLocationFailureShown) return;
    _liveLocationFailureShown = true;
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (_activeEmergencyId != null) {
      unawaited(_stopLiveEmergencyLocation());
    }
  }

  Future<void> _stopLiveEmergencyLocation() async {
    final elderId = _activeEmergencyElderId;
    final emergencyId = _activeEmergencyId;
    _activeEmergencyId = null;
    _activeEmergencyElderId = null;
    _emergencyCallWasLaunched = false;
    final stopped = await EmergencyLocationBridge.stop();
    if (!stopped) {
      _showLiveLocationError('Could not stop the emergency location service.');
    }
    if (elderId == null || emergencyId == null) return;
    try {
      await _db.stopEmergencyLocationTracking(
        elderId: elderId,
        emergencyId: emergencyId,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Could not mark emergency location sharing as ended: '
        '$error\n$stackTrace',
      );
      _showLiveLocationError(
        'Could not update the location-sharing status for your family.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_emergencyCallWasLaunched) {
        _emergencyCallWasLaunched = false;
        if (_activeEmergencyId != null) {
          unawaited(_stopLiveEmergencyLocation());
        }
      }
      _voiceSuspended = false;
      if (_voiceEnabled) _scheduleVoiceRestart();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _voiceSuspended = true;
      _awaitingWakeCommand = false;
      _awaitingMedicineName = false;
      _voiceRestartTimer?.cancel();
      if (!_voice.isAndroid) unawaited(_voice.stopListening());
      unawaited(_voice.stopSpeaking());
    }
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _careReminderSubscription?.cancel();
    _voiceRestartTimer?.cancel();
    unawaited(_voice.dispose());
    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning 👋",
              style: TextStyle(fontSize: 15, color: Color(0xFF718096)),
            ),

            SizedBox(height: 3),

            Text(
              "Welcome to CareBridge",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildPublicElderIdCard(),
              const SizedBox(height: 18),
              _buildVoiceInteractionCard(),
              const SizedBox(height: 18),
              // ======================================================
              // QUICK ACTIONS
              // ======================================================
              const Text(
                "Quick Actions",

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.medication_rounded,
                      title: "Medicines",
                      subtitle: "My medicines",

                      color: const Color(0xFFEAF4FF),

                      iconColor: const Color(0xFF4F8EF7),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MedicinesScreen(readOnly: true),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.calendar_month_rounded,
                      title: "Appointments",
                      subtitle: "My appointments",

                      color: const Color(0xFFEAFBF3),

                      iconColor: const Color(0xFF28A76B),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AppointmentsScreen(readOnly: true),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.notifications_active_rounded,
                      title: "Meal and Water Alarms",
                      subtitle: "Daily care reminders",

                      color: const Color(0xFFF3ECFF),

                      iconColor: const Color(0xFF8A5CF6),

                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          final elderId =
                              _elderId ?? await _db.resolveElderId();
                          if (elderId == null) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not load your reminder settings.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!mounted) return;
                          await navigator.push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CareReminderSettingsScreen(elderId: elderId),
                            ),
                          );
                        } catch (error) {
                          debugPrint(
                            'Could not open care reminder settings: $error',
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open your reminder settings.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ======================================================
              const SizedBox(height: 20),

              // ======================================================
              // EMERGENCY HELP
              // ======================================================
              _buildEmergencyCard(readOnly: false),
            ],
          ),
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        onTap: (index) async {
          if (index == 4) {
            setState(() => selectedIndex = 4);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final target = _emergencyCardKey.currentContext;
              if (target != null) {
                Scrollable.ensureVisible(
                  target,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              }
            });
            return;
          }

          // HOME
          if (index == 0) {
            setState(() {
              selectedIndex = 0;
            });
            return;
          }

          final Widget? page = switch (index) {
            1 => const MedicinesScreen(readOnly: true),
            2 => const AppointmentsScreen(readOnly: true),
            3 => const RemindersScreen(),
            5 => const ProfileScreen(),
            _ => null,
          };
          if (page == null) return;
          final navigator = Navigator.of(context);
          if (!mounted) return;
          await navigator.push(MaterialPageRoute(builder: (context) => page));
          if (mounted) {
            setState(() => selectedIndex = 0);
          }
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF4F8EF7),

        unselectedItemColor: Colors.grey,

        backgroundColor: Colors.white,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.medication_rounded),
            label: "Medicines",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: "Appointments",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active_rounded),
            label: "Reminders",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.emergency_rounded),
            label: "Help",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildPublicElderIdCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E6FA)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAF1FF),
            child: Icon(Icons.link_rounded, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Elder ID',
                  style: TextStyle(
                    color: Color(0xFF203864),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                if (_loadingPublicElderId)
                  const Text('Loading your ID...')
                else if (_publicElderId != null)
                  SelectableText(
                    _publicElderId!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  Text(
                    _publicElderIdError ?? 'Elder ID unavailable.',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                const SizedBox(height: 3),
                const Text(
                  'Share this ID with Family to connect.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_publicElderId != null)
            IconButton(
              tooltip: 'Copy Elder ID',
              onPressed: _copyPublicElderId,
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF1E3A8A)),
            )
          else if (!_loadingPublicElderId)
            IconButton(
              tooltip: 'Retry loading Elder ID',
              onPressed: () {
                setState(() {
                  _loadingPublicElderId = true;
                  _publicElderIdError = null;
                });
                _loadPublicElderId();
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACTION CARD
  // ================================================================

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 145,

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Icon(icon, color: iconColor, size: 27),
            ),

            const Spacer(),

            Text(
              title,

              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF243B53),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,

              style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMERGENCY DIALOG
  // ================================================================

  void _showEmergencyDialog() {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 30),

              SizedBox(width: 10),

              Text(
                "Emergency SOS",

                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          content: const Text(
            "Are you sure you want to request emergency assistance?",

            style: TextStyle(fontSize: 16, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleEmergencyIntent('Manual SOS');
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              child: const Text("SOS"),
            ),
          ],
        );
      },
    );
  }
}
