import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../providers/advisor_provider.dart';

class AddScheduleScreen extends StatefulWidget {
  final Customer customer;

  const AddScheduleScreen({super.key, required this.customer});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  int _cadenceValue = 1;
  String _cadencePeriod = 'months';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final TextEditingController _cadenceController = TextEditingController(text: '1');

  @override
  void dispose() {
    _cadenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdvisorProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Engagement Schedule', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECURRENCE',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  const Text('Every', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                      onChanged: (val) => setState(() => _cadenceValue = int.tryParse(val) ?? 1),
                      controller: _cadenceController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _cadencePeriod,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      items: ['days', 'weeks', 'months', 'years']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) => setState(() => _cadencePeriod = val!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'TIMING',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              tileColor: const Color(0xFFF9F9F9),
              title: const Text('Start Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('EEEE, MMM d, y').format(_startDate)),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              tileColor: const Color(0xFFF9F9F9),
              title: const Text('End Date (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(_endDate != null ? DateFormat('EEEE, MMM d, y').format(_endDate!) : 'No end date (continuous)'),
              trailing: _endDate != null 
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _endDate = null),
                  )
                : const Icon(Icons.calendar_today, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final schedule = EngagementSchedule(
                    scheduleId: const Uuid().v4(),
                    startDate: _startDate,
                    endDate: _endDate,
                    cadenceValue: _cadenceValue,
                    cadencePeriod: _cadencePeriod,
                  );
                  final updatedSchedules = List<EngagementSchedule>.from(widget.customer.schedules)..add(schedule);
                  final updated = widget.customer.copyWith(schedules: updatedSchedules);
                  await provider.addCustomer(updated);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('SAVE SCHEDULE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
