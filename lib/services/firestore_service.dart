import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central data layer for CareBridge.
///
/// Collection layout:
///   users/{uid}                          -> profile + role + linkedElderId
///   elders/{elderId}/medicines/{id}      -> name, dosage, time, instruction
///   elders/{elderId}/appointments/{id}   -> doctor, place, date, time
///   elders/{elderId}/settings/emergency  -> contactName, contactNumber, phrases
///   elders/{elderId}/emergencies/{id}    -> lat, lng, phrase, timestamp
///
/// Everything is keyed by "elderId" so the Family dashboard and the Elder
/// dashboard read and write the exact same documents.
class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // ================================================================
  // ELDER ID RESOLUTION
  // ================================================================

  /// Returns the elder whose data this signed-in user should see.
  ///
  /// - If the user is an Elder, that's their own uid.
  /// - If the user is a Family member, it's the elder they are linked to
  ///   (users/{uid}.linkedElderId), set during registration or by Admin.
  Future<String?> resolveElderId() async {
    final uid = currentUid;
    if (uid == null) return null;

    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final role = (data['role'] ?? '').toString().trim().toLowerCase();

    if (role == 'family' || role == 'caregiver') {
      return data['linkedElderId'] as String?;
    }
    return role == 'elder' ? uid : null;
  }

  // ================================================================
  // USER PROFILE
  // ================================================================

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role,
    String? linkedElderId,
    String? elderId,
    String? phone,
    String? assistantName,
  }) async {
    final normalizedRole = role.toLowerCase();
    final normalizedElderId = elderId?.trim().toUpperCase();
    final batch = firestore.batch();
    batch.set(firestore.collection('users').doc(uid), {
      'name': name,
      'email': email,
      'role': normalizedRole,
      'linkedElderId': linkedElderId,
      'elderId': normalizedElderId,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      if (assistantName != null && assistantName.trim().isNotEmpty)
        'assistantName': assistantName.trim(),
    }, SetOptions(merge: true));
    final signInEmail = _auth.currentUser?.email?.trim();
    if (signInEmail != null && signInEmail.isNotEmpty) {
      batch.set(firestore.collection('userPrivate').doc(uid), {
        'authEmail': signInEmail,
      });
    }

    if (normalizedRole == 'elder' && normalizedElderId != null) {
      batch.set(firestore.collection('elderDirectory').doc(normalizedElderId), {
        'elderUid': uid,
        'elderId': normalizedElderId,
      });
    }
    await batch.commit();
  }

  /// Creates a short public Elder ID that can be safely shared with a Family member.
  /// The Firebase UID remains the internal document key.
  String createElderId(String uid) {
    final clean = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final suffix = clean.length >= 8
        ? clean.substring(0, 8)
        : clean.padRight(8, '0');
    return 'CB-ELD-$suffix';
  }

  /// Gets the Elder's public ID and creates/stores one if an older account
  /// does not already have an ID. This keeps the ID shown in the UI and the
  /// ID used by Family connection in sync.
  Future<String?> getOrCreateElderPublicId() async {
    final uid = currentUid;
    if (uid == null) return null;

    final data = await getUserProfile(uid);
    if ((data?['role'] ?? '').toString().trim().toLowerCase() != 'elder') {
      return null;
    }

    final existing = data?['elderId']?.toString().trim();
    if (existing != null && existing.isNotEmpty) {
      final normalized = existing.toUpperCase();
      final directoryRef = firestore
          .collection('elderDirectory')
          .doc(normalized);
      final directory = await directoryRef.get();
      if (!directory.exists) {
        await directoryRef.set({'elderUid': uid, 'elderId': normalized});
      } else if (directory.data()?['elderUid'] != uid) {
        throw StateError(
          'This Elder ID is already assigned to another account.',
        );
      }
      return normalized;
    }

    final newId = createElderId(uid);
    final batch = firestore.batch();
    batch.set(firestore.collection('users').doc(uid), {
      'elderId': newId,
    }, SetOptions(merge: true));
    batch.set(firestore.collection('elderDirectory').doc(newId), {
      'elderUid': uid,
      'elderId': newId,
    });
    await batch.commit();
    return newId;
  }

  /// Finds an Elder account from the public Elder ID entered by Family.
  Future<Map<String, dynamic>?> findElderByPublicId(String elderId) async {
    final normalized = elderId.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final doc = await firestore
        .collection('elderDirectory')
        .doc(normalized)
        .get();
    final data = doc.data();
    final uid = data?['elderUid']?.toString();
    if (!doc.exists || uid == null || uid.isEmpty) return null;

    return {'uid': uid, 'elderId': normalized};
  }

  Future<void> linkCurrentFamilyToElderByPublicId(String elderId) async {
    final familyUid = currentUid;
    if (familyUid == null) throw Exception('Family account is not signed in.');

    final family = await getUserProfile(familyUid);
    final role = (family?['role'] ?? '').toString().trim().toLowerCase();
    if (role != 'family' && role != 'caregiver') {
      throw Exception('Only a Family account can connect to an Elder.');
    }

    final elder = await findElderByPublicId(elderId);
    if (elder == null) throw Exception('No Elder found with that Elder ID.');
    if (elder['uid'] == familyUid) {
      throw Exception('A Family account cannot connect to itself.');
    }

    final linkedElderId = (family?['linkedElderId'] ?? '').toString();
    if (linkedElderId.isNotEmpty && linkedElderId != elder['uid']) {
      throw Exception(
        'Disconnect the current Elder before connecting another.',
      );
    }

    await firestore.collection('users').doc(familyUid).update({
      'linkedElderId': elder['uid'],
      'linkedElderPublicId': elder['elderId'],
      'linkedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateAssistantName(String assistantName) async {
    final uid = currentUid;
    final normalizedName = assistantName.trim();
    if (uid == null) throw StateError('No signed-in user.');
    if (normalizedName.isEmpty || normalizedName.length > 30) {
      throw ArgumentError.value(
        assistantName,
        'assistantName',
        'The assistant name must be between 1 and 30 characters.',
      );
    }

    await firestore.collection('users').doc(uid).update({
      'assistantName': normalizedName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCurrentUserDetails({
    required String name,
    String? phone,
    String? age,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No signed-in user.');

    final updates = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (phone != null) {
      updates['phone'] = phone.trim();
    }
    if (age != null) {
      updates['age'] = age.trim().isEmpty ? FieldValue.delete() : age.trim();
    }

    await firestore.collection('users').doc(uid).update(updates);
  }

  Future<void> updateUserProfileByAdmin({
    required String uid,
    required String name,
    required String email,
  }) async {
    final userRef = firestore.collection('users').doc(uid);
    final profile = await userRef.get();
    if (!profile.exists) throw StateError('User profile was not found.');

    final privateRef = firestore.collection('userPrivate').doc(uid);
    final privateProfile = await privateRef.get();
    final existingEmail = (profile.data()?['email'] ?? '').toString().trim();
    final batch = firestore.batch();
    if (!privateProfile.exists && existingEmail.isNotEmpty) {
      batch.set(privateRef, {'authEmail': existingEmail});
    }
    batch.update(userRef, {
      'name': name.trim(),
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> get _phoneChangeRequests =>
      firestore.collection('phoneChangeRequests');

  Future<void> requestPhoneNumberChange(String phone) async {
    await requestContactChange(phone: phone);
  }

  Future<void> requestContactChange({String? phone, String? email}) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No signed-in user.');

    final requestedPhone = phone?.trim();
    final requestedEmail = email?.trim();
    if ((requestedPhone == null || requestedPhone.isEmpty) &&
        (requestedEmail == null || requestedEmail.isEmpty)) {
      throw ArgumentError('Enter a new phone number or email address.');
    }
    if (requestedPhone != null && requestedPhone.isNotEmpty) {
      final digits = requestedPhone.replaceAll(RegExp(r'\D'), '');
      if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(requestedPhone) ||
          digits.length < 7 ||
          digits.length > 15) {
        throw ArgumentError('Enter a valid phone number.');
      }
    }
    if (requestedEmail != null &&
        requestedEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(requestedEmail)) {
      throw ArgumentError('Enter a valid email address.');
    }

    final profile = await getUserProfile(uid);
    if (profile == null) throw StateError('User profile was not found.');
    final currentPhone = (profile['phone'] ?? '').toString().trim();
    final currentEmail = (profile['email'] ?? '').toString().trim();
    final phoneToRequest =
        requestedPhone != null &&
            requestedPhone.isNotEmpty &&
            requestedPhone != currentPhone
        ? requestedPhone
        : null;
    final emailToRequest =
        requestedEmail != null &&
            requestedEmail.isNotEmpty &&
            requestedEmail.toLowerCase() != currentEmail.toLowerCase()
        ? requestedEmail
        : null;
    if (phoneToRequest == null && emailToRequest == null) return;

    final requests = await _phoneChangeRequests
        .where('requestedBy', isEqualTo: uid)
        .get();
    if (requests.docs.any((doc) => doc.data()['status'] == 'pending')) {
      throw StateError(
        'You already have a contact change waiting for admin approval.',
      );
    }

    final request = <String, dynamic>{
      'userId': uid,
      'requestedBy': uid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (phoneToRequest != null) request['requestedPhone'] = phoneToRequest;
    if (emailToRequest != null) request['requestedEmail'] = emailToRequest;
    await _phoneChangeRequests.add(request);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
  streamPendingPhoneChangeRequests() {
    return _phoneChangeRequests
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCurrentUserPhoneRequests() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _phoneChangeRequests
        .where('requestedBy', isEqualTo: uid)
        .snapshots();
  }

  Future<void> reviewPhoneChangeRequest({
    required String requestId,
    required String userId,
    required bool approve,
    String? requestedPhone,
    String? requestedEmail,
  }) async {
    final reviewerUid = currentUid;
    if (reviewerUid == null) throw StateError('Admin is not signed in.');

    final batch = firestore.batch();
    final requestRef = _phoneChangeRequests.doc(requestId);
    if (approve) {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (requestedPhone != null && requestedPhone.trim().isNotEmpty) {
        updates['phone'] = requestedPhone.trim();
      }
      if (requestedEmail != null && requestedEmail.trim().isNotEmpty) {
        updates['email'] = requestedEmail.trim();
      }
      batch.update(firestore.collection('users').doc(userId), updates);
    }
    batch.update(requestRef, {
      'status': approve ? 'approved' : 'rejected',
      'reviewedBy': reviewerUid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Used by the Admin dashboard to list every registered account.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return firestore.collection('users').snapshots();
  }

  /// Links a family member to an elder (Admin dashboard).
  Future<void> linkFamilyToElder({
    required String familyUid,
    required String elderId,
  }) {
    return firestore.collection('users').doc(familyUid).update({
      'linkedElderId': elderId,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCurrentFamilyProfile() {
    final uid = currentUid;
    if (uid == null) {
      return const Stream.empty();
    }
    return firestore.collection('users').doc(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamElderProfile(
    String elderUid,
  ) {
    return firestore.collection('users').doc(elderUid).snapshots();
  }

  Future<Map<String, dynamic>?> getElderProfile(String elderUid) async {
    final doc = await firestore.collection('users').doc(elderUid).get();
    return doc.data();
  }

  // ================================================================
  // MEDICINES
  // ================================================================

  CollectionReference<Map<String, dynamic>> _medicines(String elderId) =>
      firestore.collection('elders').doc(elderId).collection('medicines');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMedicines(String elderId) {
    return _medicines(elderId).orderBy('time').snapshots();
  }

  Future<void> addMedicine({
    required String elderId,
    required String name,
    required String dosage,
    required String time,
    String instruction = 'Take as prescribed',
  }) {
    return _medicines(elderId).add({
      'name': name,
      'dosage': dosage,
      'time': time,
      'instruction': instruction,
      'taken': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMedicine({
    required String elderId,
    required String medicineId,
    required Map<String, dynamic> data,
  }) {
    return _medicines(elderId).doc(medicineId).update(data);
  }

  Future<void> deleteMedicine({
    required String elderId,
    required String medicineId,
  }) {
    return _medicines(elderId).doc(medicineId).delete();
  }

  Future<void> markMedicineTaken({
    required String elderId,
    required String medicineId,
    required bool taken,
  }) {
    return _medicines(elderId).doc(medicineId).update({
      'taken': taken,
      'lastTakenAt': taken ? FieldValue.serverTimestamp() : null,
      'takenOn': taken ? _todayDateKey() : FieldValue.delete(),
    });
  }

  static bool isMedicineTakenToday(Map<String, dynamic> medicine) {
    final takenOn = medicine['takenOn'];
    if (takenOn is String) return takenOn == _todayDateKey();

    final lastTakenAt = medicine['lastTakenAt'];
    if (lastTakenAt is Timestamp) {
      final date = lastTakenAt.toDate().toLocal();
      final dateKey =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      return dateKey == _todayDateKey();
    }
    return medicine['taken'] == true;
  }

  static String _todayDateKey() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
  }

  /// One-shot read used by the voice assistant when the elder asks
  /// "ഇന്നത്തെ മരുന്ന് എന്താണ്?" (what is today's medicine).
  Future<List<Map<String, dynamic>>> getMedicinesOnce(String elderId) async {
    final snap = await _medicines(elderId).orderBy('time').get();
    return snap.docs
        .map(
          (d) => {
            'id': d.id,
            ...d.data(),
            'taken': isMedicineTakenToday(d.data()),
          },
        )
        .toList();
  }

  // ================================================================
  // APPOINTMENTS
  // ================================================================

  CollectionReference<Map<String, dynamic>> _appointments(String elderId) =>
      firestore.collection('elders').doc(elderId).collection('appointments');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAppointments(
    String elderId,
  ) {
    return _appointments(elderId).orderBy('date').snapshots();
  }

  Future<void> addAppointment({
    required String elderId,
    required String doctor,
    required String specialization,
    required String hospital,
    required String date,
    required String time,
    String type = 'Doctor Consultation',
  }) {
    return _appointments(elderId).add({
      'doctor': doctor,
      'specialization': specialization,
      'hospital': hospital,
      'date': date,
      'time': time,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAppointment({
    required String elderId,
    required String appointmentId,
    required Map<String, dynamic> data,
  }) {
    return _appointments(elderId).doc(appointmentId).update(data);
  }

  Future<void> deleteAppointment({
    required String elderId,
    required String appointmentId,
  }) {
    return _appointments(elderId).doc(appointmentId).delete();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsOnce(String elderId) async {
    final snap = await _appointments(elderId).orderBy('date').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ================================================================
  // MEAL AND WATER REMINDERS
  // ================================================================

  DocumentReference<Map<String, dynamic>> _careReminderSettings(
    String elderId,
  ) => firestore
      .collection('elders')
      .doc(elderId)
      .collection('settings')
      .doc('careReminders');

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCareReminderSettings(
    String elderId,
  ) => _careReminderSettings(elderId).snapshots();

  Future<Map<String, dynamic>?> getCareReminderSettings(String elderId) async {
    final snapshot = await _careReminderSettings(elderId).get();
    return snapshot.data();
  }

  Future<void> saveCareReminderSettings({
    required String elderId,
    required List<String> mealTimes,
    required List<String> waterTimes,
    String wakeUpTime = '7:00 AM',
    String exerciseTime = '8:00 AM',
  }) {
    return _careReminderSettings(elderId).set({
      'mealTimes': mealTimes,
      'waterTimes': waterTimes,
      'wakeUpTime': wakeUpTime,
      'exerciseTime': exerciseTime,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markCareReminderCompleted({
    required String elderId,
    required String category,
  }) {
    if (category != 'meal' && category != 'water') {
      throw ArgumentError.value(category, 'category');
    }
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    return _careReminderSettings(elderId).set({
      '${category}ConfirmedOn': date,
      '${category}ConfirmedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================================================================
  // EMERGENCY SETTINGS
  // ================================================================

  DocumentReference<Map<String, dynamic>> _emergencySettings(String elderId) =>
      firestore
          .collection('elders')
          .doc(elderId)
          .collection('settings')
          .doc('emergency');

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamEmergencySettings(
    String elderId,
  ) {
    return _emergencySettings(elderId).snapshots();
  }

  Future<Map<String, dynamic>?> getEmergencySettings(String elderId) async {
    final doc = await _emergencySettings(elderId).get();
    return doc.data();
  }

  Future<void> saveEmergencyContact({
    required String elderId,
    required String contactName,
    required String contactNumber,
  }) {
    return _emergencySettings(elderId).set({
      'contactName': contactName,
      'contactNumber': contactNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Malayalam trigger phrases the elder can say to raise an alert.
  Future<void> saveEmergencyPhrases({
    required String elderId,
    required List<String> phrases,
  }) {
    return _emergencySettings(elderId).set({
      'phrases': phrases,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================================================================
  // EMERGENCY EVENTS
  // ================================================================

  Future<String> recordEmergency({
    required String elderId,
    required String triggerPhrase,
    double? latitude,
    double? longitude,
  }) async {
    final event = await firestore
        .collection('elders')
        .doc(elderId)
        .collection('emergencies')
        .add({
          'triggerPhrase': triggerPhrase,
          'latitude': latitude,
          'longitude': longitude,
          'locationTracking': false,
          'resolved': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
    return event.id;
  }

  Future<void> updateEmergencyLocation({
    required String elderId,
    required String emergencyId,
    required double latitude,
    required double longitude,
  }) {
    return firestore
        .collection('elders')
        .doc(elderId)
        .collection('emergencies')
        .doc(emergencyId)
        .update({
          'latitude': latitude,
          'longitude': longitude,
          'locationTracking': true,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> stopEmergencyLocationTracking({
    required String elderId,
    required String emergencyId,
  }) {
    return firestore
        .collection('elders')
        .doc(elderId)
        .collection('emergencies')
        .doc(emergencyId)
        .update({
          'locationTracking': false,
          'trackingEndedAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamEmergencies(
    String elderId,
  ) {
    return firestore
        .collection('elders')
        .doc(elderId)
        .collection('emergencies')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ================================================================
  // FAMILY DASHBOARD SUPPORT
  // ================================================================

  /// Touches settings/careReminders. The Elder's phone listens to that
  /// document and, when it changes, re-reads medicines and appointments and
  /// reschedules its alarms. Family calls this after adding, editing or
  /// deleting a medicine or appointment so the alarms stay in step.
  Future<void> touchCareSync(String elderId) {
    return _careReminderSettings(
      elderId,
    ).set({'syncedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> _healthReadings(String elderId) =>
      firestore.collection('elders').doc(elderId).collection('healthReadings');

  /// Newest recorded health reading (a list with zero or one document).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamLatestHealthReading(
    String elderId,
  ) {
    return _healthReadings(
      elderId,
    ).orderBy('timestamp', descending: true).limit(1).snapshots();
  }

  /// Saves one set of readings. Empty values are not stored.
  Future<void> addHealthReading({
    required String elderId,
    String? heartRate,
    String? bloodPressure,
    String? temperature,
    String? status,
  }) {
    String? clean(String? v) {
      final t = v?.trim() ?? '';
      return t.isEmpty ? null : t;
    }

    return _healthReadings(elderId).add({
      if (clean(heartRate) != null) 'heartRate': clean(heartRate),
      if (clean(bloodPressure) != null) 'bloodPressure': clean(bloodPressure),
      if (clean(temperature) != null) 'temperature': clean(temperature),
      if (clean(status) != null) 'status': clean(status),
      'recordedBy': currentUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  CollectionReference<Map<String, dynamic>> _healthConsultations(
    String elderId,
  ) => firestore
      .collection('elders')
      .doc(elderId)
      .collection('healthConsultations');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLatestHealthConsultation(
    String elderId,
  ) {
    return _healthConsultations(
      elderId,
    ).orderBy('consultationDate', descending: true).limit(1).snapshots();
  }

  Future<void> addHealthConsultation({
    required String elderId,
    required String doctorName,
    required DateTime consultationDate,
    required String diagnosis,
    required String status,
    String? heartRate,
    String? bloodPressure,
    String? temperature,
  }) {
    String? clean(String? value) {
      final trimmed = value?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    }

    return _healthConsultations(elderId).add({
      'doctorName': doctorName.trim(),
      'consultationDate': Timestamp.fromDate(consultationDate),
      'diagnosis': diagnosis.trim(),
      'status': status.trim(),
      if (clean(heartRate) != null) 'heartRate': clean(heartRate),
      if (clean(bloodPressure) != null) 'bloodPressure': clean(bloodPressure),
      if (clean(temperature) != null) 'temperature': clean(temperature),
      'recordedBy': currentUid,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }
}
