import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lets Admin connect a Family account to an Elder account, and shows
/// existing connections with a disconnect option.
///
/// This version uses a live StreamBuilder for the users collection
/// instead of a one-shot FutureBuilder. The previous version fetched
/// the list once per build and only happened to refresh because
/// _connect() called setState() afterward — _disconnect() did not,
/// so the "Connected to: X" line stayed on screen after a
/// disconnect until the admin manually reopened the page. A live
/// stream fixes that for both actions without depending on which
/// buttons happen to call setState.
class ConnectElderScreen extends StatefulWidget {
  const ConnectElderScreen({super.key});

  @override
  State<ConnectElderScreen> createState() => _ConnectElderScreenState();
}

class _ConnectElderScreenState extends State<ConnectElderScreen> {
  static const _blue = Color(0xFF4F8EF7);
  static const _green = Color(0xFF10B981);
  static const _navy = Color(0xFF203864);

  String? _familyUid;
  String? _elderUid;
  bool _saving = false;

  Future<void> _connect() async {
    if (_familyUid == null || _elderUid == null) {
      _show('Select both a Family account and an Elder.');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_familyUid)
          .update({'linkedElderId': _elderUid});
      if (!mounted) return;
      _show('Family and Elder connected successfully.');
      setState(() {
        _familyUid = null;
        _elderUid = null;
      });
    } catch (e) {
      if (mounted) _show('Connection failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDisconnect(
    String familyUid,
    String familyName,
    String? elderName,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove connection?'),
        content: Text(
          'Disconnect $familyName from ${elderName ?? 'their elder'}? '
          'The Family Dashboard will lose access to that elder\'s data until reconnected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (yes == true) await _disconnect(familyUid);
  }

  Future<void> _disconnect(String familyUid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(familyUid)
          .update({'linkedElderId': FieldValue.delete()});
      if (mounted) _show('Family–Elder connection removed.');
    } catch (e) {
      if (mounted) _show('Could not remove connection: $e');
    }
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Family–Elder Connection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load users: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          final families =
              allDocs.where((d) {
                final role = (d.data()['role'] ?? '').toString().toLowerCase();
                return role == 'family' || role == 'caregiver';
              }).toList()..sort(
                (a, b) =>
                    (a.data()['name'] ?? '').toString().toLowerCase().compareTo(
                      (b.data()['name'] ?? '').toString().toLowerCase(),
                    ),
              );

          final elders =
              allDocs
                  .where(
                    (d) =>
                        (d.data()['role'] ?? '').toString().toLowerCase() ==
                        'elder',
                  )
                  .toList()
                ..sort(
                  (a, b) => (a.data()['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .compareTo(
                        (b.data()['name'] ?? '').toString().toLowerCase(),
                      ),
                );

          // If the family or elder currently selected in the dropdown
          // no longer exists in a fresh snapshot (rare, but possible
          // if another admin session changes something), clear the
          // selection instead of pointing at a stale id.
          if (_familyUid != null && !families.any((d) => d.id == _familyUid)) {
            _familyUid = null;
          }
          if (_elderUid != null && !elders.any((d) => d.id == _elderUid)) {
            _elderUid = null;
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Connect a Family account to an Elder',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'After connection, the Family Dashboard uses only the selected elder\'s data.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 22),

              // ==========================================================
              // CREATE / CHANGE CONNECTION
              // ==========================================================
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create / change connection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (families.isEmpty)
                        _emptyNote('No Family accounts registered yet.')
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _familyUid,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Family account',
                            border: OutlineInputBorder(),
                          ),
                          items: families.map((doc) {
                            final d = doc.data();
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                '${d['name'] ?? 'Family'} — ${d['email'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _familyUid = v),
                        ),
                      const SizedBox(height: 14),
                      if (elders.isEmpty)
                        _emptyNote('No Elder accounts registered yet.')
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _elderUid,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Elder',
                            border: OutlineInputBorder(),
                          ),
                          items: elders.map((doc) {
                            final d = doc.data();
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                '${d['name'] ?? 'Elder'} — ${d['email'] ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _elderUid = v),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              (_saving || families.isEmpty || elders.isEmpty)
                              ? null
                              : _connect,
                          icon: const Icon(Icons.link_rounded),
                          label: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Connect Family to Elder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),
              Text(
                'Current Family connections (${families.length})',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 10),

              if (families.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No Family accounts registered yet.'),
                  ),
                )
              else
                ...families.map((doc) {
                  final d = doc.data();
                  final familyName = (d['name'] ?? 'Family').toString();
                  final linkedId = (d['linkedElderId'] ?? '').toString();

                  String? elderName;
                  if (linkedId.isNotEmpty) {
                    for (final elderDoc in elders) {
                      if (elderDoc.id == linkedId) {
                        elderName = elderDoc.data()['name']?.toString();
                        break;
                      }
                    }
                  }

                  final isStaleLink = linkedId.isNotEmpty && elderName == null;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _blue.withValues(alpha: .12),
                        child: const Icon(
                          Icons.family_restroom_rounded,
                          color: _blue,
                        ),
                      ),
                      title: Text(familyName),
                      subtitle: Text(
                        linkedId.isEmpty
                            ? 'No elder connected'
                            : isStaleLink
                            ? 'Connected elder no longer exists'
                            : 'Connected to: $elderName',
                        style: TextStyle(
                          color: isStaleLink ? Colors.orange.shade800 : null,
                        ),
                      ),
                      trailing: linkedId.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Disconnect',
                              icon: const Icon(
                                Icons.link_off_rounded,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDisconnect(
                                doc.id,
                                familyName,
                                elderName,
                              ),
                            ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyNote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.orange.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.orange.shade800)),
          ),
        ],
      ),
    );
  }
}
