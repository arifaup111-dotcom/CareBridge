import 'package:flutter/material.dart';

class ConnectElderScreen extends StatefulWidget {
  const ConnectElderScreen({super.key});

  @override
  State<ConnectElderScreen> createState() => _ConnectElderScreenState();
}

class _ConnectElderScreenState extends State<ConnectElderScreen> {
  final TextEditingController elderIdController = TextEditingController();

  bool isConnected = false;

  @override
  void dispose() {
    elderIdController.dispose();
    super.dispose();
  }

  void _connectElder() {
    if (elderIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Elder ID"),
        ),
      );
      return;
    }

    // Temporary local connection.
    // Firebase will be added later.
    setState(() {
      isConnected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Elder connected successfully"),
      ),
    );
  }

  void _disconnectElder() {
    setState(() {
      isConnected = false;
      elderIdController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Elder disconnected"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4F8EF7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Connect Elder",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Connect an Elder",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203864),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Connect a family account with an elder",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 25),

            // Connection status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isConnected
                        ? Icons.link_rounded
                        : Icons.link_off_rounded,
                    size: 55,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    isConnected ? "Elder Connected" : "No Elder Connected",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? Colors.green
                          : const Color(0xFF203864),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    isConnected
                        ? "Your account is connected to an elder."
                        : "Enter the Elder ID to connect.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            if (!isConnected) ...[
              const Text(
                "Elder ID",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203864),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: elderIdController,
                decoration: InputDecoration(
                  hintText: "Enter Elder ID",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _connectElder,
                  icon: const Icon(Icons.link),
                  label: const Text(
                    "Connect Elder",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F8EF7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _disconnectElder,
                  icon: const Icon(Icons.link_off),
                  label: const Text(
                    "Disconnect Elder",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
            ],
          ],
        ),
      ),
    );
  }
}