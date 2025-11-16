import 'dart:async';

import 'package:flutter/material.dart';
import 'package:growth_tracker/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';
import '../services/api_service.dart';
import 'add_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<Reminder> reminders = [];
  bool isLoading = false;
  Timer? _timer;

  String _userName = '';
  String _userJob = '';
  int _userAge = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    fetchReminders();

    _timer = Timer.periodic(Duration(seconds: 1), (_) => checkReminders());
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _userJob = prefs.getString('user_job') ?? '';
      _userAge = prefs.getInt('user_age') ?? 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchReminders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await apiService.fetchReminders();
      setState(() {
        reminders = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Hata durumunda kullanıcıya bilgi verin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatıcılar yüklenemedi: $e')),
      );
    }
  }

  bool _snackbarShowing =
      false; // Aynı anda birden fazla snackbar göstermemek için

  void checkReminders() {
    final now = DateTime.now();
    for (var r in reminders) {
      if (!r.isCompleted &&
          r.reminderDate.isBefore(now.add(Duration(seconds: 1)))) {
        if (!_snackbarShowing) {
          _snackbarShowing = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder: ${r.title}'),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior
                    .floating, // hafifçe yukarıdan açılıyor gibi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () async {
                    await fetchReminders(); // isteğe bağlı: listeyi backend’den çek
                  },
                ),
              ),
            );
            _snackbarShowing = false;
          });
        }

        r.isCompleted = true; // tekrar göstermesin
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Growth Tracker'),
      actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        })
      ],),
      body: RefreshIndicator(
        onRefresh: fetchReminders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : reminders.isEmpty
                ? ListView(
                    children: const [
                      Center(child: Text('No upcoming reminders'))
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final r = reminders[index];
                      final isPast = r.reminderDate.isBefore(DateTime.now());
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          leading: Icon(
                              isPast ? Icons.warning : Icons.notifications,
                              color: isPast ? Colors.red : Colors.blue),
                          title: Text(r.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${r.description}\t - ${DateFormat('dd MMM, HH:mm').format(r.reminderDate)}'),
                          trailing: r.isCompleted
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : null,
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddReminderScreen()));
            fetchReminders();
          },
          child: const Icon(Icons.add)),
      // ElevatedButton(
      //   onPressed: () {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Test Reminder!')),
      //     );
      //   },
      //   child: Text('Show Snackbar'),
      // ),
    );
  }
}
