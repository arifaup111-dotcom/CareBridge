import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'profile_screen.dart';
import '../services/gemini_service.dart';
import 'medicines_screen.dart';
import 'appointments_screen.dart';
import 'family_screen.dart';
import 'reminders_screen.dart';
import 'emergency_settings_screen.dart';

class ElderDashboard extends StatefulWidget {
  const ElderDashboard({super.key});

  @override
  State<ElderDashboard> createState() => _ElderDashboardState();
}

class _ElderDashboardState extends State<ElderDashboard> {
  // ================================================================
  // NAVIGATION
  // ================================================================

  int selectedIndex = 0;

  // ================================================================
  // VOICE ASSISTANT
  // ================================================================
  Widget _buildEmergencyCard() {
    return Container(
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

              child: const Row(
                children: [
                  Icon(Icons.person_rounded, color: Colors.red, size: 25),

                  SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "Emergency Contact",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF243B53),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Family contact will be connected later",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.chevron_right_rounded, color: Color(0xFF718096)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ==========================================================
          // CUSTOM EMERGENCY VOICE PHRASE
          // ==========================================================
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

                  Icon(Icons.edit_rounded, color: Color(0xFF718096), size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

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

                  onChanged: (value) {
                    setState(() {
                      _locationSharingEnabled = value;
                    });
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

      builder: (context) {
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
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                // For now, we only show that the phrase was saved.
                // Firebase storage will be added later.

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Emergency phrase saved: "${phraseController.text}"',
                    ),
                  ),
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

      builder: (context) {
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
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            // Save.
            ElevatedButton(
              onPressed: () {
                final String name = nameController.text.trim();

                final String phone = phoneController.text.trim();

                // Check that both fields are filled.
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter both name and phone number."),
                    ),
                  );

                  return;
                }

                // Save the contact locally for now.
                // Later we will save this information in Firebase.
                setState(() {
                  _emergencyContactName = name;
                  _emergencyContactPhone = phone;
                });

                Navigator.pop(context);

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

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final GeminiService _geminiService = GeminiService();

  bool _speechAvailable = false;
  bool _isListening = false;
  // Stores the emergency contact name locally for now.
  // Later this will be stored in Firebase.
  String _emergencyContactName = "";

  // Stores the emergency contact phone number locally for now.
  // Later this will be stored in Firebase.
  String _emergencyContactPhone = "";
  bool _locationSharingEnabled = true;

  String _recognizedText = "";

  String _assistantResponse =
      "Tap the microphone and tell me how I can help you.";

  // ================================================================
  // INITIALIZATION
  // ================================================================

  @override
  void initState() {
    super.initState();
    _initializeVoiceAssistant();
  }

  Future<void> _initializeVoiceAssistant() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint("Speech status: $status");

          if (status == "done" || status == "notListening") {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (error) {
          debugPrint("Speech error: $error");

          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );

      // TTS settings
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Voice initialization error: $e");
    }
  }

  // ================================================================
  // START LISTENING
  // ================================================================

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      await _initializeVoiceAssistant();
    }

    if (!_speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice recognition is not available on this device."),
        ),
      );

      return;
    }

    await _tts.stop();

