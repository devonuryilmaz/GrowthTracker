import 'package:flutter/material.dart';
import 'package:growth_tracker/models/reminder.dart';
import 'package:growth_tracker/services/api_service.dart';

class AddReminderScreen extends StatefulWidget {
  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty ? 'Title required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description')
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () async {
                _selectedDate = DateTime.now().add(Duration(minutes: 1));
                if (_formKey.currentState!.validate()){
                  final reminder = Reminder(
                    id: 0,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    reminderDate: _selectedDate!.toUtc(),
                    isCompleted: false);

                  await apiService.addReminder(reminder);
                  Navigator.pop(context);
                }
              }, child: const Text('Save'))
            ],
          ),
        ),
      ),
    );
  }
}
