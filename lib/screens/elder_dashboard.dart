import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/care_alarm_service.dart';
import '../services/emergency_call_service.dart';
import '../services/firestore_service.dart';
import '../services/permission_service.dart';
import '../services/voice_service.dart';
import '../services/voice_intent_router.dart';
import '../services/background_voice_bridge.dart';
import '../services/sherpa_wake_word_listener.dart';
import '../services/emergency_location_bridge.dart';
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

enum AssistantLifecycleState {
  disabled,
  initializing,
  waitingForWakeWord,
  capturingCommand,
  processingCommand,
  speakingResponse,
  error,
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

          // ==========================================================
          // CUSTOM EMERGENCY VOICE PHRASE
          // ==========================================================
          if (!readOnly)
            GestureDetector(
              onTap: () {
                _showEmergencyPhraseDialog();
              },

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: Color(0xFF4F8EF7), size: 25),

                    SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Emergency Voice Phrase",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF243B53),
                            ),
                          ),

                          SizedBox(height: 3),

                          Text(
                            'Choose a phrase such as "Amma help"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF718096),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

          if (!readOnly) const SizedBox(height: 12),

          // NATURAL VOICE COMMANDS
          // ==========================================================
          GestureDetector(
            behavior: HitTestBehavior.opaque,

            onTap: _toggleVoiceAssistant,

            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    color: Color(0xFF8A5CF6),
                    size: 25,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Natural Voice Commands",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF243B53),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Example: "I need help, call my daughter"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF28A76B),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

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
              "Press SOS or use your emergency voice phrase.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMERGENCY PHRASE DIALOG
  // ================================================================

  void _showEmergencyPhraseDialog() {
    final TextEditingController phraseController = TextEditingController();

    showDialog(
      context: context,

      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),

          title: const Text(
            "Choose Emergency Phrase",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: TextField(
            controller: phraseController,

            decoration: InputDecoration(
              hintText: "Example: Amma help",
              prefixIcon: const Icon(Icons.mic_rounded),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                final phrase = phraseController.text.trim();
                Navigator.pop(dialogCtx);
                if (phrase.isEmpty) return;

                setState(() => _customEmergencyPhrases = [phrase]);
                final elderId = _elderId ?? await _db.resolveElderId();
                if (elderId != null) {
                  _elderId = elderId;
                  await _db.saveEmergencyPhrases(
                    elderId: elderId,
                    phrases: [phrase],
                  );
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Emergency phrase saved: "$phrase"')),
                );
              },

              child: const Text("Save"),
            ),
          ],
        );
      },
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

  final VoiceService _voice = VoiceService();
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _db = FirestoreService();

  VoiceState _voiceState = VoiceState.idle;

  String _emergencyContactName = "";
  String _emergencyContactPhone = "";
  List<String> _customEmergencyPhrases = const [];
  bool _locationSharingEnabled = true;
  String? _elderId;
  String? _publicElderId;
  String? _publicElderIdError;
  bool _loadingPublicElderId = true;

  String _recognizedText = "";

  // Voice assistant state
  String _assistantResponse = 'Tap the mic and speak in Malayalam or English.';
  String _assistantName = 'Care';
  bool _assistantNameLoaded = false;
  bool _voiceAssistantEnabled = true;
  AssistantLifecycleState _assistantLifecycleState =
      AssistantLifecycleState.initializing;
  bool _handlingVoiceCommand = false;
  bool _awaitingWakeCommand = false;
  bool _conversationActive = false;
  bool _voicePausedForLifecycle = false;
  bool _suppressVoiceAutoRestart = false;
  bool _voiceLoopStarting = false;
  bool _backgroundWakeServiceStarted = false;
  bool _backgroundWakeServicePaused = false;
  bool _backgroundServiceRecoveryInProgress = false;
  bool _returnToWakeAfterCommand = false;
  bool _wakeCommandInProgress = false;
  String? _pendingBackgroundWakePhrase;
  final SherpaWakeWordListener _sherpaWakeWordListener =
      SherpaWakeWordListener();
  bool _emergencyCallWasLaunched = false;
  bool _liveLocationFailureShown = false;
  String? _activeEmergencyId;
  String? _activeEmergencyElderId;
  DateTime? _lastEmergencyCallTime;
  final GlobalKey _emergencyCardKey = GlobalKey();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _careReminderSubscription;

  // ================================================================
  // INITIALIZATION
  // ================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (defaultTargetPlatform == TargetPlatform.android) {
      BackgroundVoiceBridge.initialize(
        onWake: _handleBackgroundWakeWord,
        onError: _handleBackgroundWakeError,
      );
    }
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
    _loadPublicElderId();
    _listenForCareReminders();
    unawaited(_initializeAssistantAndVoice());
  }

  void _handleBackgroundWakeError(String message) {
    if (!mounted || !_voiceAssistantEnabled) return;
    if (_backgroundWakeServiceStarted && !_backgroundWakeServicePaused) {
      unawaited(_pauseBackgroundWakeService());
    } else {
      unawaited(_sherpaWakeWordListener.pause());
    }
    _setAssistantLifecycleState(AssistantLifecycleState.error);
    setState(() => _assistantResponse = message);
  }

  Future<void> _initializeAssistantAndVoice() async {
    _setAssistantLifecycleState(AssistantLifecycleState.initializing);
    await _loadVoiceAssistantEnabled();
    await _loadAssistantName();
    if (!mounted) return;
    if (!_voiceAssistantEnabled) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _sherpaWakeWordListener.pause();
        await BackgroundVoiceBridge.stopForegroundService();
      }
      _setAssistantLifecycleState(AssistantLifecycleState.disabled);
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final notificationsAllowed =
          await PermissionService.requestNotifications();
      if (!notificationsAllowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allow notifications to see the hands-free assistant status.',
            ),
          ),
        );
      }
    }
    await _initializeVoiceAssistant();
    await _startBackgroundWakeService();
    final pendingPhrase = _pendingBackgroundWakePhrase;
    _pendingBackgroundWakePhrase = null;
    if (pendingPhrase != null) {
      await _handleBackgroundWakeWord(pendingPhrase);
    }
  }

  void _setAssistantLifecycleState(AssistantLifecycleState next) {
    if (_assistantLifecycleState == next) return;
    debugPrint(
      'ElderDashboard: voice state '
      '${_assistantLifecycleState.name} -> ${next.name}',
    );
    _assistantLifecycleState = next;
    if (mounted) setState(() {});
  }

  Future<void> _loadVoiceAssistantEnabled() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _voiceAssistantEnabled =
            preferences.getBool('voice_assistant_enabled') ?? true;
      });
    } catch (error) {
      debugPrint('ElderDashboard: voice preference load failed -> $error');
      _setAssistantLifecycleState(AssistantLifecycleState.error);
    }
  }

  Future<void> _setVoiceAssistantEnabled(bool enabled) async {
    if (enabled == _voiceAssistantEnabled) return;
    setState(() => _voiceAssistantEnabled = enabled);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(
        'voice_assistant_enabled',
        enabled,
      );
      if (!saved) {
        throw StateError('Could not persist assistant preference.');
      }
      if (!enabled) {
        _conversationActive = false;
        _awaitingWakeCommand = false;
        _returnToWakeAfterCommand = false;
        _wakeCommandInProgress = false;
        _suppressVoiceAutoRestart = true;
        try {
          await _voice.cancelListening();
          await _voice.stopSpeaking();
          if (defaultTargetPlatform == TargetPlatform.android) {
            await _sherpaWakeWordListener.pause();
            await BackgroundVoiceBridge.stopForegroundService();
          }
        } finally {
          _suppressVoiceAutoRestart = false;
        }
        _backgroundWakeServiceStarted = false;
        _backgroundWakeServicePaused = false;
        _setAssistantLifecycleState(AssistantLifecycleState.disabled);
        if (mounted) {
          setState(() {
            _assistantResponse = 'Voice assistant is off.';
            _recognizedText = '';
          });
        }
        return;
      }

      if (!_voice.isInitialized) await _initializeVoiceAssistant();
      if (!_voice.isSttAvailable) {
        _setAssistantLifecycleState(AssistantLifecycleState.error);
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _startBackgroundWakeService();
      } else {
        _setAssistantLifecycleState(AssistantLifecycleState.waitingForWakeWord);
        await _restartVoiceLoop();
      }
    } catch (error) {
      debugPrint('ElderDashboard: assistant enable update failed -> $error');
      if (mounted) {
        setState(() {
          _voiceAssistantEnabled = !enabled;
          _assistantResponse = 'Could not update voice assistant setting.';
        });
      }
      _setAssistantLifecycleState(AssistantLifecycleState.error);
    }
  }

  Future<void> _startBackgroundWakeService() async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        !_voiceAssistantEnabled ||
        !mounted ||
        !_voice.isInitialized ||
        !_voice.isSttAvailable) {
      return;
    }
    final started = await BackgroundVoiceBridge.startForegroundService(
      wakePhrase: _assistantName,
    );
    if (!mounted) return;
    _backgroundWakeServiceStarted = started;
    _backgroundWakeServicePaused = false;
    if (!started) {
      _setAssistantLifecycleState(AssistantLifecycleState.error);
      setState(
        () => _assistantResponse =
            'Wake listening could not start. Check microphone permission and keep CareBridge open.',
      );
    } else {
      try {
        await _sherpaWakeWordListener.start(
          wakePhrase: _assistantName,
          onWakeWord: _handleBackgroundWakeWord,
          onError: (error, stackTrace) {
            debugPrint('Sherpa wake detection failed: $error');
            _handleBackgroundWakeError(
              'Offline wake detection stopped. Re-enable the assistant to retry.',
            );
          },
        );
      } catch (error) {
        debugPrint('Sherpa wake detection could not start: $error');
        _backgroundWakeServiceStarted = false;
        _backgroundWakeServicePaused = false;
        await BackgroundVoiceBridge.stopForegroundService();
        _setAssistantLifecycleState(AssistantLifecycleState.error);
        if (mounted) {
          setState(
            () => _assistantResponse =
                'Offline wake detection could not start: $error',
          );
        }
        return;
      }
      _setAssistantLifecycleState(AssistantLifecycleState.waitingForWakeWord);
      setState(
        () => _assistantResponse =
            'Listening for "$_assistantName". Say the name to wake me.',
      );
    }
  }

  Future<void> _pauseBackgroundWakeService() async {
    await _sherpaWakeWordListener.pause();
    if (!_backgroundWakeServiceStarted || _backgroundWakeServicePaused) return;
    final paused = await BackgroundVoiceBridge.pauseForegroundVoice();
    if (paused) {
      _backgroundWakeServicePaused = true;
    }
  }

  Future<void> _resumeBackgroundWakeService() async {
    if (!_voiceAssistantEnabled ||
        !_backgroundWakeServiceStarted ||
        (!_backgroundWakeServicePaused && _sherpaWakeWordListener.isRunning)) {
      return;
    }
    if (_backgroundWakeServicePaused) {
      final resumed = await BackgroundVoiceBridge.resumeForegroundVoice();
      if (!resumed) {
        _setAssistantLifecycleState(AssistantLifecycleState.error);
        return;
      }
      _backgroundWakeServicePaused = false;
    }
    try {
      await _sherpaWakeWordListener.start(
        wakePhrase: _assistantName,
        onWakeWord: _handleBackgroundWakeWord,
        onError: (error, stackTrace) {
          debugPrint('Sherpa wake detection failed: $error');
          _handleBackgroundWakeError(
            'Offline wake detection stopped. Re-enable the assistant to retry.',
          );
        },
      );
      _setAssistantLifecycleState(AssistantLifecycleState.waitingForWakeWord);
    } catch (error) {
      debugPrint('Sherpa wake detection could not resume: $error');
      _setAssistantLifecycleState(AssistantLifecycleState.error);
      _handleBackgroundWakeError(
        'Offline wake detection could not resume: $error',
      );
    }
  }

  Future<void> _restoreBackgroundWakeService() async {
    if (!mounted ||
        !_voiceAssistantEnabled ||
        defaultTargetPlatform != TargetPlatform.android ||
        _backgroundServiceRecoveryInProgress) {
      return;
    }
    _backgroundServiceRecoveryInProgress = true;
    try {
      final state = await BackgroundVoiceBridge.foregroundVoiceState();
      if (!mounted || !_voiceAssistantEnabled) return;
      _backgroundWakeServiceStarted = state?['running'] == true;
      _backgroundWakeServicePaused = state?['paused'] == true;
      if (!_backgroundWakeServiceStarted) {
        _backgroundWakeServicePaused = false;
        await _startBackgroundWakeService();
      } else if (_backgroundWakeServicePaused && !_conversationActive) {
        await _resumeBackgroundWakeService();
      } else if (!_sherpaWakeWordListener.isRunning && !_conversationActive) {
        await _resumeBackgroundWakeService();
      }
      await _restartVoiceLoop();
    } finally {
      _backgroundServiceRecoveryInProgress = false;
    }
  }

  Future<void> _handleBackgroundWakeWord(String phrase) async {
    if (!_voiceAssistantEnabled || _wakeCommandInProgress) return;
    if (!_assistantNameLoaded) {
      _pendingBackgroundWakePhrase = phrase;
      return;
    }

    final command = VoiceIntentRouter.commandAfterWakeWord(
      phrase,
      assistantName: _assistantName,
    );
    if (command == null) return;

    _wakeCommandInProgress = true;
    _returnToWakeAfterCommand = true;
    await _pauseBackgroundWakeService();
    if (_backgroundWakeServiceStarted && !_backgroundWakeServicePaused) {
      _wakeCommandInProgress = false;
      _returnToWakeAfterCommand = false;
      _setAssistantLifecycleState(AssistantLifecycleState.error);
      return;
    }
    _conversationActive = true;
    _awaitingWakeCommand = false;
    _setAssistantLifecycleState(
      command.isEmpty
          ? AssistantLifecycleState.capturingCommand
          : AssistantLifecycleState.processingCommand,
    );
    if (command.isEmpty) {
      if (mounted) {
        setState(() {
          _recognizedText = phrase;
          _assistantResponse = 'ഞാൻ ഇവിടെയുണ്ട്. എന്താണ് സഹായം വേണ്ടത്?';
        });
      }
      await _voice.speak(
        _voice.isMalayalamTtsAvailable
            ? 'ഞാൻ ഇവിടെയുണ്ട്. എന്താണ് സഹായം വേണ്ടത്?'
            : 'I am here. How can I help?',
      );
      if (mounted && _conversationActive) {
        await _startListening(forCommand: true);
      }
      return;
    }
    await _handleVoiceCommand(command);
  }

  Future<void> _loadAssistantName() async {
    try {
      final uid = _db.currentUid;
      if (uid == null) return;
      final profile = await _db.getUserProfile(uid);
      final configuredName = (profile?['assistantName'] ?? '')
          .toString()
          .trim();
      final profileName = (profile?['name'] ?? '').toString().trim();
      final useProfileName =
          profileName.isNotEmpty &&
          (configuredName.isEmpty || configuredName.toLowerCase() == 'care');
      var name = useProfileName ? profileName : configuredName;
      if (name.isEmpty && mounted) {
        name = await _showAssistantNameDialog(initialSetup: true) ?? '';
      }

      if (name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _assistantName = name;
            _assistantResponse =
                'Tap the mic and speak in Malayalam or English.';
          });
        } else {
          _assistantName = name;
        }
        _geminiService.setAssistantName(name);
        final savedName = configuredName;
        if (savedName != name) await _db.updateAssistantName(name);
      }
    } catch (error) {
      debugPrint('ElderDashboard: assistant name load failed -> $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load the assistant name. Using Care.'),
          ),
        );
      }
    } finally {
      _assistantNameLoaded = true;
      if (mounted &&
          _voice.isInitialized &&
          defaultTargetPlatform != TargetPlatform.android) {
        unawaited(_restartVoiceLoop());
      }
    }
  }

  Future<String?> _showAssistantNameDialog({bool initialSetup = false}) async {
    final controller = TextEditingController(
      text: initialSetup ? '' : _assistantName,
    );
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: !initialSetup,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          initialSetup ? 'Name your voice assistant' : 'Change assistant name',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name to call',
            hintText: 'For example, Care',
          ),
          onSubmitted: (value) {
            final normalized = value.trim();
            if (normalized.isNotEmpty) Navigator.pop(dialogContext, normalized);
          },
        ),
        actions: [
          if (!initialSetup)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          FilledButton(
            onPressed: () {
              final normalized = controller.text.trim();
              if (normalized.isNotEmpty) {
                Navigator.pop(dialogContext, normalized);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return name;
  }

  Future<void> _changeAssistantName() async {
    final name = await _showAssistantNameDialog();
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      await _db.updateAssistantName(name);
      if (!mounted) return;
      setState(() {
        _assistantName = name.trim();
        _assistantResponse = 'Tap the mic and speak in Malayalam or English.';
      });
      _geminiService.setAssistantName(_assistantName);
      _suppressVoiceAutoRestart = true;
      try {
        await _voice.cancelListening();
      } finally {
        _suppressVoiceAutoRestart = false;
      }
      await _startBackgroundWakeService();
      await _restartVoiceLoop();
    } catch (error) {
      debugPrint('ElderDashboard: assistant name update failed -> $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the assistant name.')),
        );
      }
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
                  wakeUpTime: (settings['wakeUpTime'] ?? '7:00 AM').toString(),
                  exerciseTime: (settings['exerciseTime'] ?? '8:00 AM')
                      .toString(),
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
    String wakeUpTime = '7:00 AM',
    String exerciseTime = '8:00 AM',
  }) async {
    try {
      if (!await PermissionService.requestNotifications()) {
        await CareAlarmService.instance.clearDailyReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Allow notifications to receive care alarms.'),
            ),
          );
        }
        return;
      }
      await CareAlarmService.instance.scheduleDailyReminders(
        mealTimes: mealTimes,
        waterTimes: waterTimes,
        wakeUpTime: wakeUpTime,
        exerciseTime: exerciseTime,
      );

      final id = _elderId ?? await _db.resolveElderId();
      if (id != null) {
        final medicines = await _db.getMedicinesOnce(id);
        await CareAlarmService.instance.scheduleMedicineReminders(
          medicines: medicines,
        );
        final appointments = await _db.getAppointmentsOnce(id);
        await CareAlarmService.instance.scheduleAppointmentReminders(
          appointments: appointments,
        );
      }
      await _scheduleTrialReminderOnce();
    } catch (error) {
      debugPrint('Could not schedule care alarms: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not schedule care reminders.')),
        );
      }
    }
  }

  Future<void> _scheduleTrialReminderOnce() async {
    final preferences = await SharedPreferences.getInstance();
    const trialKey = 'carebridgeTrialReminderScheduled';
    if (preferences.getBool(trialKey) == true) return;
    await CareAlarmService.instance.scheduleTrialReminder();
    await preferences.setBool(trialKey, true);
  }

  Future<void> _loadEmergencyData() async {
    try {
      final id = await _db.resolveElderId();
      if (id == null) return;
      final data = await _db.getEmergencySettings(id);
      if (!mounted) return;
      final phrases =
          (data?['phrases'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          <String>[];
      setState(() {
        _elderId = id;
        _emergencyContactName = (data?['contactName'] ?? '').toString().trim();
        _emergencyContactPhone = (data?['contactNumber'] ?? '')
            .toString()
            .trim();
        _customEmergencyPhrases = phrases;
        _locationSharingEnabled = data?['locationSharingEnabled'] != false;
      });
    } catch (e) {
      debugPrint('ElderDashboard: emergency data load failed -> $e');
    }
  }

  Future<void> _initializeVoiceAssistant() async {
    _voice.onStateChanged = (state) {
      if (!mounted) return;
      final wasListening = _voiceState == VoiceState.listening;
      setState(() {
        _voiceState = state;
      });
      if (state == VoiceState.speaking) {
        _setAssistantLifecycleState(AssistantLifecycleState.speakingResponse);
      } else if (state == VoiceState.processing) {
        _setAssistantLifecycleState(AssistantLifecycleState.processingCommand);
      }
      if (state == VoiceState.idle &&
          wasListening &&
          _conversationActive &&
          !_voicePausedForLifecycle &&
          !_suppressVoiceAutoRestart &&
          !_handlingVoiceCommand) {
        unawaited(_restartVoiceLoop());
      }
    };

    _voice.onPartialResult = (text) {
      if (!mounted) return;
      setState(() {
        _recognizedText = text;
      });
    };

    _voice.onFinalResult = (text) {
      if (!mounted) return;
      setState(() {
        _recognizedText = text;
      });
      _handleVoiceCommand(text);
    };

    _voice.onError = (message) {
      if (!mounted) return;
      final wasSilence = message.contains('ഒന്നും കേൾക്കാനായില്ല');
      _awaitingWakeCommand = false;
      if (wasSilence) {
        _wakeCommandInProgress = false;
        _returnToWakeAfterCommand = false;
        if (_conversationActive) {
          _conversationActive = false;
          setState(
            () => _assistantResponse =
                'സംഭാഷണം അവസാനിച്ചു. വീണ്ടും സംസാരിക്കാൻ $_assistantName എന്ന് വിളിക്കൂ.',
          );
        }
        unawaited(_restartVoiceLoop());
        return;
      }
      _conversationActive = false;
      _wakeCommandInProgress = false;
      _returnToWakeAfterCommand = false;
      _setAssistantLifecycleState(AssistantLifecycleState.error);
      setState(() => _assistantResponse = message);
      unawaited(_restartVoiceLoop());
    };

    await _voice.initialize();

    if (!mounted) return;
    setState(() {
      if (!_voice.isSttAvailable) {
        _assistantResponse = _voice.capabilityNote();
      } else if (!_voice.isMalayalamSttAvailable) {
        _assistantResponse =
            'ഈ ഫോണിൽ മലയാളം ശബ്ദ തിരിച്ചറിയൽ ലഭ്യമല്ല. Google voice typing-ൽ മലയാളം ഭാഷാ പാക്ക് ഇൻസ്റ്റാൾ ചെയ്യുക.';
      } else if (!_voice.isMalayalamTtsAvailable) {
        _assistantResponse =
            'മലയാളത്തിൽ സംസാരിക്കാം. മറുപടി സ്ക്രീനിൽ കാണാം; Malayalam voice is not installed.';
      } else {
        _assistantResponse = 'Tap the mic and speak in Malayalam or English.';
      }
    });
    if (_assistantNameLoaded &&
        defaultTargetPlatform != TargetPlatform.android) {
      await _restartVoiceLoop();
    }
  }

  // ================================================================
  // START LISTENING
  // ================================================================

  Future<void> _startListening({bool forCommand = false}) async {
    if (_voiceLoopStarting) return;
    _voiceLoopStarting = true;
    try {
      await _pauseBackgroundWakeService();
      if (_backgroundWakeServiceStarted && !_backgroundWakeServicePaused) {
        _setAssistantLifecycleState(AssistantLifecycleState.error);
        return;
      }
      if (!_voice.isInitialized) {
        await _initializeVoiceAssistant();
      }

      if (!_voiceAssistantEnabled || !_voice.isSttAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_voice.capabilityNote())));
        }
        return;
      }

      if (_voice.isListening) return;
      if (mounted) {
        setState(() {
          _recognizedText = "";
          _assistantResponse = forCommand
              ? 'Listening for your request...'
              : 'Listening for "$_assistantName"...';
        });
      }
      _setAssistantLifecycleState(
        forCommand
            ? AssistantLifecycleState.capturingCommand
            : AssistantLifecycleState.waitingForWakeWord,
      );
      final isMalayalamWakeName = RegExp(
        r'[\u0D00-\u0D7F]',
      ).hasMatch(_assistantName);
      await _voice.startListening(
        listenFor: const Duration(seconds: 60),
        pauseFor: forCommand
            ? const Duration(seconds: 3)
            : const Duration(seconds: 4),
        localeId: forCommand
            ? _voice.commandLocale
            : isMalayalamWakeName
            ? _voice.wakeWordLocale
            : _voice.englishWakeLocale,
        useDictationMode: true,
      );
    } finally {
      _voiceLoopStarting = false;
    }
  }

  // ================================================================
  // PROCESS VOICE COMMAND
  // ================================================================

  /// Entry point for anything the elder said, whether captured by
  /// [_startListening]'s live stream. Classifies the sentence, then either
  /// navigates, handles an emergency, or falls through to Gemini chat.
  Future<void> _handleVoiceCommand(String command) async {
    if (_handlingVoiceCommand) return;
    _handlingVoiceCommand = true;

    var text = command.trim();
    try {
      await _voice.cancelListening();
      if (!_conversationActive) {
        final activatedCommand = VoiceIntentRouter.commandAfterWakeWord(
          text,
          assistantName: _assistantName,
        );
        if (activatedCommand == null) {
          if (mounted) {
            setState(() {
              _recognizedText = '';
              _assistantResponse =
                  'I did not hear "$_assistantName". Tap the mic and try again.';
            });
          }
          await _restartVoiceLoop();
          return;
        }

        _conversationActive = true;
        text = activatedCommand;
        if (text.isEmpty) {
          _awaitingWakeCommand = false;
          if (mounted) {
            setState(() {
              _recognizedText = _assistantName;
              _assistantResponse = 'ഞാൻ ഇവിടെയുണ്ട്. എന്താണ് സഹായം വേണ്ടത്?';
            });
          }
          await _voice.speak(
            _voice.isMalayalamTtsAvailable
                ? 'ഞാൻ ഇവിടെയുണ്ട്. എന്താണ് സഹായം വേണ്ടത്?'
                : 'I am here. How can I help?',
          );
          await _startListening(forCommand: true);
          return;
        }
        _awaitingWakeCommand = false;
      }

      if (text.isNotEmpty &&
          _voiceAssistantEnabled &&
          defaultTargetPlatform == TargetPlatform.android &&
          _backgroundWakeServiceStarted &&
          _backgroundWakeServicePaused) {
        _returnToWakeAfterCommand = true;
        _wakeCommandInProgress = true;
      }

      if (RegExp(
        r"^(?:stop|stop listening|goodbye|bye|that(?: is|'s) all|നിർത്ത്|നിർത്തൂ|മതി|പിന്നെ സംസാരിക്കാം)$",
        caseSensitive: false,
      ).hasMatch(text)) {
        _conversationActive = false;
        await _respondAndSpeak(
          VoiceService.containsMalayalam(text)
              ? 'ശരി. വീണ്ടും മൈക്രോഫോൺ അമർത്തി $_assistantName എന്ന് പറഞ്ഞാൽ ഞാൻ സഹായിക്കാം.'
              : 'Okay. Tap the mic and say "$_assistantName" when you need me.',
        );
        await _restartVoiceLoop();
        return;
      }

      if (mounted) setState(() => _recognizedText = text);
      _setAssistantLifecycleState(AssistantLifecycleState.processingCommand);
      if (text.isEmpty) {
        await _restartVoiceLoop();
        return;
      }

      // Voice acknowledgment for taking medicine (e.g., "മരുന്ന് കഴിച്ചു", "ഗുളിക കഴിച്ചു")
      if (RegExp(
            r'(?:മരുന്ന്|ഗുളിക|ടാബ്‌ലെറ്റ്|medicine|pill)\s*(?:കഴിച്ചു|കുടിച്ചു|എടുത്തു|തീർത്തു|taken|took)',
            caseSensitive: false,
          ).hasMatch(text) ||
          RegExp(
            r'\b(?:took|had|taken)\s+(?:my\s+)?(?:medicine|medication|pill|tablet)s?\b',
            caseSensitive: false,
          ).hasMatch(text) ||
          RegExp(
            r'^(?:കഴിച്ചു|എടുത്തു|done|taken)$',
            caseSensitive: false,
          ).hasMatch(text)) {
        await _handleMedicineTakenVoiceConfirmation(text);
        await _restartVoiceLoop();
        return;
      }

      if (_isCareReminderConfirmation(text)) {
        await _handleCareReminderConfirmation(text);
        await _restartVoiceLoop();
        return;
      }

      final intent = VoiceIntentRouter.detect(
        text,
        customEmergencyPhrases: _customEmergencyPhrases,
      );
      debugPrint('Voice intent detected: ${intent.name}');

      switch (intent) {
        case VoiceIntentType.emergency:
          await _handleEmergencyIntent(text);
          return;
        case VoiceIntentType.medicineToday:
          await _handleMedicineVoiceQuery(text);
          break;
        case VoiceIntentType.appointmentToday:
          await _handleAppointmentVoiceQuery(text);
          break;
        case VoiceIntentType.careReminders:
          await _handleCareReminderVoiceQuery(text);
          break;
        case VoiceIntentType.openMedicines:
          await _handleNavigationIntent(
            malayalamMessage: "മരുന്നുകൾ തുറക്കുന്നു.",
            englishMessage: "Opening your medicines.",
            builder: (context) => const MedicinesScreen(readOnly: true),
          );
          return;
        case VoiceIntentType.openAppointments:
          await _handleNavigationIntent(
            malayalamMessage: "അപ്പോയിന്റ്മെന്റുകൾ തുറക്കുന്നു.",
            englishMessage: "Opening your appointments.",
            builder: (context) => const AppointmentsScreen(readOnly: true),
          );
          return;
        case VoiceIntentType.openReminders:
          await _handleNavigationIntent(
            malayalamMessage: "ഓർമ്മപ്പെടുത്തലുകൾ തുറക്കുന്നു.",
            englishMessage: "Opening your reminders.",
            builder: (context) => const RemindersScreen(),
          );
          return;
        case VoiceIntentType.chat:
          await _handleChatIntent(text);
          break;
      }

      await _restartVoiceLoop();
    } finally {
      _handlingVoiceCommand = false;
      if (_returnToWakeAfterCommand) {
        _returnToWakeAfterCommand = false;
        _wakeCommandInProgress = false;
        _conversationActive = false;
        _awaitingWakeCommand = false;
        if (!_emergencyCallWasLaunched && _voiceAssistantEnabled) {
          unawaited(_restartVoiceLoop());
        }
      }
    }
  }

  Future<void> _handleMedicineTakenVoiceConfirmation(String sourceText) async {
    final elderId = _elderId ?? await _db.resolveElderId();
    if (elderId == null) {
      await _respondAndSpeak(
        _localizedResponse(
          sourceText,
          malayalam: 'മരുന്നുകളുടെ വിവരങ്ങൾ ലഭ്യമല്ല.',
          english: 'Your medicine information is unavailable.',
        ),
      );
      return;
    }
    try {
      final medicines = await _db.getMedicinesOnce(elderId);
      final untaken = medicines.where((m) => m['taken'] != true).toList();
      if (untaken.isNotEmpty) {
        final target = untaken.first;
        await _db.markMedicineTaken(
          elderId: elderId,
          medicineId: target['id'].toString(),
          taken: true,
        );
        final name = (target['name'] ?? 'മരുന്ന്').toString();
        await _respondAndSpeak(
          _localizedResponse(
            sourceText,
            malayalam: 'വളരെ നല്ലത്. $name കഴിച്ചതായി രേഖപ്പെടുത്തിയിട്ടുണ്ട്.',
            english: 'Good. I marked $name as taken.',
          ),
        );
      } else {
        await _respondAndSpeak(
          _localizedResponse(
            sourceText,
            malayalam:
                'ഇന്നത്തെ മരുന്നുകളെല്ലാം കഴിച്ചതായി കാണുന്നു. വളരെ സന്തോഷം!',
            english: 'All of today’s medicines are already marked as taken.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Medicine taken voice confirmation error: $e');
      await _respondAndSpeak(
        _localizedResponse(
          sourceText,
          malayalam: 'മരുന്ന് കഴിച്ചതായി അടയാളപ്പെടുത്താൻ കഴിഞ്ഞില്ല.',
          english: 'I could not update the medicine status.',
        ),
      );
    }
  }

  String _localizedResponse(
    String sourceText, {
    required String malayalam,
    required String english,
  }) => VoiceService.containsMalayalam(sourceText) ? malayalam : english;

  Future<void> _handleMedicineVoiceQuery(String text) async {
    if (_elderId == null) await _loadEmergencyData();
    final elderId = _elderId;
    if (elderId == null) {
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'മരുന്നുകളുടെ വിവരങ്ങൾ ലഭ്യമല്ല.',
          english: 'Your medicine information is unavailable.',
        ),
      );
      return;
    }

    try {
      final medicines = await _db.getMedicinesOnce(elderId);
      if (medicines.isEmpty) {
        await _respondAndSpeak(
          _localizedResponse(
            text,
            malayalam:
                'ഇന്ന് നിങ്ങൾക്ക് പുതിയ മരുന്നുകൾ ഒന്നും രേഖപ്പെടുത്തിയിട്ടില്ല.',
            english: 'There are no medicines scheduled for today.',
          ),
        );
        return;
      }
      final untaken = medicines.where((m) => m['taken'] != true).toList();
      if (untaken.isEmpty) {
        await _respondAndSpeak(
          _localizedResponse(
            text,
            malayalam:
                'ഇന്നത്തെ മരുന്നുകളെല്ലാം നിങ്ങൾ കഴിച്ചു കഴിഞ്ഞു. വളരെ നല്ലത്!',
            english: 'All of today’s medicines are marked as taken. Well done!',
          ),
        );
        return;
      }
      final summary = untaken
          .map((m) {
            final name = (m['name'] ?? 'മരുന്ന്').toString();
            final dosage = (m['dosage'] ?? '').toString();
            final time = (m['time'] ?? '').toString();
            return '$name $dosage $time'.trim();
          })
          .join(', ');
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'ഇന്ന് കഴിക്കാനുള്ള മരുന്നുകൾ: $summary എന്നിവയാണ്.',
          english: 'Your medicines for today are: $summary.',
        ),
      );
    } catch (e) {
      debugPrint('Medicine voice query failed: $e');
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'മരുന്നുകളുടെ വിവരങ്ങൾ എടുക്കാൻ കഴിഞ്ഞില്ല.',
          english: 'I could not load your medicine information.',
        ),
      );
    }
  }

  Future<void> _handleAppointmentVoiceQuery(String text) async {
    if (_elderId == null) await _loadEmergencyData();
    final elderId = _elderId;
    if (elderId == null) {
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'അപ്പോയിന്റ്മെന്റുകളുടെ വിവരങ്ങൾ ലഭ്യമല്ല.',
          english: 'Your appointment information is unavailable.',
        ),
      );
      return;
    }

    try {
      final appointments = await _db.getAppointmentsOnce(elderId);
      final now = DateTime.now();
      final today = '${now.day}/${now.month}/${now.year}';
      final todaysAppointments = appointments
          .where((appointment) => appointment['date']?.toString() == today)
          .toList();
      if (todaysAppointments.isEmpty) {
        await _respondAndSpeak(
          _localizedResponse(
            text,
            malayalam: 'ഇന്ന് പുതിയ അപ്പോയിന്റ്മെന്റുകൾ ഒന്നും ഇല്ല.',
            english: 'There are no appointments recorded for today.',
          ),
        );
        return;
      }
      final summary = todaysAppointments
          .map((a) {
            final doc = (a['doctor'] ?? 'ഡോക്ടർ').toString();
            final hosp = (a['hospital'] ?? '').toString();
            final time = (a['time'] ?? '').toString();
            final details = [
              doc,
              hosp,
              time,
            ].where((value) => value.trim().isNotEmpty).join(', ');
            return details;
          })
          .join(', ');
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'ഇന്നത്തെ അപ്പോയിന്റ്മെന്റ്: $summary ആണ്.',
          english: 'Your appointments are: $summary.',
        ),
      );
    } catch (e) {
      debugPrint('Appointment voice query failed: $e');
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'അപ്പോയിന്റ്മെന്റുകളുടെ വിവരങ്ങൾ എടുക്കാൻ കഴിഞ്ഞില്ല.',
          english: 'I could not load your appointment information.',
        ),
      );
    }
  }

  Future<void> _handleCareReminderVoiceQuery(String text) async {
    if (_elderId == null) await _loadEmergencyData();
    final elderId = _elderId;
    if (elderId == null) {
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'ഓർമ്മപ്പെടുത്തലുകളുടെ വിവരങ്ങൾ ലഭ്യമല്ല.',
          english: 'Your reminder information is unavailable.',
        ),
      );
      return;
    }

    try {
      final settings = await _db.getCareReminderSettings(elderId);
      final mealTimes = (settings?['mealTimes'] as List? ?? const [])
          .map((time) => time.toString())
          .toList();
      final waterTimes = (settings?['waterTimes'] as List? ?? const [])
          .map((time) => time.toString())
          .toList();
      final isWater =
          text.contains('വെള്ളം') ||
          text.contains('കുടി') ||
          text.contains('ദാഹം') ||
          text.toLowerCase().contains('water');
      if (isWater) {
        final waterStr = waterTimes.isEmpty
            ? 'നിശ്ചയിച്ചിട്ടില്ല'
            : waterTimes.join(', ');
        await _respondAndSpeak(
          _localizedResponse(
            text,
            malayalam:
                'വെള്ളം കുടിക്കാനുള്ള സമയങ്ങൾ: $waterStr ആണ്. ആവശ്യത്തിന് വെള്ളം കുടിക്കാൻ ശ്രദ്ധിക്കൂ.',
            english: 'Your water reminders are at: $waterStr.',
          ),
        );
      } else {
        final mealStr = mealTimes.isEmpty
            ? 'നിശ്ചയിച്ചിട്ടില്ല'
            : mealTimes.join(', ');
        await _respondAndSpeak(
          _localizedResponse(
            text,
            malayalam:
                'ഭക്ഷണ സമയങ്ങൾ: $mealStr ആണ്. കൃത്യസമയത്ത് ഭക്ഷണം കഴിക്കൂ.',
            english: 'Your meal reminders are at: $mealStr.',
          ),
        );
      }
    } catch (e) {
      debugPrint('Care reminder voice query failed: $e');
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'ഓർമ്മപ്പെടുത്തലുകൾ ലഭ്യമാക്കാൻ കഴിഞ്ഞില്ല.',
          english: 'I could not load your reminders.',
        ),
      );
    }
  }

  bool _isCareReminderConfirmation(String text) {
    final lower = text.toLowerCase();
    final confirmsAction =
        RegExp(
          r'(?:കഴിച്ചു|കഴിച്ചുകഴിഞ്ഞു|ഭക്ഷിച്ചു|കുടിച്ചു|കുടിച്ചുകഴിഞ്ഞു)',
        ).hasMatch(lower) ||
        RegExp(r'\b(?:drank|had|ate|finished)\b').hasMatch(lower);
    if (!confirmsAction) return false;

    final mentionsWater =
        lower.contains('വെള്ളം') ||
        lower.contains('ദാഹം') ||
        lower.contains('water') ||
        lower.contains('drink');
    final mentionsMeal =
        lower.contains('ഭക്ഷണം') ||
        lower.contains('ഊണ്') ||
        lower.contains('ഭക്ഷിച്ചു') ||
        lower.contains('meal') ||
        lower.contains('food') ||
        lower.contains('breakfast') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('ate');
    return mentionsWater || mentionsMeal;
  }

  Future<void> _handleCareReminderConfirmation(String text) async {
    if (_elderId == null) await _loadEmergencyData();
    final elderId = _elderId;
    if (elderId == null) {
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam: 'ഓർമ്മപ്പെടുത്തലുകളുടെ വിവരങ്ങൾ ലഭ്യമല്ല.',
          english: 'Your reminder information is unavailable.',
        ),
      );
      return;
    }

    final lower = text.toLowerCase();
    final isWater =
        lower.contains('വെള്ളം') ||
        lower.contains('ദാഹം') ||
        lower.contains('water') ||
        lower.contains('drink');
    final category = isWater ? 'water' : 'meal';
    try {
      await _db.markCareReminderCompleted(elderId: elderId, category: category);
      final message = isWater
          ? _localizedResponse(
              text,
              malayalam:
                  'വെള്ളം കുടിച്ചതായി രേഖപ്പെടുത്തി. നിങ്ങളുടെ കുടുംബത്തിനും ഇത് കാണാം.',
              english: 'Water intake recorded. Your family can see the update.',
            )
          : _localizedResponse(
              text,
              malayalam:
                  'ഭക്ഷണം കഴിച്ചതായി രേഖപ്പെടുത്തി. നിങ്ങളുടെ കുടുംബത്തിനും ഇത് കാണാം.',
              english: 'Meal recorded. Your family can see the update.',
            );
      await _respondAndSpeak(message);
    } catch (error) {
      debugPrint('Care reminder confirmation failed: $error');
      await _respondAndSpeak(
        _localizedResponse(
          text,
          malayalam:
              'ഇത് രേഖപ്പെടുത്താൻ കഴിഞ്ഞില്ല. ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കൂ.',
          english:
              'I could not save that update. Please check your connection.',
        ),
      );
    }
  }

  Future<void> _respondAndSpeak(String message) async {
    if (!mounted) return;
    setState(() => _assistantResponse = message);
    _setAssistantLifecycleState(AssistantLifecycleState.speakingResponse);
    await _voice.speak(message);
    if (_voiceAssistantEnabled) {
      _setAssistantLifecycleState(AssistantLifecycleState.processingCommand);
    }
  }

  Future<void> _restartVoiceLoop() async {
    if (!mounted ||
        !_voiceAssistantEnabled ||
        _handlingVoiceCommand ||
        !_assistantNameLoaded ||
        !_voice.isInitialized ||
        _voicePausedForLifecycle ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        _voice.isListening ||
        _voiceLoopStarting) {
      return;
    }
    if (_conversationActive || _awaitingWakeCommand) {
      await _startListening(forCommand: _conversationActive);
    } else {
      await _resumeBackgroundWakeService();
    }
  }

  /// Speaks a short confirmation, then pushes the matched screen.
  ///
  /// Used for every voice-triggered navigation so the elder always
  /// hears what's about to happen before the screen changes — jumping
  /// straight to a new screen with no warning is disorienting.
  Future<void> _handleNavigationIntent({
    required String malayalamMessage,
    required String englishMessage,
    required WidgetBuilder builder,
  }) async {
    final message = VoiceService.containsMalayalam(_recognizedText)
        ? malayalamMessage
        : englishMessage;

    if (mounted) {
      setState(() {
        _assistantResponse = message;
      });
    }

    await _voice.speak(message);

    if (!mounted) return;

    await Navigator.push(context, MaterialPageRoute(builder: builder));

    if (!mounted) return;

    setState(() {
      selectedIndex = 0;
      _recognizedText = "";
      _assistantResponse = 'Tap the mic and speak in Malayalam or English.';
    });
    await _restartVoiceLoop();
  }

  /// Critical voice phrase: record the emergency and immediately call the
  /// primary contact saved in Firestore. Location is recorded when enabled.
  Future<void> _handleEmergencyIntent(String triggerPhrase) async {
    _awaitingWakeCommand = false;
    await _voice.cancelListening();
    // Debounce calls within 15 seconds to prevent accidental duplicate dialing
    if (_lastEmergencyCallTime != null &&
        DateTime.now().difference(_lastEmergencyCallTime!).inSeconds < 15) {
      await _respondAndSpeak(
        'അടിയന്തര കോൾ ഇതിനകം ആരംഭിച്ചിട്ടുണ്ട്. ദയവായി അല്പം കാത്തിരിക്കൂ.',
      );
      await _restartVoiceLoop();
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
      await _respondAndSpeak(
        eventRecorded
            ? 'അടിയന്തര സംഭവം രേഖപ്പെടുത്തി. അടിയന്തര കോൺടാക്ട് നമ്പർ സജ്ജീകരിച്ചിട്ടില്ല; SOS സഹായം ലഭ്യമാക്കാൻ Emergency Settings തുറന്ന് നമ്പർ ചേർക്കുക.'
            : 'അടിയന്തര കോൺടാക്ട് നമ്പർ സജ്ജീകരിച്ചിട്ടില്ല, സംഭവവും രേഖപ്പെടുത്താനായില്ല. സഹായത്തിനായി സമീപത്തുള്ള ഒരാളോട് പറയുക.',
      );
      await _restartVoiceLoop();
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

    if (mounted) {
      setState(() {
        _assistantResponse = _emergencyContactName.isEmpty
            ? 'അടിയന്തര സഹായത്തിനായി കോൾ ആരംഭിക്കുന്നു.'
            : '$_emergencyContactName നെ വിളിക്കുന്നു.';
      });
    }

    if (!await PermissionService.requestPhone()) {
      await _respondAndSpeak(
        eventRecorded
            ? 'അടിയന്തര സംഭവം രേഖപ്പെടുത്തി, പക്ഷേ ഫോൺ കോളിന് അനുമതി ലഭിച്ചില്ല. Phone permission അനുവദിക്കുക.'
            : 'അടിയന്തര സംഭവം രേഖപ്പെടുത്താനായില്ല, ഫോൺ കോളിനും അനുമതി ലഭിച്ചില്ല. സമീപത്തുള്ള ഒരാളോട് സഹായം ചോദിക്കുക.',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emergencySmsStatus)));
      }
      await _restartVoiceLoop();
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
    if (called && mounted) {
      setState(() {
        _assistantResponse = eventRecorded
            ? '${_emergencyContactName.isEmpty ? 'അടിയന്തര കോൾ ആരംഭിച്ചു.' : '$_emergencyContactName നെ വിളിക്കാൻ കോൾ ആരംഭിച്ചു.'} '
                  '${liveLocationStarted ? 'കുടുംബത്തിനായി തത്സമയ ലൊക്കേഷൻ പങ്കിടൽ ആരംഭിക്കുന്നു.' : 'തത്സമയ ലൊക്കേഷൻ ലഭ്യമല്ല.'} '
                  '$emergencySmsStatus'
            : 'കോൾ ആരംഭിച്ചു, പക്ഷേ അടിയന്തര സംഭവം രേഖപ്പെടുത്താനായില്ല.';
      });
    } else if (!called) {
      _emergencyCallWasLaunched = false;
      if (liveLocationStarted) await _stopLiveEmergencyLocation();
      await _respondAndSpeak(
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
    if (!called) await _restartVoiceLoop();
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

  /// Nothing matched a screen or an emergency — treat it as a normal
  /// question for Gemini, same as before.
  Future<void> _handleChatIntent(String text) async {
    if (mounted) {
      setState(() {
        _assistantResponse = "ഒരു നിമിഷം...";
      });
    }

    final response = await _geminiService.askGemini(text);

    debugPrint("Gemini response: $response");

    if (!mounted) return;

    setState(() {
      _assistantResponse = response;
    });

    await _voice.speak(response);
  }

  // ================================================================
  // VOICE BUTTON
  // ================================================================

  Future<void> _toggleVoiceAssistant() async {
    if (!_voiceAssistantEnabled) return;
    final wasListening = _voice.isListening;
    if (wasListening) {
      _suppressVoiceAutoRestart = true;
      try {
        await _voice.cancelListening();
      } finally {
        _suppressVoiceAutoRestart = false;
      }
    }

    if (_conversationActive) {
      _conversationActive = false;
      _awaitingWakeCommand = false;
      _wakeCommandInProgress = false;
      _returnToWakeAfterCommand = false;
      await _voice.stopSpeaking();
      await _restartVoiceLoop();
      return;
    }

    _conversationActive = true;
    _awaitingWakeCommand = false;
    await _startListening(forCommand: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _voicePausedForLifecycle = false;
      if (_emergencyCallWasLaunched) {
        _emergencyCallWasLaunched = false;
        if (_activeEmergencyId != null) {
          unawaited(_stopLiveEmergencyLocation());
        }
      }
      if (defaultTargetPlatform == TargetPlatform.android &&
          _voiceAssistantEnabled) {
        unawaited(_restoreBackgroundWakeService());
      } else {
        unawaited(_restartVoiceLoop());
      }
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _voicePausedForLifecycle = true;
      _conversationActive = false;
      _awaitingWakeCommand = false;
      _wakeCommandInProgress = false;
      _returnToWakeAfterCommand = false;
      unawaited(_releaseForegroundVoiceAndResumeWake());
    }
  }

  Future<void> _releaseForegroundVoiceAndResumeWake() async {
    await _voice.cancelListening();
    await _voice.stopSpeaking();
    if (!_emergencyCallWasLaunched && _voiceAssistantEnabled) {
      await _resumeBackgroundWakeService();
    }
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    // State.dispose() is synchronous; VoiceService.dispose() is not
    // awaited here on purpose — the screen is going away regardless,
    // this just lets the engines wind down cleanly.
    WidgetsBinding.instance.removeObserver(this);
    _careReminderSubscription?.cancel();
    _voice.dispose();
    unawaited(_sherpaWakeWordListener.dispose());
    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(BackgroundVoiceBridge.stopForegroundService());
    }
    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final bool isListening = _voiceState == VoiceState.listening;
    final bool isCapturingCommand = _awaitingWakeCommand;
    final assistantStatusText = switch (_assistantLifecycleState) {
      AssistantLifecycleState.disabled => 'Voice assistant is off.',
      AssistantLifecycleState.initializing => 'Starting voice assistant...',
      AssistantLifecycleState.waitingForWakeWord =>
        'Waiting for "$_assistantName"...',
      AssistantLifecycleState.capturingCommand =>
        'Listening for your request...',
      AssistantLifecycleState.processingCommand => 'Preparing your response...',
      AssistantLifecycleState.speakingResponse => 'Speaking...',
      AssistantLifecycleState.error => _assistantResponse,
    };

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
              // ======================================================
              // VOICE ASSISTANT CARD
              // ======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F8EF7), Color(0xFF6FA8FF)],

                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(28),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 30,
                        ),

                        SizedBox(width: 12),

                        const Expanded(
                          child: Text(
                            'How can I help you?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Change assistant name',
                          onPressed: _changeAssistantName,
                          color: Colors.white,
                          icon: const Icon(Icons.settings_voice_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        isListening
                            ? (_conversationActive && !_awaitingWakeCommand
                                  ? 'Listening for your request...'
                                  : 'Listening for "$_assistantName"...')
                            : assistantStatusText,

                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Hands-free assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _voiceAssistantEnabled
                            ? 'Waiting for "$_assistantName"'
                            : 'Wake-word monitoring is off',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      value: _voiceAssistantEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.lightBlueAccent,
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.white24,
                      onChanged: _setVoiceAssistantEnabled,
                    ),

                    const SizedBox(height: 18),

                    // Recognized speech
                    if (_recognizedText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),

                        margin: const EdgeInsets.only(bottom: 14),

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: Text(
                          '"$_recognizedText"',

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    // Assistant response
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),

                      margin: const EdgeInsets.only(bottom: 18),

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 22,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              _assistantResponse,

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Microphone
                    GestureDetector(
                      onTap: _voiceAssistantEnabled
                          ? _toggleVoiceAssistant
                          : null,

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),

                        width: isListening && isCapturingCommand ? 96 : 82,
                        height: isListening && isCapturingCommand ? 96 : 82,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: isListening && isCapturingCommand
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0.12),

                              blurRadius: isListening && isCapturingCommand
                                  ? 25
                                  : 15,

                              spreadRadius: isListening && isCapturingCommand
                                  ? 5
                                  : 0,
                            ),
                          ],
                        ),

                        child: Icon(
                          isListening && isCapturingCommand
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,

                          color: _voiceAssistantEnabled
                              ? const Color(0xFF4F8EF7)
                              : Colors.grey,

                          size: isListening && isCapturingCommand ? 46 : 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isListening
                          ? (_conversationActive && !_awaitingWakeCommand
                                ? 'Listening for your request...'
                                : 'Waiting for "$_assistantName"...')
                          : assistantStatusText,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ======================================================
              const SizedBox(height: 26),

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
          if (index == 5) {
            _conversationActive = false;
            _awaitingWakeCommand = false;
            if (_voice.isListening) {
              _suppressVoiceAutoRestart = true;
              try {
                await _voice.cancelListening();
              } finally {
                _suppressVoiceAutoRestart = false;
              }
            }
          }
          if (!mounted) return;
          await navigator.push(MaterialPageRoute(builder: (context) => page));
          if (mounted) {
            setState(() => selectedIndex = 0);
            if (index == 5) {
              await _loadAssistantName();
              await _startBackgroundWakeService();
            }
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