    if (mounted) {
      setState(() {
        _isListening = true;
        _recognizedText = "";
        _assistantResponse = "I'm listening...";
      });
    }

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _recognizedText = result.recognizedWords;
        });

        debugPrint("Recognized: ${result.recognizedWords}");

        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords);
        }
      },

      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),

      partialResults: true,

      localeId: "ml_IN",
    );
  }

  // ================================================================
  // STOP LISTENING
  // ================================================================

  Future<void> _stopListening() async {
    await _speech.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    if (_recognizedText.trim().isNotEmpty) {
      await _processVoiceCommand(_recognizedText);
    }
  }

  // ================================================================
  // PROCESS VOICE COMMAND
  // ================================================================

  Future<void> _processVoiceCommand(String command) async {
    final text = command.trim();

    if (text.isEmpty) {
      await _speakResponse(
        "ക്ഷമിക്കണം, എനിക്ക് ഒന്നും കേൾക്കാനായില്ല. വീണ്ടും ശ്രമിക്കൂ.",
      );
      return;
    }

    debugPrint("Sending to Gemini: $text");

    if (mounted) {
      setState(() {
        _assistantResponse = "ഒരു നിമിഷം...";
      });
    }

    // ------------------------------------------------------------
    // ASK GEMINI
    // ------------------------------------------------------------

    final response = await _geminiService.askGemini(text);

    debugPrint("Gemini response: $response");

    if (!mounted) return;

    setState(() {
      _assistantResponse = response;
    });

    await _speakResponse(response);
  }

  // ================================================================
  // TEXT TO SPEECH
  // ================================================================

  Future<void> _speakResponse(String response) async {
    try {
      await _tts.stop();

      // Try Malayalam first.
      if (_containsMalayalam(response)) {
        await _tts.setLanguage("ml-IN");
      } else {
        await _tts.setLanguage("en-US");
      }

      await _tts.speak(response);
    } catch (e) {
      debugPrint("Text to speech error: $e");
    }
  }

  // ================================================================
  // MALAYALAM DETECTION
  // ================================================================

  bool _containsMalayalam(String text) {
    final malayalamRegex = RegExp(r'[\u0D00-\u0D7F]');
    return malayalamRegex.hasMatch(text);
  }

  // ================================================================
  // VOICE BUTTON
  // ================================================================

  Future<void> _toggleVoiceAssistant() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
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

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),

            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE8F1FF),

              child: IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF4F8EF7)),

                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile coming soon.")),
                  );
                },
              ),
            ),
          ),
        ],
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
                    const Row(
                      children: [
                        Icon(
                          Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 30,
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "How can I help you?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        _isListening
                            ? "I'm listening to you..."
                            : "You can talk to CareBridge using your voice.",

                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
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
                      onTap: _toggleVoiceAssistant,

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),

                        width: _isListening ? 96 : 82,
                        height: _isListening ? 96 : 82,

                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0.12),

                              blurRadius: _isListening ? 25 : 15,

                              spreadRadius: _isListening ? 5 : 0,
                            ),
                          ],
                        ),

                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,

                          color: const Color(0xFF4F8EF7),

                          size: _isListening ? 46 : 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _isListening ? "Tap to stop" : "Tap to speak",

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
                            builder: (context) => const MedicinesScreen(),
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
                            builder: (context) => const AppointmentsScreen(),
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
                      icon: Icons.family_restroom_rounded,
                      title: "My Family",
                      subtitle: "Stay connected",

                      color: const Color(0xFFFFF5DD),

                      iconColor: const Color(0xFFE6A21A),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FamilyScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.notifications_active_rounded,
                      title: "Reminders",
                      subtitle: "Daily reminders",

                      color: const Color(0xFFF3ECFF),

                      iconColor: const Color(0xFF8A5CF6),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RemindersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ======================================================
              // TODAY'S REMINDER
              // ======================================================
              const Text(
                "Today's Reminder",

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: const Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,

                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEAF4FF),

                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),

                        child: Icon(
                          Icons.medication_rounded,
                          color: Color(0xFF4F8EF7),
                          size: 28,
                        ),
                      ),
                    ),

                    SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Medicine Reminder",

                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF243B53),
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "Take your medicine at 8:00 PM",

                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF4F8EF7),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ======================================================
              // EMERGENCY HELP
              // ======================================================
              _buildEmergencyCard(),
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
          // HOME
          if (index == 0) {
            setState(() {
              selectedIndex = 0;
            });
            return;
          }

          // MEDICINES
          if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MedicinesScreen()),
            );

            if (mounted) {
              setState(() {
                selectedIndex = 0;
              });
            }

            return;
          }

          // APPOINTMENTS
          if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppointmentsScreen(),
              ),
            );

            if (mounted) {
              setState(() {
                selectedIndex = 0;
              });
            }

            return;
          }

          // FAMILY
          if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FamilyScreen()),
            );

            if (mounted) {
              setState(() {
                selectedIndex = 0;
              });
            }

            return;
          }

          // PROFILE
          // PROFILE
          if (index == 4) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );

            if (mounted) {
              setState(() {
                selectedIndex = 0;
              });
            }

            return;
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
            icon: Icon(Icons.family_restroom_rounded),
            label: "Family",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
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

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Emergency assistance requested."),
                  ),
                );
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
