import 'package:flutter/material.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  State<EmergencySettingsScreen> createState() =>
      _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  // Stores the emergency phrase entered by the elder.
  String emergencyPhrase = "";

  // Controls whether the custom emergency phrase is enabled.
  bool phraseEnabled = true;

  // Controls whether natural-language emergency commands are enabled.
  bool naturalCommandsEnabled = true;

  // Controls whether confirmation is required before the emergency action.
  bool confirmationEnabled = true;

  // Controller for entering the emergency phrase.
  final TextEditingController phraseController = TextEditingController();

  @override
  void dispose() {
    // Dispose the controller when the screen is closed.
    phraseController.dispose();
    super.dispose();
  }

  // Opens a dialog where the elder can enter their emergency phrase.
  void _editEmergencyPhrase() {
    phraseController.text = emergencyPhrase;

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
            autofocus: true,
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
                setState(() {
                  emergencyPhrase = phraseController.text.trim();
                });

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF243B53)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Emergency Settings",
          style: TextStyle(
            color: Color(0xFF243B53),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ======================================================
              // INTRODUCTION
              // ======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(Icons.emergency_rounded, color: Colors.red, size: 30),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        "Set up how CareBridge should respond when you need emergency help.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ======================================================
              // PERSONAL EMERGENCY PHRASE
              // ======================================================
              const Text(
                "Emergency Voice Phrase",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Choose a word or short phrase that feels comfortable for you.",
                style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
              ),

              const SizedBox(height: 14),

              GestureDetector(
                onTap: _editEmergencyPhrase,

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF4F8EF7),
                        size: 28,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          emergencyPhrase.isEmpty
                              ? "Tap to choose your emergency phrase"
                              : '"$emergencyPhrase"',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: emergencyPhrase.isEmpty
                                ? const Color(0xFF718096)
                                : const Color(0xFF243B53),
                          ),
                        ),
                      ),

                      const Icon(Icons.edit_rounded, color: Color(0xFF718096)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Example: "Amma help", "Please help", or "Emergency".',
                style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),

              const SizedBox(height: 28),

              // ======================================================
              // VOICE OPTIONS
              // ======================================================
              const Text(
                "Voice Options",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  children: [
                    SwitchListTile(
                      value: phraseEnabled,

                      onChanged: (value) {
                        setState(() {
                          phraseEnabled = value;
                        });
                      },

                      secondary: const Icon(
                        Icons.record_voice_over_rounded,
                        color: Color(0xFF4F8EF7),
                      ),

                      title: const Text(
                        "Personal emergency phrase",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Use your chosen phrase to request emergency help.",
                      ),
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      value: naturalCommandsEnabled,

                      onChanged: (value) {
                        setState(() {
                          naturalCommandsEnabled = value;
                        });
                      },

                      secondary: const Icon(
                        Icons.chat_rounded,
                        color: Color(0xFF8A5CF6),
                      ),

                      title: const Text(
                        "Natural voice commands",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        'Understand commands such as "I need help".',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ======================================================
              // CONFIRMATION
              // ======================================================
              const Text(
                "Emergency Confirmation",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: SwitchListTile(
                  value: confirmationEnabled,

                  onChanged: (value) {
                    setState(() {
                      confirmationEnabled = value;
                    });
                  },

                  secondary: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF28A76B),
                  ),

                  title: const Text(
                    "Confirm before emergency action",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: const Text(
                    "Ask for confirmation before contacting the emergency contact.",
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ======================================================
              // INFORMATION
              // ======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(18),
                ),

                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF4F8EF7)),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        "Emergency contacts and location sharing will be connected later through your CareBridge family connection.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ======================================================
              // SAVE BUTTON
              // ======================================================
              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Emergency settings saved."),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    "Save Emergency Settings",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
