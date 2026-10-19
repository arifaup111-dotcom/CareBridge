// lib/screens/family_common.dart
//
// Shared pieces used by the Family dashboard tabs.
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'welcome_screen.dart';

const Color kFamilyBlue = Color(0xFF4F8EF7);
const Color kFamilyNavy = Color(0xFF203864);
const Color kFamilyBg = Color(0xFFF5F8FF);
const Color kFamilyMuted = Color(0xFF718096);

/// Blue app bar used by every Family tab, with a log-out button.
AppBar familyAppBar(
  BuildContext context,
  String title, {
  List<Widget> actions = const [],
}) {
  return AppBar(
    backgroundColor: kFamilyBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    actions: [
      ...actions,
      IconButton(
        tooltip: 'Log out',
        icon: const Icon(Icons.logout),
        onPressed: () => confirmFamilyLogout(context),
      ),
    ],
  );
}

Future<void> confirmFamilyLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not log out. Please try again.')),
    );
  }
}

// ------------------------------------------------------------------
// Time / date helpers.
//
// These produce and read exactly the same text formats the Elder screens and
// CareAlarmService use ("8:00 AM" and "d/m/yyyy"), so medicines and
// appointments added by Family still trigger alarms on the Elder's phone.
// ------------------------------------------------------------------

String formatTime12h(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

TimeOfDay? parseTime(String value) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  var hour = int.tryParse(match.group(1)!) ?? 0;
  final minute = int.tryParse(match.group(2)!) ?? 0;
  final period = (match.group(3) ?? '').toUpperCase();
  if (period == 'PM' && hour < 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return TimeOfDay(
    hour: hour.clamp(0, 23).toInt(),
    minute: minute.clamp(0, 59).toInt(),
  );
}

/// Minutes since midnight, or a large number when the text can't be parsed
/// (so unparsable entries sort to the end).
int timeSortKey(String value) {
  final t = parseTime(value);
  return t == null ? 24 * 60 + 1 : t.hour * 60 + t.minute;
}

String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

DateTime? parseDate(String value) {
  final p = value.trim().split('/');
  if (p.length != 3) return null;
  return DateTime.tryParse(
    '${p[2].padLeft(4, '0')}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}',
  );
}

// ------------------------------------------------------------------
// Shown on a tab while the Family account is not linked to an Elder yet.
// ------------------------------------------------------------------
class ConnectElderGate extends StatefulWidget {
  const ConnectElderGate({super.key});

  @override
  State<ConnectElderGate> createState() => _ConnectElderGateState();
}

class _ConnectElderGateState extends State<ConnectElderGate> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final id = _controller.text.trim().toUpperCase();
    if (id.isEmpty) {
      _show('Please enter the Elder ID.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _db.linkCurrentFamilyToElderByPublicId(id);
      // The dashboard listens to the family profile, so it switches to the
      // connected view on its own once the link is saved.
      _show('Connected successfully.');
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.link_rounded, color: kFamilyBlue, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Connect to an Elder',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kFamilyNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask the Elder for the Elder ID shown in their CareBridge '
                'profile (it looks like CB-ELD-XXXXXXXX), then enter it here.',
                style: TextStyle(color: kFamilyMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Elder ID',
                  hintText: 'CB-ELD-1A2B3C4D',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _connect,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: Text(_saving ? 'Connecting...' : 'Connect Elder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kFamilyBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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

/// Page shown for a tab while no Elder is linked.
class FamilyUnlinkedPage extends StatelessWidget {
  const FamilyUnlinkedPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFamilyBg,
      appBar: familyAppBar(context, title),
      body: const ConnectElderGate(),
    );
  }
}
