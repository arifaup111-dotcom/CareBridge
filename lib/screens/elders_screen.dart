import 'package:flutter/material.dart';

class EldersScreen extends StatefulWidget {
  const EldersScreen({super.key});

  @override
  State<EldersScreen> createState() => _EldersScreenState();
}

class _EldersScreenState extends State<EldersScreen> {
  // Temporary dummy data.
  // Firebase will be connected later.
  final List<Map<String, String>> elders = [
    {
      "name": "Anitha Menon",
      "email": "anitha@gmail.com",
      "phone": "9876543210",
      "age": "68",
    },
    {
      "name": "Mary Thomas",
      "email": "mary@gmail.com",
      "phone": "9876543211",
      "age": "72",
    },
    {
      "name": "Raman Nair",
      "email": "raman@gmail.com",
      "phone": "9876543212",
      "age": "70",
    },
  ];

  void _viewElder(Map<String, String> elder) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Elder Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF203864),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Name", elder["name"]!),
              _detailRow("Email", elder["email"]!),
              _detailRow("Phone", elder["phone"]!),
              _detailRow("Age", elder["age"]!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _deleteElder(int index) {
    final elderName = elders[index]["name"]!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Delete Elder",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete $elderName?",
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
                  elders.removeAt(index);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$elderName deleted successfully"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
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
          "Elder Management",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: elders.isEmpty
          ? const Center(
              child: Text(
                "No elders registered",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Registered Elders",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203864),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "View and manage registered elders",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total elders card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                    child: Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.elderly,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 18),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Elders",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${elders.length}",
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF203864),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Elder list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: elders.length,
                    itemBuilder: (context, index) {
                      final elder = elders[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
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
                            Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.elderly,
                                    color: Colors.orange,
                                    size: 30,
                                  ),
                                ),

                                const SizedBox(width: 15),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        elder["name"]!,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF203864),
                                        ),
                                      ),

                                      const SizedBox(height: 5),

                                      Text(
                                        elder["email"]!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        "Age: ${elder["age"]!}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _viewElder(elder);
                                    },
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    label: const Text("View"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF4F8EF7),
                                      side: const BorderSide(
                                        color: Color(0xFF4F8EF7),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _deleteElder(index);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    label: const Text("Delete"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}