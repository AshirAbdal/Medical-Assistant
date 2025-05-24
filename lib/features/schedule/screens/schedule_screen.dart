import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Current selected date
  DateTime selectedDate = DateTime.now();

  // Sample appointments data
  final Map<String, List<Map<String, dynamic>>> appointments = {
    '2025-04-09': [
      {
        'time': '09:30 AM',
        'name': 'John Doe',
        'type': 'Check-up',
        'color': Colors.green,
      },
      {
        'time': '11:00 AM',
        'name': 'Michael Johnson',
        'type': 'Follow-up',
        'color': Colors.blue,
      },
      {
        'time': '02:15 PM',
        'name': 'David Wilson',
        'type': 'Consultation',
        'color': Colors.blue,
      },
    ],
    '2025-04-10': [
      {
        'time': '10:00 AM',
        'name': 'Jane Smith',
        'type': 'Initial Consultation',
        'color': Colors.orange,
      },
      {
        'time': '03:45 PM',
        'name': 'Emily Wilson',
        'type': 'Check-up',
        'color': Colors.green,
      },
    ],
  };

  List<Map<String, dynamic>> getAppointmentsForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return appointments[dateString] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final formattedDisplayDate = DateFormat(
      'MMMM dd, yyyy',
    ).format(selectedDate);
    final appointmentsForSelectedDate = getAppointmentsForDate(selectedDate);
    final formattedDisplayMonth = DateFormat('MMMM yyyy').format(selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Calendar header
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),

                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month - 1,
                            selectedDate.day,
                          );
                        });
                      },
                    ),
                    Text(
                      formattedDisplayMonth,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month + 1,
                            selectedDate.day,
                          );
                        });
                      },
                    ),
                  ],
                ),

                // Weekday headers
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Calendar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: _getDaysInMonth().length,
                  itemBuilder: (context, index) {
                    final day = _getDaysInMonth()[index];
                    final isSelected =
                        day != null &&
                        day.day == selectedDate.day &&
                        day.month == selectedDate.month &&
                        day.year == selectedDate.year;

                    final hasAppointments =
                        day != null &&
                        appointments[DateFormat('yyyy-MM-dd').format(day)]
                                ?.isNotEmpty ==
                            true;

                    return GestureDetector(
                      onTap: () {
                        if (day != null) {
                          setState(() {
                            selectedDate = day;
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFF4c5c97)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day?.day.toString() ?? '',
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (hasAppointments
                                          ? Colors.blue
                                          : Colors.black87),
                              fontWeight:
                                  isSelected || hasAppointments
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Appointments for selected date
          Text(
            'Appointments for ${DateFormat('MMMM dd, yyyy').format(selectedDate)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(height: 16),

          if (appointmentsForSelectedDate.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments for this day',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4caf50),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Add appointment action
                    },
                    child: const Text('Add Appointment'),
                  ),
                ],
              ),
            )
          else
            ...appointmentsForSelectedDate
                .map(
                  (appointment) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              appointment['time'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: appointment['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appointment['type'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Show appointment options
                            showModalBottomSheet(
                              context: context,
                              builder:
                                  (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit),
                                        title: const Text('Edit Appointment'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Edit appointment action
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        title: const Text(
                                          'Cancel Appointment',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Cancel appointment action
                                        },
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }

  // Helper method to generate calendar days
  List<DateTime?> _getDaysInMonth() {
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    final result = List<DateTime?>.filled(42, null); // 6 rows of 7 days

    // Fill in the days of the selected month
    for (int i = 0; i < daysInMonth; i++) {
      result[firstWeekday + i] = DateTime(
        selectedDate.year,
        selectedDate.month,
        i + 1,
      );
    }

    return result;
  }
}
