import 'care_reminder_planner.dart';

class AppointmentScheduleFormatter {
  AppointmentScheduleFormatter._();

  static String formatTodaysAppointments(
    List<Map<String, dynamic>> appointments, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final todaysAppointments = <({Map<String, dynamic> data, DateTime at})>[];
    for (final appointment in appointments) {
      if (_isCancelled(appointment)) continue;
      final appointmentAt = CareReminderPlanner.parseAppointmentDateTime(
        (appointment['date'] ?? '').toString(),
        (appointment['time'] ?? '').toString(),
      );
      if (appointmentAt == null ||
          appointmentAt.year != current.year ||
          appointmentAt.month != current.month ||
          appointmentAt.day != current.day) {
        continue;
      }
      todaysAppointments.add((data: appointment, at: appointmentAt));
    }

    if (todaysAppointments.isEmpty) {
      return "You don't have any appointments scheduled for today.";
    }

    todaysAppointments.sort((a, b) => a.at.compareTo(b.at));
    final details = todaysAppointments
        .map((item) {
          final data = item.data;
          final doctor = (data['doctor'] ?? 'Doctor appointment')
              .toString()
              .trim();
          final time = _formatTime(item.at);
          final specialization = (data['specialization'] ?? '')
              .toString()
              .trim();
          final hospital = (data['hospital'] ?? '').toString().trim();
          final extra = [
            if (specialization.isNotEmpty) specialization,
            if (hospital.isNotEmpty) 'at $hospital',
          ];
          return 'At $time, you have an appointment with $doctor'
              '${extra.isEmpty ? '' : ', ${extra.join(', ')}'}.';
        })
        .join(' ');

    return "Here are your appointments for today. $details";
  }

  static bool _isCancelled(Map<String, dynamic> appointment) {
    final status = (appointment['status'] ?? '').toString().toLowerCase();
    return appointment['cancelled'] == true ||
        appointment['canceled'] == true ||
        appointment['isCancelled'] == true ||
        appointment['deleted'] == true ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'deleted';
  }

  static String _formatTime(DateTime appointmentAt) {
    final hour = appointmentAt.hour % 12 == 0 ? 12 : appointmentAt.hour % 12;
    final minute = appointmentAt.minute.toString().padLeft(2, '0');
    final period = appointmentAt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
